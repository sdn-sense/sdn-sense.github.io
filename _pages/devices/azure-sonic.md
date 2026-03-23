---
title: "Azure SONiC"
layout: single
classes: wide
permalink: "/devices/azure-sonic/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**Azure SONiC** (Software for Open Networking in the Cloud) is an open-source network operating system based on Linux and Debian. SiteRM controls these devices using the `sense.sonic` Ansible collection. Azure SONiC supports VLAN creation, BGP control, and BGP multipath through SENSE.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.sonic.sonic` |
| **Ansible Collection** | [sense-sonic-collection](https://github.com/sdn-sense/sense-sonic-collection) |
| **VLAN Creation** | Yes |
| **BGP Control** | Yes |
| **BGP Multipath** | Yes |
| **QoS (network-level)** | No |
| **Ping / Traceroute** | Yes |

---

## Ansible Inventory Configuration

```yaml
inventory:
  sonic_s0:
    network_os: sense.sonic.sonic
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

SiteRM executes the following commands to collect topology and interface information from Azure SONiC devices:

```bash
show runningconfiguration all
show interfaces status
show lldp neighbor
```

**Information extracted:**
- Full running configuration as JSON (VLANs, port assignments, BGP, VRFs, static routes)
- Interface status: operational state, MTU, speed, media type, line protocol
- Port-channel members and VLAN membership (tagged/untagged)
- IPv4 and IPv6 addresses with subnet information
- Static routes with next hop and VRF info
- MAC addresses
- LLDP neighbor details: local port, remote system name, remote port ID, chassis ID — used for topology stitching

---

## VLAN Creation and Deletion

Azure SONiC uses a management framework based on the SONiC configuration database (`config_db`) and is configured through SONiC management CLI or REST API. The `sense.sonic` Ansible collection applies VLAN and BGP configuration by communicating with the SONiC management daemon directly.

### Example: VLAN 3617, VRF `lhcone`, port `Port-channel 102`

When SENSE provisions a VLAN on SONiC, the collection configures the SONiC device to create:

- A VLAN interface (`Vlan3617`) with the specified MTU and IPv6/IPv4 address
- VRF binding: the VLAN interface is attached to the specified VRF
- Trunk port membership: the physical port or port-channel is added to the VLAN's tagged member list
- A description identifying the SENSE service connection

The equivalent SONiC CLI commands would be:

```bash
config vlan add 3617
config vlan member add -u 3617 PortChannel102
config interface ip add Vlan3617 fc00:0:0:0:0:0:0:59/124
config interface vrf bind Vlan3617 lhcone
```

### Example: Delete VLAN

```bash
config interface vrf unbind Vlan3617
config interface ip remove Vlan3617 fc00:0:0:0:0:0:0:59/124
config vlan member del 3617 PortChannel102
config vlan del 3617
```

---

## BGP Configuration

Azure SONiC BGP is managed through FRRouting (FRR) which is embedded in SONiC. The `sense.sonic` collection configures BGP by interfacing with the SONiC management framework, which translates to FRR/vtysh configuration internally.

### Example: BGP (ASN 64513, VRF `lhcone`)

The SENSE provisioning creates:
- IPv6 prefix lists for inbound and outbound route filtering
- Route maps binding the prefix lists
- BGP neighbor configuration with VRF-scoped address-family

The equivalent FRR/vtysh commands running inside SONiC would be:

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
router bgp 64513 vrf lhcone
 address-family ipv6 unicast
  network 2605:d9c0:2:fff1::/64
  neighbor fc00:0:0:0:0:0:0:5a remote-as 64512
  neighbor fc00:0:0:0:0:0:0:5a activate
  neighbor fc00:0:0:0:0:0:0:5a route-map sense-abc123-mapin in
  neighbor fc00:0:0:0:0:0:0:5a route-map sense-abc123-mapout out
```

---

## Ping and Traceroute

SENSE can issue active probes from Azure SONiC devices (requires IP assigned to a SENSE VLAN interface).

### Ping

```bash
# IPv6
ping6 -c 10 -W 5 fc00:0:0:0:0:0:0:5a

# IPv4
ping -c 10 -W 5 10.0.0.1
```

**Note:** Azure SONiC uses Linux-style ping (`ping6` for IPv6, `ping` for IPv4) with `-c` (count) and `-W` (timeout in seconds) flags. VRF-aware ping is done by specifying the source interface or VRF namespace.

### Traceroute

```bash
# IPv6
traceroute6 fc00:0:0:0:0:0:0:5a

# IPv4
traceroute 10.0.0.1
```

---

## Switch Configuration in `main.yaml`

```yaml
sonic_s0:
  rsts_enabled: ipv4,ipv6    # Enable BGP control
  private_asn: 64513          # Private ASN assigned by SENSE team
  vrf: lhcone                 # VRF name for SENSE traffic
  vlan_mtu: 9000
  vlan_range:
    - 3600-3699
  allports: false
  ports:
    PortChannel102:
      capacity: 100000         # Port capacity in Mbps
    Ethernet0:
      capacity: 100000
      isAlias: urn:ogf:network:remote-site.net:2024:switch_s0:port_xyz
      wanlink: true
```

---

## Known Limitations and Notes

- **No QoS**: Azure SONiC does not support SENSE network-level QoS rate limiting. Traffic shaping must be configured independently using SONiC QoS profiles.
- **BGP Multipath**: Supported. Multiple VLAN + BGP peer pairs can share the same port with independent routing paths.
- **SONiC version**: The sense-sonic-collection has been tested against Azure SONiC versions used at research and HPC sites. Behavior may vary between SONiC builds.
- **FRR inside SONiC**: BGP runs via the embedded FRR process. Ensure FRR BGP is enabled in the SONiC configuration before deploying SENSE BGP control.
- **LLDP**: Required on trunk ports for automatic topology discovery. Without LLDP, all inter-switch links must be manually defined via `isAlias`.

---

## Useful Links

- [sense-sonic-collection GitHub](https://github.com/sdn-sense/sense-sonic-collection)
- [Azure SONiC GitHub](https://github.com/sonic-net/sonic-buildimage)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
