---
title: "Dell EMC OS 10"
layout: single
classes: wide
permalink: "/devices/dell-os10/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**Dell EMC Networking OS 10** (DNOS10) is the operating system for Dell PowerSwitch series switches. SiteRM controls these devices using the `sense.dellos10` Ansible collection.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.dellos10.dellos10` |
| **Ansible Collection** | [sense-dellos10-collection](https://github.com/sdn-sense/sense-dellos10-collection) |
| **VLAN Creation** | Yes |
| **BGP Control** | Yes |
| **BGP Multipath** | Yes |
| **QoS (network-level)** | No |
| **Ping / Traceroute** | Yes |

---

## Ansible Inventory Configuration

```yaml
inventory:
  dellos10_s0:
    network_os: sense.dellos10.dellos10
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

SiteRM executes the following commands to collect topology and interface information from Dell OS 10 devices:

```bash
show running-config
show lldp neighbors detail
show interface
show interface port-channel
show system
```

**Information extracted:**
- System MAC address (`show system`)
- Interface details: description, MAC, MTU, bandwidth/speed, operational status, IPv4/IPv6 addresses, VRF assignments, tagged VLAN members
- Port-channel members and aggregated link state
- LLDP neighbors: remote hostname, port, chassis ID — used for topology stitching
- Running configuration: VLAN definitions, switchport trunk memberships, VRF assignments

---

## VLAN Creation and Deletion

### Create VLAN (example: VLAN 3607, VRF `lhcone`, port `Port-channel 102`)

```bash
interface vlan 3607
 mtu 9000
 ip vrf forwarding lhcone
 description urn:ogf:network:service+858b5c37...:vt+l2-policy::Connection_1
 ipv6 address fc00:0:0:0:0:0:0:16/124
 no shutdown

interface Port-channel 102
 switchport trunk allowed vlan 3607
```

**Note on switchport syntax:** Dell OS 10 uses `switchport trunk allowed vlan <id>` on the physical or port-channel interface (not inside the VLAN interface stanza, unlike Dell OS 9).

### Delete VLAN

```bash
no interface vlan 3607
```

**Switchport cleanup:** Dell OS 10 automatically removes the deleted VLAN from all trunk ports when the VLAN interface is deleted; no explicit `no switchport trunk allowed vlan` command is needed.

---

## BGP Configuration

Dell OS 10 BGP configuration uses a **two-step process**:

1. **Step 1 (`_before` run)**: Prefix lists are configured first with `ignore_errors: true`. Dell OS 10 returns an error if the same prefix list is applied a second time, so the before-run is tolerant of failures.
2. **Step 2 (main run)**: Route maps and BGP neighbors are configured.

### Create BGP (example: ASN 64513, VRF `lhcone`)

**Step 1 — Prefix lists** (run with `ignore_errors: true`):

```bash
ipv6 prefix-list sense-abc123-from permit 2001:48d0:3001:110::/64
ipv6 prefix-list sense-abc123-to permit 2605:d9c0:2:fff1::/64
```

**Step 2 — Route maps and BGP**:

```bash
# Route maps
route-map sense-abc123-mapin permit 10
 match ipv6 address sense-abc123-from
route-map sense-abc123-mapout permit 10
 match ipv6 address sense-abc123-to

# BGP router
router bgp 64513
 vrf lhcone
  address-family ipv6 unicast
   network 2605:d9c0:2:fff1::/64
  neighbor fc00:0:0:0:0:0:0:17
   remote-as 65000
   no shutdown
   address-family ipv6 unicast
     activate
     route-map sense-abc123-mapin in
     route-map sense-abc123-mapout out
```

### Delete BGP

```bash
no route-map sense-abc123-mapin
no route-map sense-abc123-mapout

router bgp 64513
 vrf lhcone
  address-family ipv6 unicast
   no network 2605:d9c0:2:fff1::/64
  no neighbor fc00:0:0:0:0:0:0:17
no ipv6 prefix-list sense-abc123-from
no ipv6 prefix-list sense-abc123-to
```

---

## Ping and Traceroute

SENSE can issue active probes from Dell OS 10 devices (requires IP assigned to a SENSE VLAN interface).

### Ping

```bash
# IPv6 with VRF
ping6 vrf lhcone fc00:0:0:0:0:0:0:17 -c 10 -i 5

# IPv6 without VRF
ping6 fc00:0:0:0:0:0:0:17 -c 10 -i 5

# IPv4 with VRF
ping vrf lhcone 10.0.0.1 -c 10 -i 5
```

**Note:** Dell OS 10 uses the Linux-style `-c` (count) and `-i` (interval/timeout) flags, unlike Dell OS 9 which uses the `count` and `timeout` keywords.

### Traceroute

```bash
# IPv6 with VRF
traceroute vrf lhcone fc00:0:0:0:0:0:0:17

# IPv4 with VRF
traceroute vrf lhcone 10.0.0.1
```

---

## Switch Configuration in `main.yaml`

```yaml
dellos10_s0:
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
    Port-channel 102:
      capacity: 100000
      isAlias: urn:ogf:network:remote-site.net:2024:switch_s0:port_xyz
      wanlink: true
```

---

## Known Limitations and Notes

- **QoS**: Not supported on Dell OS 10 in SENSE. Rate limiting is not applied at the switch level for OS 10.
- **BGP prefix-list quirk**: Dell OS 10 returns an error if a prefix-list is applied twice. SiteRM works around this by running prefix-list configuration separately with `ignore_errors: true` before the main configuration run.
- **BGP Multipath**: Supported. Multiple VLAN + BGP peer pairs can share the same port with independent routing.
- **LLDP**: Required on trunk ports for automatic topology discovery. Without LLDP, all inter-switch links must be manually defined via `isAlias`.
- **Tested versions**: Dell OS 10.5.4.4

---

## Useful Links

- [sense-dellos10-collection GitHub](https://github.com/sdn-sense/sense-dellos10-collection)
- [Dell EMC OS 10 CLI Reference](https://www.dell.com/support/manuals/en-us/dell-emc-smartfabric-os10)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
