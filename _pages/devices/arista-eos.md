---
title: "Arista EOS"
layout: single
classes: wide
permalink: "/devices/arista-eos/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**Arista EOS** (Extensible Operating System) is the network operating system for Arista switches. SiteRM controls these devices using the `sense.aristaeos` Ansible collection. Arista EOS supports VLAN creation and hardware-level QoS but does not support BGP control through SENSE.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.aristaeos.aristaeos` |
| **Ansible Collection** | [sense-aristaeos-collection](https://github.com/sdn-sense/sense-aristaeos-collection) |
| **VLAN Creation** | Yes |
| **BGP Control** | No |
| **BGP Multipath** | No |
| **QoS (network-level)** | Yes |
| **Ping / Traceroute** | Yes |

---

## Ansible Inventory Configuration

```yaml
inventory:
  aristaeos_s0:
    network_os: sense.aristaeos.aristaeos
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

SiteRM executes the following commands to collect topology and interface information from Arista EOS devices:

```bash
show version | json
show running-config
show interfaces | json
show lldp neighbors detail | json
show vlan | json
show interfaces switchport | json
```

For routing facts (if enabled):

```bash
show ip route vrf all | json
show ipv6 route vrf all | json
```

**Information extracted:**
- System version and hardware platform
- Interface details: description, MAC, MTU, bandwidth/speed, operational status, IPv4/IPv6 addresses, VRF assignments
- VLAN memberships and switchport trunk/access assignments
- LLDP neighbors: remote hostname, port, chassis ID — used for topology stitching
- Running configuration: VRF definitions, port-channel configuration

---

## VLAN Creation and Deletion

### Create VLAN (example: VLAN 1798, VRF `lhcone`, ports `Ethernet31/1` and `Ethernet30/1`)

```bash
# Create VLAN and L3 interface
vlan 1798
interface Vlan 1798
 description urn:ogf:network:service+8791cc78...:vt+l2-policy::Connection_1
 vrf lhcone
 ipv6 address fc00:0:0:0:0:0:0:16/124

# Add to trunk ports
interface Ethernet31/1
 switchport trunk allowed vlan add 1798
interface Ethernet30/1
 switchport trunk allowed vlan add 1798
```

### Delete VLAN

```bash
no vlan 1798
no interface Vlan 1798

interface Ethernet31/1
 switchport trunk allowed vlan remove 1798
interface Ethernet30/1
 switchport trunk allowed vlan remove 1798
```

**Note:** On Arista EOS, deleting the VLAN does not automatically remove it from trunk ports. SiteRM explicitly issues `switchport trunk allowed vlan remove` for each port when deleting a VLAN.

---

## QoS Configuration

Arista EOS supports hardware-level QoS through class-map and policy-map configurations. SENSE applies per-VLAN traffic policing using the `SENSE_QOS` policy map.

### QoS Setup (example: VLAN 3616 on `Ethernet12/1` and `Port-Channel502`, 50 Gbps guaranteed)

```bash
# Create VLAN class-map
class-map type qos match-any VLAN3616
 match vlan 3616
exit

# Apply policy (guaranteedCapped — fixed rate, no burst beyond limit)
policy-map type quality-of-service SENSE_QOS
 class VLAN3616
  set traffic-class 7
  police rate 50000 mbps burst-size 256 mbytes
 exit
exit

# Apply policy to interfaces
interface Ethernet12/1
 service-policy type qos input SENSE_QOS
interface Port-Channel502
 service-policy type qos input SENSE_QOS
```

### QoS for softCapped and bestEffort

```bash
# softCapped — guaranteed up to min_rate, bursts up to max_rate
policy-map type quality-of-service SENSE_QOS
 class VLAN3616
  set traffic-class 4
  police rate 50000 mbps burst-size 256 mbytes action set drop-precedence rate 100000 mbps burst-size 256 mbytes
 exit
exit

# bestEffort — 100 Mbps minimum, up to remaining capacity
policy-map type quality-of-service SENSE_QOS
 class VLAN3616
  set traffic-class 2
  police rate 100 mbps burst-size 256 mbytes action set drop-precedence rate 100000 mbps burst-size 256 mbytes
 exit
exit
```

### Remove QoS

```bash
no class-map type qos match-any VLAN3616

policy-map type quality-of-service SENSE_QOS
 no class VLAN3616
exit
```

---

## Ping and Traceroute

SENSE can issue active probes from Arista EOS devices (requires IP assigned to a SENSE VLAN interface).

### Ping

```bash
# IPv6 with VRF
ping vrf lhcone ipv6 fc00:0:0:0:0:0:0:17 timeout 5 repeat 10

# IPv6 without VRF
ping ipv6 fc00:0:0:0:0:0:0:17 timeout 5 repeat 10

# IPv4 with VRF
ping vrf lhcone ip 10.0.0.1 timeout 5 repeat 10
```

**Note:** Arista EOS uses the `ipv6` / `ip` keyword after `ping` (unlike OS 9/10 which use `ping6`), and uses `timeout` + `repeat` keywords (not `-c`/`-i` flags).

### Traceroute

```bash
# IPv6 with VRF
traceroute vrf lhcone ipv6 fc00:0:0:0:0:0:0:17

# IPv4 with VRF
traceroute vrf lhcone ip 10.0.0.1
```

---

## Switch Configuration in `main.yaml`

```yaml
aristaeos_s0:
  vlan_mtu: 9000
  rate_limit: true             # Enable per-port QoS
  vlan_range:
    - 3600-3699
  allports: false
  ports:
    Ethernet12/1:
      capacity: 100000         # Port capacity in Mbps
    Port-Channel502:
      capacity: 100000
      isAlias: urn:ogf:network:remote-site.net:2024:switch_s0:port_xyz
      wanlink: true
```

---

## Known Limitations and Notes

- **No BGP control**: Arista EOS does not support SENSE BGP control. Network routing to/from SENSE VLANs must be configured manually or via other automation tools.
- **QoS maximum policy rate**: There is a platform-enforced maximum police rate. The `max_policy_rate` site configuration parameter can be used to cap the maximum rate applied per class. Refer to Arista documentation for per-platform limits.
- **QoS traffic classes**: SENSE uses traffic classes 7 (guaranteedCapped), 4 (softCapped), and 2 (bestEffort). Ensure these classes are not already in use on the device.
- **LLDP**: Required on trunk ports for automatic topology discovery. Without LLDP, all inter-switch links must be manually defined via `isAlias`.

---

## Useful Links

- [sense-aristaeos-collection GitHub](https://github.com/sdn-sense/sense-aristaeos-collection)
- [Arista EOS Command Reference](https://www.arista.com/en/um-eos/eos-section-1-1-command-reference)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
