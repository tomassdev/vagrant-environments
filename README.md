# 📦 Vagrant Environments

## 📖 Overview

A curated collection of dynamic, ready-to-use Vagrant environments for VirtualBox. This repository provides flexible `Vagrantfile` setups that support both **single** and **multi-node** configurations, enabling quick provisioning of development, test, or lab environments — from minimal VMs to full multi-node clusters.

```
┌───────────────┐
| Host Machine  |
|   (Vagrant)   |
└───────┬───────┘
        │
┌───────┴──────────────┐
| Virtualization Layer |
|     (VirtualBox)     |
└───────┬──────────────┘
        │
┌───────┴────────────────────┬─────────────────────────┐
| Centos/Debian/Ubuntu Nodes | Docker Swarm/Kubernetes |
└────────────────────────────┴─────────────────────────┘
```

## 🚀 What's Inside?

Each subdirectory represents a Vagrant environment with a dynamic `Vagrantfile`:

### 📦 Base Environments

- `centos/` - Centos-based environment
- `debian/` - Centos-based environment
- `ubuntu/` - Ubuntu-based environment
- `fedora/` - Fedora-based environment

### 📦 📦 Cluster Packs

- `kubernetes/` - Kubernetes multi-node cluster
- `docker-swarm/` - Docker swarm multi-node cluster

## 🚀 Getting Started

### ✅ Prerequisites

- 🐱 **Host OS:** Linux, macOS, or Windows
- 📦 **Vagrant:** 2.4.x or newer
- 🖥️ **VirtualBox:** 7.2.x or newer

## ⚙️ Usage

### 🏁 Spin up an Environment

```bash
cd ubuntu && vagrant up
```

The environment will spin up one or more VMs based on the `NODES` definition inside the `Vagrantfile`.

### 🛠️ Example Node Configuration

```ruby
NODES = {
  'node-1' => {
    ip: '192.168.10.10',
    ports: {
      'ssh' => { guest: 22, host: 2222 }
    },
    cpus: 2,
    memory: 2048,
    disk_size: "64GB",
    synced_folder: false
  },
  'node-2' => {
    ip: '192.168.10.11',
    ports: {
      'ssh' => { guest: 22, host: 2223 }
    },
    cpus: 2,
    memory: 2048,
    disk_size: "64GB",
    synced_folder: false
  }
}
```

To access a specific environment:

```bash
vagrant ssh node-1
```

To destroy all environments:

```bash
vagrant destroy -f
```

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.
