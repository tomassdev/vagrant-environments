#!/bin/bash
set -euo pipefail

# Setup Docker Swarm
# Note: Installation steps may vary depending on the Docker Engine version
# Reference: https://docs.docker.com/engine/release-notes/28/

readonly CURRENT_HOST=$(hostname)
readonly CURRENT_IP=$(echo "${NODE_IPS}" | tr ',' '\n' | awk -v host="${CURRENT_HOST}" '$2 == host {print $1}')

export DEBIAN_FRONTEND=noninteractive

# Add the hostnames to the hosts file
echo "==> Current HOST: ${CURRENT_HOST}, IP: ${CURRENT_IP}"
echo "==> Adding host entries to /etc/hosts"
echo "${NODE_IPS}" | tr ',' '\n' >> /etc/hosts

# Install Docker Engine
echo "==> Installing Docker Engine"
apt-get update && apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add vagrant user to the docker group
echo "==> Adding user '${SUDO_USER:-vagrant}' to the 'docker' group"
usermod -aG docker "${SUDO_USER:-vagrant}"

# Initialize Docker Swarm manager or join as worker
if [[ "${CURRENT_HOST}" == "manager" ]]; then
  echo "==> Initializing Docker Swarm Manager"
  docker swarm init --advertise-addr "${CURRENT_IP}"

  # Generate worker join token and save join command
  JOIN_CMD=$(docker swarm join-token -q worker)
  echo "docker swarm join --token ${JOIN_CMD} ${CURRENT_IP}:2377" > /tmp/join.sh

  # Start a simple server to serve the join command
  echo "==> Starting join command server on port 8080"
  while true; do
    nc -l -p 8080 < /tmp/join.sh
  done &
else
  # Wait for the manager to be ready before joining
  echo "==> Waiting for Docker Swarm manager at manager:2377"
  until nc -z manager 2377; do
    echo "Waiting for Docker Swarm manager..."
    sleep 5
  done

  # Join the Docker Swarm as a worker
  echo "==> Joining Docker Swarm node ${CURRENT_HOST} (${CURRENT_IP}) to the cluster"
  nc manager 8080 | bash
fi