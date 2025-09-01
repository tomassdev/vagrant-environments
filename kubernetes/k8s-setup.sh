#!/bin/bash
set -euo pipefail

# Setup Kubernetes Cluster v1.34
# Note: Installation steps may vary depending on the Kubernetes version
# Reference: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# https://kubernetes.io/releases/
readonly K8S_VERSION="v1.34"
# https://github.com/projectcalico/calico/releases
readonly K8S_CALICO_VERSION="v3.30.3"
readonly K8S_POD_NETWORK_CIDR="192.168.64.0/18"
readonly K8S_API_SERVER_EXTRA_SANS="127.0.0.1,localhost"
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
readonly CONTAINERD_SANDBOX_IMAGE="registry.k8s.io/pause:3.10.1"
readonly CURRENT_HOST=$(hostname)
readonly CURRENT_IP=$(echo "${NODE_IPS}" | tr ',' '\n' | grep "${CURRENT_HOST}" | awk '{print $1}')

export DEBIAN_FRONTEND=noninteractive

# Ensure unique machine ID
echo "==> Generating unique machine ID"
rm -f /etc/machine-id
dbus-uuidgen --ensure=/etc/machine-id

# Add the hostnames to the hosts file
echo "==> Adding host entries to /etc/hosts"
echo "${NODE_IPS}" | tr ',' '\n' >> /etc/hosts

# Disable swap
echo "==> Disabling swap and removing swap entry from /etc/fstab"
swapoff -a && sed -i '/\/swap.img/s/^/#/' /etc/fstab

# Enable IPv4 packet forwarding
echo "==> Enabling IPv4 packet forwarding"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Install containerd runtime
echo "==> Installing containerd runtime"
apt-get update && apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update && apt-get install -y containerd.io

# Configure containerd runtime
echo "==> Configuring containerd runtime"
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i "s|registry.k8s.io/pause:3.8|${CONTAINERD_SANDBOX_IMAGE}|g" /etc/containerd/config.toml
systemctl restart containerd

# Install Kubernetes tools
echo "==> Installing Kubernetes tools: kubeadm, kubelet, kubectl"
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Configure kubelet service
echo "==> Starting kubelet service"
systemctl enable --now kubelet

# Initialize Kubernetes control plane node or join worker nodes
if [[ "${CURRENT_HOST}" == "control-plane" ]]; then
  echo "==> Initializing Kubernetes control plane node"
  kubeadm init \
      --apiserver-advertise-address="${CURRENT_IP}" \
      --control-plane-endpoint="${CURRENT_HOST}" \
      --pod-network-cidr="${K8S_POD_NETWORK_CIDR}" \
      --apiserver-cert-extra-sans="${K8S_API_SERVER_EXTRA_SANS}"

  echo "==> Configuring the admin profile"
  export KUBECONFIG=/etc/kubernetes/admin.conf

  echo "==> Installing network add-on: Calico"
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${K8S_CALICO_VERSION}/manifests/operator-crds.yaml
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${K8S_CALICO_VERSION}/manifests/tigera-operator.yaml
  curl -s "https://raw.githubusercontent.com/projectcalico/calico/${K8S_CALICO_VERSION}/manifests/custom-resources.yaml" | \
      sed "s|192.168.0.0/16|${K8S_POD_NETWORK_CIDR}|g" | \
      kubectl apply -f -

  echo "==> Installing Metrics Server"
  curl -sL https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml | \
    sed 's/- args:/- args:\n        - --kubelet-insecure-tls/' | \
    kubectl apply -f -

  echo "==> Generating join command for worker nodes"
  kubeadm token create --print-join-command > /tmp/join.sh

  echo "==> Starting join command server"
  while true; do
      nc -l 8080 < /tmp/join.sh
  done &
else
    echo "==> Joining Kubernetes ${CURRENT_HOST} ${CURRENT_IP} to the cluster"
    until nc -z control-plane 6443; do
        echo "Waiting for control plane API"
        sleep 5
    done

    nc control-plane 8080 | bash
fi
