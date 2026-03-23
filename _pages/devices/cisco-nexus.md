---
title: "Cisco Nexus 9/10"
layout: single
classes: wide
permalink: "/devices/cisco-nexus/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**Cisco Nexus 9000/10000 series** running NX-OS is supported by SiteRM via the `sense.cisconx9` Ansible collection. Cisco NX-OS supports VLAN creation, BGP control, and BGP multipath through SENSE.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.cisconx9.cisconx9` |
| **Ansible Collection** | [sense-cisconx9-collection](https://github.com/sdn-sense/sense-cisconx9-collection) |
| **VLAN Creation** | Yes |
| **BGP Control** | Yes |
| **BGP Multipath** | Yes |
| **QoS (network-level)** | No |
| **Ping / Traceroute** | Yes |

---

## Ansible Inventory Configuration

```yaml
inventory:
  cisconx_s0:
    network_os: sense.cisconx9.cisconx9
    host: 192.168.1.10
    user: admin
    pass: <password>            # or use sshkey
    # sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
    snmp_params:
      session_vars:
        community: public
        hostname: 192.168.1.10
        version: 2
```

---

## Facts Collection

SiteRM executes the following commands to collect topology and interface information from Cisco NX-OS devices (output in JSON format):

```bash
show version | json
show running-config | json
show interface | json
show vlan | json
show ipv6 interface vrf all | json
show lldp neighbors detail | json
show interface switchport | json
```

For routing facts:

```bash
show ip route vrf all | json
show ipv6 route vrf all | json
```

**Information extracted:**
- System version, platform model, NX-OS version
- Interface details: description, MAC, MTU, bandwidth/speed, operational status, IPv4/IPv6 addresses, VRF memberships
- VLAN membership and switchport trunk/access assignments
- IPv6 interface details across all VRFs
- LLDP neighbors: remote hostname, port, chassis ID — used for topology stitching
- IPv4 and IPv6 routing tables per VRF

---

## VLAN Creation and Deletion

### Create VLAN (example: VLAN 3607, VRF `lhcone`, port `hundredGigE 1/7`)

```bash
# Create VLAN
vlan 3607

# Configure VLAN interface
interface Vlan3607
 mtu 9000
 vrf member lhcone
 description urn:ogf:network:service+858b5c37...:vt+l2-policy::Connection_1
 ipv6 address fc00:0:0:0:0:0:0:16/124
 no shutdown

# Add to trunk port
interface hundredGigE 1/7
 switchport trunk allowed vlan add 3607
```

**Note:** Cisco NX-OS uses `vrf member` (not `ip vrf forwarding` as in Dell OS), and `interface Vlan3607` has no space before the VLAN number.

### Delete VLAN

```bash
no vlan 3607
no interface Vlan3607

interface hundredGigE 1/7
 switchport trunk allowed vlan remove 3607
```

---

## BGP Configuration

Cisco NX-OS BGP configuration applies prefix lists and route maps inline, then configures the BGP router in a single pass (no two-step process needed unlike Dell OS 10).

### Create BGP (example: ASN 64513, VRF `lhcone`)

```bash
# Prefix lists
ipv6 prefix-list sense-abc123-from permit 2001:48d0:3001:110::/64
ipv6 prefix-list sense-abc123-to permit 2605:d9c0:2:fff1::/64

# Route maps
route-map sense-abc123-mapin permit 10
 match ipv6 address prefix-list sense-abc123-from
route-map sense-abc123-mapout permit 10
 match ipv6 address prefix-list sense-abc123-to

# BGP configuration
router bgp 64513
 address-family ipv6 unicast
  soft-reconfiguration inbound
  network 2605:d9c0:2:fff1::/64
 neighbor fc00:0:0:0:0:0:0:17 remote-as 65000
  address-family ipv6 unicast
   route-map sense-abc123-mapin in
   route-map sense-abc123-mapout out
```

### Delete BGP

```bash
no ipv6 prefix-list sense-abc123-from
no ipv6 prefix-list sense-abc123-to
no route-map sense-abc123-mapin permit 10
no route-map sense-abc123-mapout permit 10

router bgp 64513
 address-family ipv6 unicast
  no network 2605:d9c0:2:fff1::/64
 no neighbor fc00:0:0:0:0:0:0:17 remote-as 65000
```

---

## Ping and Traceroute

SENSE can issue active probes from Cisco NX-OS devices (requires IP assigned to a SENSE VLAN interface).

### Ping

```bash
# IPv6
ping6 fc00:0:0:0:0:0:0:17 timeout 5 count 10

# IPv4
ping 10.0.0.1 timeout 5 count 10
```

**Note:** Cisco NX-OS uses `ping6` for IPv6 (separate command from `ping`). VRF is not part of the ping syntax in the current SENSE template — routing is determined by the routing table for the VRF the VLAN interface belongs to.

### Traceroute

```bash
# IPv6
traceroute6 fc00:0:0:0:0:0:0:17

# IPv4
traceroute 10.0.0.1
```

---

## Switch Configuration in `main.yaml`

```yaml
cisconx_s0:
  rsts_enabled: ipv4,ipv6    # Enable BGP control
  private_asn: 64513          # Private ASN assigned by SENSE team
  vrf: lhcone                 # VRF name for SENSE traffic
  vlan_mtu: 9000
  vlan_range:
    - 3600-3699
    - 3985-3989
  allports: false
  ports:
    hundredGigE 1/1:
      capacity: 100000         # Port capacity in Mbps
    hundredGigE 1/7:
      capacity: 100000
      isAlias: urn:ogf:network:remote-site.net:2024:switch_s0:port_xyz
      wanlink: true
```

---

## Known Limitations and Notes

- **No QoS**: Cisco NX-OS does not support SENSE network-level QoS rate limiting. Traffic shaping must be configured independently.
- **BGP VRF**: The current SENSE NX-OS BGP template does not inject routes into a specific VRF address-family — BGP is configured globally. Sites requiring VRF-scoped BGP should verify behavior with the SENSE team.
- **`soft-reconfiguration inbound`**: Automatically enabled when a network statement is configured. This stores received routes before filtering and allows `show bgp ipv6 unicast neighbors X received-routes` to work.
- **LLDP**: Required on trunk ports for automatic topology discovery. Without LLDP, all inter-switch links must be manually defined via `isAlias`.
- **Feature requirements**: Ensure `feature bgp`, `feature interface-vlan`, and `feature lldp` are enabled on the switch before deploying.

---

## Useful Links

- [sense-cisconx9-collection GitHub](https://github.com/sdn-sense/sense-cisconx9-collection)
- [Cisco NX-OS Command Reference](https://www.cisco.com/c/en/us/support/switches/nexus-9000-series-switches/products-command-reference-list.html)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
