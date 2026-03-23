---
title: "FreeRTR"
layout: single
classes: wide
permalink: "/devices/freertr/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**FreeRTR** is an open-source router implementation written in Java. SiteRM supports FreeRTR devices for topology visualization using the `sense.freertr` Ansible collection. FreeRTR integration is currently in early stages — only facts collection (topology visualization in MRML) is supported at this time.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.freertr.freertr` |
| **Ansible Collection** | [sense-freertr-collection](https://github.com/sdn-sense/sense-freertr-collection) |
| **VLAN Creation** | No |
| **BGP Control** | No |
| **BGP Multipath** | No |
| **QoS (network-level)** | No |
| **Ping / Traceroute** | No |
| **Viz in MRML** | Yes |

---

## Ansible Inventory Configuration

```yaml
inventory:
  freertr_s0:
    network_os: sense.freertr.freertr
    host: 192.168.1.10
    user: admin
    pass: <password>            # or use sshkey
    # sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
```

---

## Facts Collection

SiteRM executes the following commands to collect topology and interface information from FreeRTR devices:

```bash
show platform
show running-config
show interfaces
show ipv4 interface
show ipv6 interface
show lldp neighbor
show vrf routing
```

For per-VRF routing information (one command per discovered VRF):

```bash
show ipv4 route <vrf_name>
show ipv6 route <vrf_name>
```

For per-interface LLDP detail (one command per interface with LLDP neighbors):

```bash
show lldp detail <interface_name>
```

**Information extracted:**
- Platform version, hardware ID, hostname (`show platform`)
- Full running configuration (`show running-config`)
- Interface status, descriptions, MAC addresses, MTU, bandwidth (`show interfaces`)
- IPv4 and IPv6 addresses per interface (`show ipv4 interface`, `show ipv6 interface`)
- LLDP neighbors with remote hostname, port, chassis ID — used for topology stitching
- VRF routing tables with IPv4 and IPv6 routes per VRF

---

## Current Status and Roadmap

FreeRTR support in SENSE is at the **visualization-only** stage:

- **Supported**: Facts collection and topology representation in MRML model
- **Not yet supported**: VLAN provisioning, BGP control, QoS, active probes (ping/traceroute)

Full control-plane integration (VLAN creation, BGP) is planned for a future release. If your site requires FreeRTR control, contact the SENSE team.

---

## Switch Configuration in `main.yaml`

```yaml
freertr_s0:
  vlan_range:
    - 3600-3699
  allports: false
  ports:
    eth0:
      capacity: 100000         # Port capacity in Mbps
    eth1:
      capacity: 100000
      isAlias: urn:ogf:network:remote-site.net:2024:freertr_s0:port_xyz
      wanlink: true
```

**Note:** `rsts_enabled` and `private_asn` are not configured for FreeRTR since BGP control is not yet supported.

---

## Known Limitations and Notes

- **Viz only**: FreeRTR is only used for topology discovery (MRML visualization). No provisioning operations are performed on FreeRTR devices by SENSE.
- **LLDP required**: LLDP must be enabled on FreeRTR interfaces for automatic topology stitching with adjacent devices.
- **Per-VRF commands**: The facts collector dynamically discovers VRFs and issues routing commands per VRF. Large numbers of VRFs will result in more SSH commands per collection cycle.

---

## Useful Links

- [sense-freertr-collection GitHub](https://github.com/sdn-sense/sense-freertr-collection)
- [FreeRTR Project](http://www.freertr.org/)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
