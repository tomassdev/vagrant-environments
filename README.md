# 📦 Vagrant Environments

## 📖 Overview

A curated collection of dynamic, ready-to-use Vagrant environments for VirtualBox. This repository provides flexible `Vagrantfile` setups that support both **single** and **multi-node** configurations, enabling quick provisioning of development, test, or lab environments — from minimal VMs to full multi-node clusters.

```
┌──────────────┐
| Host Machine |
|  (Vagrant)   |
└───────┬──────┘
        │
        v
┌──────────────────────┐
| Virtualization Layer | <-- VirtualBox
└───────┬──────────────┘
        │
┌───────┴──────┬──────────────┬────────────┬───────┐
| Ubuntu Nodes | CentOS Nodes | Kubernetes | Other |
└──────────────┴──────────────┴────────────┴───────┘
```

## 🚀 What's Inside?

Each subdirectory represents a Vagrant environment with a dynamic `Vagrantfile`:

### 📦 Base Environments

- `ubuntu/` - Ubuntu-based environment
- `centos/` - Centos-based environment

### 📦 📦 Cluster Packs

- `kubernetes/` - Kubernetes multi-node cluster

## 🚀 Getting Started

### ✅ Prerequisites

- 🐱 **Host OS:** Linux, macOS, or Windows
- 📦 **Vagrant:** 2.4.x or newer
- 🖥️ **VirtualBox:** 7.1.x or newer

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
    ip: '192.168.56.10',
    ports: {
      'ssh' => { guest: 22, host: 2222 }
    },
    cpus: 2,
    memory: 2048
  },
  'node-2' => {
    ip: '192.168.56.11',
    ports: {
      'ssh' => { guest: 22, host: 2223 }
    },
    cpus: 2,
    memory: 2048
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
