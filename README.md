# Ansible Role: Wireguard L2VPN

An Ansible Role that sets up a full mesh Wireguard network between all hosts, configures a VXLAN interface over the Wireguard network, and creates a bridge interface with a static IP.

## Requirements

- Linux hosts with systemd-networkd
- Python for Ansible
- Internet connectivity to install packages

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Wireguard package and service settings
wireguard_package: wireguard
wireguard_package_state: present
wireguard_service_state: started
wireguard_service_enabled: true

# Wireguard network configuration
wireguard_port: 51820
wireguard_interface: wg0
wireguard_address_prefix: "10.10.10"
wireguard_netmask: 24

# VXLAN configuration
vxlan_interface: vxlan0
vxlan_id: 42
vxlan_port: 4789
vxlan_multicast_group: "239.1.1.42"

# Bridge configuration
bridge_interface: br0
bridge_address_prefix: "172.16.0"
bridge_netmask: 24
bridge_address_offset: "{{ inventory_hostname | ansible.utils.hash('sha1') | regex_replace('[^0-9]','') | truncate(2, True, '') | int + 10 }}"
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: servers
  roles:
    - wireguard-l2vpn
```

## Network Architecture

This role configures a network with the following components:

1. A full mesh Wireguard VPN between all hosts in the inventory
2. A VXLAN interface (vxlan0) running on top of the Wireguard interface (wg0)
3. A bridge interface (br0) that includes the VXLAN interface
4. Static IP addressing on the bridge interface

### Network Diagram

```
                    Node 1                                   Node 2
┌───────────────────────────────────┐    ┌───────────────────────────────────┐
│                                   │    │                                   │
│  ┌────────────┐                   │    │  ┌────────────┐                   │
│  │ br0        │ 172.16.0.11/24    │    │  │ br0        │ 172.16.0.12/24    │
│  └─────┬──────┘                   │    │  └─────┬──────┘                   │
│        │                          │    │        │                          │
│  ┌─────┴──────┐                   │    │  ┌─────┴──────┐                   │
│  │ vxlan0     │ Multicast: 239.1.1.42   │  │ vxlan0     │ VNI: 42          │
│  └─────┬──────┘                   │    │  └─────┬──────┘                   │
│        │                          │    │        │                          │
│  ┌─────┴──────┐                   │    │  ┌─────┴──────┐                   │
│  │ wg0        │ 10.10.10.1/24     │    │  │ wg0        │ 10.10.10.2/24     │
│  └─────┬──────┘                   │    │  └─────┬──────┘                   │
└────────┼──────────────────────────┘    └────────┼──────────────────────────┘
         │                                        │
         │                                        │
         └───────────────WireGuard───────────────┐│
                         Full Mesh                │
         ┌────────────────────────────────────────┘
         │
┌────────┼──────────────────────────┐
│        │                          │
│  ┌─────┴──────┐                   │
│  │ wg0        │ 10.10.10.3/24     │
│  └─────┬──────┘                   │
│        │                          │
│  ┌─────┴──────┐                   │
│  │ vxlan0     │ VXLAN Port: 4789  │
│  └─────┬──────┘                   │
│        │                          │
│  ┌─────┴──────┐                   │
│  │ br0        │ 172.16.0.13/24    │
│  └────────────┘                   │
│                                   │
└───────────────────────────────────┘
           Node 3
```

## How It Works

1. **Wireguard Setup**: Each host generates a private/public key pair and creates a Wireguard interface with connections to all other hosts.
2. **VXLAN Layer**: A VXLAN interface is created to encapsulate L2 traffic across the Wireguard network, using multicast address 239.1.1.42.
3. **Bridge Configuration**: A bridge interface is set up with a static IP from the 172.16.0.0/24 range.

## Security Notes

- For production use, you should manage Wireguard keys securely through your Ansible vault or other secret management system.
- The role automatically generates Wireguard keys if they are not provided.

## Testing

This role includes Molecule tests to validate functionality in a multi-node cluster setup. To run the tests:

1. Make sure you have Docker installed and running with appropriate privileges
2. Run the test script:

```bash
./run-tests.sh
```

By default, the tests use Debian 11. You can specify a different distribution:

```bash
./run-tests.sh ubuntu2004  # Test with Ubuntu 20.04
```

### Test Environment

The testing environment:
- Creates three Docker containers with the specified distribution
- Configures a full mesh Wireguard network between the containers
- Sets up VXLAN and bridge interfaces on each container
- Verifies connectivity between the nodes
- Tests the L2VPN functionality by checking ping connectivity

### Test Requirements

- Docker with elevated privileges (for network operations)
- Python 3 with virtual environment support
- Internet connectivity to download Docker images and packages
```

The advanced validation tests perform the following checks:
- Interface existence and status verification
- Full connectivity testing between all nodes
- Bandwidth testing using iperf3
- File transfer testing over the L2VPN
- MTU verification across all interfaces
- Multicast communication testing

You can also run these tests using the Makefile:

```bash
make advanced-test
```

### Test Environment

The testing environment:
- Creates a Docker container with the specified distribution
- Installs Wireguard and related packages
- Configures all required interfaces and services
- Verifies the setup is working correctly

### Test Requirements

- Docker with elevated privileges (for network operations)
- Python 3 with virtual environment support
- Internet connectivity to download Docker images and packages

## Troubleshooting

### Common Issues

#### Wireguard Interface Not Coming Up

If the Wireguard interface isn't coming up, check:

```bash
# Check if Wireguard kernel module is loaded
lsmod | grep wireguard

# Check Wireguard interface status
ip link show wg0

# Check Wireguard logs
journalctl -u wg-quick@wg0
```

#### No Connectivity Between Nodes

If nodes can't communicate over the L2VPN:

1. Verify Wireguard connectivity:
   ```bash
   # Check Wireguard peers
   wg show

   # Check if Wireguard traffic is flowing
   tcpdump -i wg0
   ```

2. Verify VXLAN configuration:
   ```bash
   # Check VXLAN interface
   ip -d link show vxlan0
   
   # Check multicast routing
   ip mroute show
   ```

3. Verify bridge configuration:
   ```bash
   # List bridge interfaces
   brctl show
   
   # Check bridge forwarding
   bridge fdb show
   ```

#### MTU Issues

If you're experiencing packet fragmentation or connectivity problems:

```bash
# Check MTU on all relevant interfaces
ip link show | grep mtu

# Set appropriate MTU values (adjust as needed)
ip link set dev wg0 mtu 1420
ip link set dev vxlan0 mtu 1400
ip link set dev br0 mtu 1400
```

Consider that the MTU for each interface should be set with overhead in mind:
- Wireguard overhead: ~60 bytes
- VXLAN overhead: ~50 bytes

#### Firewall Issues

Ensure your firewall allows:
- UDP port 51820 (or your configured Wireguard port)
- UDP port 4789 (VXLAN)
- Protocol 112 (VRRP) if using VRRP
- Multicast traffic (239.1.1.42)

```bash
# For iptables-based firewalls
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -p udp --dport 4789 -j ACCEPT
iptables -A INPUT -d 239.1.1.42/32 -j ACCEPT
```

## License

MIT

## Author Information

This role was created by SEDINFRA team.
