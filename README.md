# 🌐 Ansible Role: WireGuard L2VPN

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible Galaxy](https://img.shields.io/badge/Ansible%20Galaxy-cedricfarinazzo.wireguard__l2vpn-blue)](https://galaxy.ansible.com/cedricfarinazzo/wireguard_l2vpn)

> **An advanced Ansible role that creates a Layer 2 VPN using WireGuard mesh networking, VXLAN encapsulation, and Linux bridge interfaces.**

This role establishes a secure, scalable Layer 2 network overlay that allows distributed hosts to communicate as if they were on the same LAN segment, regardless of their physical network location.

## 🚀 Quick Start

```yaml
# Simple inventory setup
- hosts: wireguard_nodes
  roles:
    - cedricfarinazzo.wireguard_l2vpn
```

**Important**: All hosts must be in the `wireguard_nodes` inventory group for the full mesh topology to work correctly.

That's it! The role will automatically:
- ✅ Generate WireGuard keys for each host
- ✅ Create a full mesh VPN topology
- ✅ Configure VXLAN for Layer 2 connectivity  
- ✅ Set up bridge interfaces with static IPs
- ✅ Enable secure communication between all nodes

## 📋 Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | Linux with WireGuard kernel support |
| **Ansible** | Version 2.9+ |
| **Python** | Python 3.8+ on target hosts |
| **Network** | Internet connectivity for package installation |
| **Privileges** | Root or sudo access on target hosts |

### Supported Distributions

- ✅ **Debian** 11, 12
- ✅ **Ubuntu** 20.04, 22.04, 24.04

## ⚙️ Configuration

### Core Variables

The role uses sensible defaults but can be customized through these variables:

#### WireGuard Configuration
```yaml
# Package and service management
wireguard_package: wireguard           # Package name
wireguard_package_state: present       # Package state
wireguard_service_state: started       # Service state
wireguard_service_enabled: true        # Enable on boot

# Network settings
wireguard_port: 51820                  # UDP port for WireGuard
wireguard_interface: wg0               # Interface name
wireguard_address_prefix: "10.10.10"   # IP prefix for mesh network
wireguard_netmask: 24                  # Subnet mask
wireguard_persistent_keepalive: 25     # NAT traversal

```

#### VXLAN Configuration
```yaml
vxlan_interface: vxlan0                # VXLAN interface name
vxlan_id: 42                          # VXLAN Network Identifier (VNI)
vxlan_port: 4789                      # VXLAN UDP port
vxlan_multicast_group: "239.1.1.42"   # Multicast group for VXLAN
```

#### Bridge Configuration
```yaml
bridge_interface: br0                  # Bridge interface name
bridge_address_prefix: "172.16.0"     # IP prefix for bridge network
bridge_netmask: 24                    # Bridge subnet mask
bridge_address_offset: "{{ inventory_hostname | ansible.utils.hash('sha1') | regex_replace('[^0-9]','') | truncate(2, True, '') | int + 10 }}"
```

## 🏗️ Network Architecture

### Network Stack Components

| Layer | Component | Purpose | Configuration |
|-------|-----------|---------|---------------|
| **L2 Bridge** | `br0` | Provides Layer 2 switching | Static IPs: `172.16.0.x/24` |
| **VXLAN** | `vxlan0` | L2 over L3 encapsulation | VNI: 42, Multicast: `239.1.1.42` |
| **VPN** | `wg0` | Secure mesh networking | Full mesh topology: `10.10.10.x/24` |
| **Physical** | `eth0` | Internet connectivity | DHCP/Static (existing) |

### Multi-Node Topology

```
    ┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
    │       Node A         │     │       Node B         │     │       Node C         │
    │                      │     │                      │     │                      │
    │  ┏━━━━━━━━━━━━━━━┓   │     │  ┏━━━━━━━━━━━━━━━┓   │     │  ┏━━━━━━━━━━━━━━━┓   │
    │  ┃ br0           ┃   │     │  ┃ br0           ┃   │     │  ┃ br0           ┃   │
    │  ┃ 172.16.0.11   ┃   │     │  ┃ 172.16.0.12   ┃   │     │  ┃ 172.16.0.13   ┃   │
    │  ┗━━━━━━┯━━━━━━━━┛   │     │  ┗━━━━━━┯━━━━━━━━┛   │     │  ┗━━━━━━┯━━━━━━━━┛   │
    │         │            │     │         │            │     │         │            │
    │  ┌──────┴──────┐     │     │  ┌──────┴──────┐     │     │  ┌──────┴──────┐     │
    │  │ vxlan0      │     │     │  │ vxlan0      │     │     │  │ vxlan0      │     │
    │  │ VNI: 42     │     │     │  │ VNI: 42     │     │     │  │ VNI: 42     │     │
    │  └──────┬──────┘     │     │  └──────┬──────┘     │     │  └──────┬──────┘     │
    │         │            │     │         │            │     │         │            │
    │  ┌──────┴──────┐     │     │  ┌──────┴──────┐     │     │  ┌──────┴──────┐     │
    │  │ wg0         │     │     │  │ wg0         │     │     │  │ wg0         │     │
    │  │ 10.10.10.1  │     │     │  │ 10.10.10.2  │     │     │  │ 10.10.10.3  │     │
    │  └──────┬──────┘     │     │  └──────┬──────┘     │     │  └──────┬──────┘     │
    └─────────┼────────────┘     └─────────┼────────────┘     └─────────┼────────────┘
              │                            │                            │
              └────────────┬───────────────┴─────────────┬──────────────┘
                           │                             │
                    ┌──────┴──────┐               ┌──────┴──────┐
                    │   Internet   │               │   Internet   │
                    │  (Encrypted  │               │ (Encrypted   │
                    │   Tunnels)   │               │  Tunnels)    │
                    └─────────────┘               └─────────────┘
```

### Traffic Flow

1. **Application Traffic** → Bridge interface (`br0`)
2. **L2 Frames** → VXLAN encapsulation (`vxlan0`)  
3. **VXLAN Packets** → WireGuard encryption (`wg0`)
4. **Encrypted Packets** → Internet routing

## 🔧 How It Works

1. **WireGuard Setup**: Automatic key generation and full mesh VPN configuration
2. **VXLAN Layer**: Creates Layer 2 overlay network using multicast learning
3. **Bridge Integration**: Linux bridge provides local L2 switching with static IPs

## 📦 Dependencies

This role has **zero external dependencies** and uses only:
- ✅ **Ansible Core Modules** (built-in)
- ✅ **Linux Kernel Features** (WireGuard, VXLAN, Bridges)
- ✅ **Standard Packages** (available in all major distributions)

## 🎯 Usage Examples

### Basic Multi-Site Setup
```yaml
- hosts: wireguard_nodes
  become: true
  roles:
    - role: cedricfarinazzo.wireguard_l2vpn
      vars:
        bridge_address_prefix: "192.168.100"
```

## 🔒 Security Considerations

### Key Management
- **Automatic Generation**: WireGuard keys are automatically generated if not provided
- **Key Rotation**: Implement regular key rotation procedures (TODO)

### Network Security
- **Encryption**: All traffic encrypted with ChaCha20Poly1305
- **Authentication**: Cryptographic authentication prevents man-in-the-middle attacks
- **Perfect Forward Secrecy**: Regular key rotation provides perfect forward secrecy
- **IP Allowlists**: Configure restrictive allowed IPs for each peer


## 🧪 Testing

### Quick Testing
```bash
# Run test against debian12
make test

# Test against all supported distributions
make molecule-test-all
```

### Test Coverage
- Package installation and service configuration
- Full mesh connectivity between all nodes
- VXLAN and bridge interface validation

## 👥 Authors & Contributors

**Cédric Farinazzo** ([@cedricfarinazzo](https://github.com/cedricfarinazzo)) - *Author and Maintainer*

