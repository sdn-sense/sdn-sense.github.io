---
title: "Dell EMC OS 9"
layout: single
classes: wide
permalink: "/devices/dell-os9/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**Dell EMC Networking OS 9** (also known as FTOS or DNOS9) is the operating system for Dell PowerEdge and Force10 chassis-based switches. SiteRM controls these devices using the `sense.dellos9` Ansible collection.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.dellos9.dellos9` |
| **Ansible Collection** | [sense-dellos9-collection](https://github.com/sdn-sense/sense-dellos9-collection) |
| **VLAN Creation** | Yes |
| **BGP Control** | Yes |
| **BGP Multipath** | No |
| **QoS (network-level)** | Yes (max 3 rate limits per port — see notes) |
| **Ping / Traceroute** | Yes |

---

## Ansible Inventory Configuration

```yaml
inventory:
  dellos9_s0:
    network_os: sense.dellos9.dellos9
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

SiteRM executes the following commands to collect topology and interface information from Dell OS 9 devices:

```bash
show running-config
show lldp neighbors detail
show interfaces
show system
```

**Information extracted:**
- System MAC address (`show system`)
- Interface details: description, MAC, MTU, bandwidth/speed, operational status, IPv4/IPv6 addresses, VRF assignments, tagged VLAN members
- LLDP neighbors: remote hostname, port, chassis ID — used for topology stitching
- Running configuration: VLAN definitions, switchport trunk memberships, port-channel members

---

## VLAN Creation and Deletion

SiteRM creates VLAN interfaces on Dell OS 9 with the following commands:

### Create VLAN (example: VLAN 3607, VRF `lhcone`, port `hundredGigE 1/7`)

```bash
interface Vlan 3607
 mtu 9000
 ip vrf forwarding lhcone
 description urn:ogf:network:service+858b5c37...:vt+l2-policy::Connection_1
 ipv6 address fc00:0:0:0:0:0:0:16/124
 tagged hundredGigE 1/7
 no shutdown
```

**Note on `tagged` syntax:** Dell OS 9 uses `tagged <interface>` inside the VLAN interface stanza (not `switchport trunk allowed vlan` as in OS 10).

### Delete VLAN

```bash
no interface Vlan 3607
```

**Port-level cleanup** (removing from trunk) is handled via `no tagged` inside the interface, but Dell OS 9 automatically removes the VLAN from all tagged ports when the VLAN interface is deleted.

---

## BGP Configuration

Dell OS 9 has specific requirements for BGP that differ from other platforms:

1. IPv6 neighbors **must be declared in `address-family ipv4 multicast`** (or `ipv4 vrf <NAME>`) first, then activated in `address-family ipv6 unicast`.
2. The `no neighbor <IP> activate` must appear in the IPv4 address-family to prevent IPv4 activation of an IPv6 neighbor.

### Create BGP (example: ASN 64513, VRF `lhcone`)

```bash
# Step 1: Prefix lists
ipv6 prefix-list sense-abc123-from
 permit 2001:48d0:3001:110::/64
ipv6 prefix-list sense-abc123-to
 permit 2605:d9c0:2:fff1::/64

# Step 2: Route maps
route-map sense-abc123-mapin permit 10
 match ipv6 address sense-abc123-from
route-map sense-abc123-mapout permit 10
 match ipv6 address sense-abc123-to

# Step 3: IPv4 address-family (required for IPv6 neighbor declaration)
router bgp 64513
 address-family ipv4 vrf lhcone
  neighbor fc00:0:0:0:0:0:0:17 remote-as 65000
  neighbor fc00:0:0:0:0:0:0:17 no shutdown
  no neighbor fc00:0:0:0:0:0:0:17 activate

# Step 4: IPv6 address-family
router bgp 64513
 address-family ipv6 unicast vrf lhcone
  network 2605:d9c0:2:fff1::/64
  neighbor fc00:0:0:0:0:0:0:17 activate
  neighbor fc00:0:0:0:0:0:0:17 soft-reconfiguration inbound
  neighbor fc00:0:0:0:0:0:0:17 route-map sense-abc123-mapin in
  neighbor fc00:0:0:0:0:0:0:17 route-map sense-abc123-mapout out
```

### Delete BGP

```bash
no ipv6 prefix-list sense-abc123-from
no ipv6 prefix-list sense-abc123-to
no route-map sense-abc123-mapin permit 10
no route-map sense-abc123-mapout permit 10
router bgp 64513
 address-family ipv4 vrf lhcone
  no neighbor fc00:0:0:0:0:0:0:17 remote-as 65000
 address-family ipv6 unicast vrf lhcone
  no network 2605:d9c0:2:fff1::/64
```

---

## Ping and Traceroute

SENSE can issue active probes from Dell OS 9 devices (requires IP assigned to a SENSE VLAN interface).

### Ping

```bash
# IPv6 with VRF
ping vrf lhcone fc00:0:0:0:0:0:0:17 count 10 timeout 5

# IPv6 without VRF
ping fc00:0:0:0:0:0:0:17 count 10 timeout 5

# IPv4
ping vrf lhcone 10.0.0.1 count 10 timeout 5
```

### Traceroute

```bash
# IPv6 with VRF
traceroute vrf lhcone fc00:0:0:0:0:0:0:17

# IPv4
traceroute vrf lhcone 10.0.0.1
```

---

## Switch Configuration in `main.yaml`

```yaml
dellos9_s0:
  rsts_enabled: ipv4,ipv6    # Enable BGP control
  private_asn: 64513          # Private ASN assigned by SENSE team
  vrf: lhcone                 # VRF name for SENSE traffic
  vlan_mtu: 9000
  rate_limit: true            # Enable per-port QoS (max 3 rate limits per port)
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

- **QoS rate limits**: Dell OS 9 allows a **maximum of 3 rate-limit policies per port**. If more than 3 SENSE paths with rate limiting are active on a single port simultaneously, subsequent QoS rules will fail. SENSE does not enforce this limit automatically — it is the admin's responsibility to configure sites appropriately.
- **BGP neighbor quirk**: IPv6 BGP neighbors must be declared in `address-family ipv4` before activation in `address-family ipv6`. This is a Dell OS 9 platform limitation that SiteRM handles automatically through its two-step BGP template.
- **BGP Multipath**: Not supported on Dell OS 9. Each path requires a separate VLAN and BGP peer.
- **LLDP**: Required on trunk ports for automatic topology discovery. Without LLDP, all inter-switch links must be manually defined via `isAlias`.
- **Tested versions**: Dell OS 9.11 and 9.14

---

## Useful Links

- [sense-dellos9-collection GitHub](https://github.com/sdn-sense/sense-dellos9-collection)
- [Dell EMC OS 9 CLI Reference](https://www.dell.com/support/manuals/en-us/dell-emc-os-9)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
