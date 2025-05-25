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

# IP address override (set in host_vars)
wireguard_ip: ""              # Override automatic IP assignment for specific hosts
                                       # Example: "10.10.10.50"
                                       # If empty, IP is auto-assigned based on host index
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

# Bridge IP address override (set in host_vars)
bridge_ip: ""                         # Override automatic bridge IP assignment for specific hosts
                                       # Example: "172.16.0.50"
                                       # If empty, IP is auto-assigned based on host index
```

#### Endpoint Configuration
```yaml
# Advanced per-host client-only control (set in host_vars)
wireguard_client_only_peers: []       # List of peer hostnames to exclude endpoints for
```

#### Key Rotation Configuration
```yaml
# Automatic key rotation settings
wireguard_key_rotation_enabled: false      # Enable automatic key rotation
wireguard_key_rotation_days: 30            # Rotate keys every X days
```

**Key Rotation Behavior:**
- Key rotation is checked on every Ansible run when `wireguard_key_rotation_enabled: true`
- Keys are rotated automatically if they are older than `wireguard_key_rotation_days`
- Old keys are automatically backed up to `/etc/wireguard/backups/` before rotation
- After rotation, the new keys are immediately used in the mesh configuration
- No cron jobs or background processes are created - rotation happens during deployment

⚠️ Wireguard service will be restarted after key rotation introducing a short downtime.

**Endpoint Behavior:**
- By default, endpoints are included for all peers with valid IP addresses
- Use `wireguard_client_only_peers` to specify which peer endpoints should be excluded from this node's config
- Hosts behind NAT or without internet access should be added to client-only peers list

**PersistentKeepalive Behavior:**
- `PersistentKeepalive` is automatically enabled only when this host is acting as a client to a peer
- This happens when the current host is listed in the peer's `wireguard_client_only_peers` list
- Optimizes traffic by avoiding unnecessary keepalives in server-to-server connections

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
              └────────────────────────────┬────────────────────────────┘
                                           │
                                    ┌──────┴──────┐
                                    │   Internet  │
                                    │  (Encrypted │
                                    │   Tunnels)  │
                                    └─────────────┘
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

### Client-Only Node Configuration
For hosts that are not accessible from the internet (e.g., behind NAT without port forwarding):
```yaml
- hosts: wireguard_nodes
  become: true
  roles:
    - role: cedricfarinazzo.wireguard_l2vpn

# Configuration on the server side:
# host_vars/server1.yml (publicly accessible server)
wireguard_client_only_peers:
  - internal_node1
  - internal_node2

# host_vars/server2.yml (another publicly accessible server)
wireguard_client_only_peers:
  - internal_node1
  - internal_node2
```
This configuration means:
- `server1` and `server2` **will NOT** have `Endpoint` lines for `internal_node1` and `internal_node2`
- `internal_node1` and `internal_node2` **will** have `Endpoint` lines for `server1` and `server2`
- `internal_node1` and `internal_node2` **will** have `PersistentKeepalive` enabled for `server1` and `server2`
- `server1` and `server2` will **NOT** have `PersistentKeepalive` between each other (server-to-server)
- This optimizes NAT traversal while avoiding unnecessary keepalives

## 🔒 Security Considerations

## Key Management

- **Automatic Generation**: WireGuard keys are automatically generated if not provided
- **Key Rotation**: WireGuard keys are rotated automatically and old keys are backed up with a little downtime

#### Network Security
- **Encryption**: All traffic encrypted with ChaCha20Poly1305
- **Authentication**: Cryptographic authentication prevents man-in-the-middle attacks
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

