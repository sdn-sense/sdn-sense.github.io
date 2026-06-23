---
title: "Juniper Junos"
layout: single
classes: wide
permalink: "/devices/juniper-junos/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**Juniper Junos** is the network operating system for Juniper Networks switches and routers. SiteRM controls these devices using the `sense.junos` Ansible collection. Juniper Junos supports VLAN creation, BGP control, and BGP multipath through SENSE. Two VLAN rendering paths are supported, selected with `ansparams.vlanmode`: **standard mode** (EX/QFX switches, the default) and **MX / PTX virtual-switch mode** for Juniper MX and PTX routers.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.junos.junos` |
| **Ansible Collection** | [sense-junos-collection](https://github.com/sdn-sense/sense-junos-collection) |
| **VLAN Creation** | Yes |
| **BGP Control** | Yes |
| **BGP Multipath** | Yes |
| **QoS (network-level)** | No |
| **Ping / Traceroute** | Yes |

---

## Ansible Inventory Configuration

```yaml
inventory:
  junos_s0:
    network_os: sense.junos.junos
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

**Additional Junos parameters (`ansparams`):** Junos behavior is tuned per-device through three optional `ansparams` fields, sourced from the site `ansible_params:` configuration:

| Field | Values | Default | Purpose |
|---|---|---|---|
| `vlanip` | `vlan` or `irb` | `vlan` | Standard mode only. Selects whether the L3 VLAN interface is a `vlan` unit or an `irb` unit (platform-dependent). |
| `vlanmode` | `standard`, `mx`, `ptx` | `standard` | Selects the rendering path. `mx` and `ptx` use a routing-instance `virtual-switch` (see [MX / PTX Virtual-Switch Mode](#mx--ptx-virtual-switch-mode)). |
| `routing_instance` | any name | `SENSE-Vlans` | **Optional.** Name of the `virtual-switch` routing-instance. Only consulted when `vlanmode` is `mx` or `ptx`. If omitted, defaults to `SENSE-Vlans`. |

```yaml
# In site main.yaml switch config:
junos_s0:
  ansparams:
    vlanip: vlan            # standard mode: 'vlan' or 'irb' depending on platform
    vlanmode: standard      # 'standard' (default), 'mx', or 'ptx'
    # routing_instance: SENSE-Vlans   # optional; mx/ptx only, defaults to SENSE-Vlans
```

---

## Facts Collection

SiteRM executes the following commands to collect topology and interface information from Juniper Junos devices (output is in JSON/XML format):

```bash
show version | display json
show ethernet-switching table detail | display json
show interfaces | display json
show vlans detail | display json
show lldp neighbors | display json
show interfaces ae* | display json
```

For routing facts:

```bash
show route all | display xml
```

**VLAN listing depends on `vlanmode`:** the `show vlans detail` command above is used in `standard` mode. In `mx`/`ptx` mode the VLAN-listing command is scoped to the routing-instance (`routing_instance`, default `SENSE-Vlans`):

| `vlanmode` | VLAN-listing command |
|---|---|
| `standard` (default) | `show vlans detail | display json` |
| `mx` | `show bridge-domain instance <routing_instance> detail | display json` |
| `ptx` | `show vlans instance <routing_instance> detail | display json` |

All other facts commands (version, ethernet-switching table, interfaces, LLDP, AE interfaces, routes) are identical across modes.

**Information extracted:**
- System version, hardware platform, serial number
- Interface details: description, MAC, MTU, operational status, IPv4/IPv6 addresses, VRF assignments
- VLAN membership and ethernet switching tables
- Aggregated Ethernet (AE/LAG) interface details
- LLDP neighbors: remote hostname, port, chassis ID — used for topology stitching
- Full routing table (all VRFs)

---

## VLAN Creation and Deletion (Standard Mode)

Juniper Junos uses a **set-style** configuration syntax (not the line-by-line CLI of other platforms). All commands are `set` or `delete` statements.

This section covers **standard mode** (`vlanmode: standard`, the default), used on EX/QFX/SRX/ELS platforms. For MX and PTX routers that drive VLANs through a `virtual-switch` routing-instance, see [MX / PTX Virtual-Switch Mode](#mx--ptx-virtual-switch-mode) below.

### L3 Interface Mode: `vlan` vs `irb`

Juniper devices use either a `vlan` logical unit or an `irb` (Integrated Routing and Bridging) unit for L3 VLAN interfaces, depending on the platform:
- **EX series switches**: Typically use `vlan` units
- **QFX series switches**: Typically use `irb` units

The mode is configured in `main.yaml` under `ansparams.vlanip`.

### Create VLAN (example: VLAN 3607, VRF `lhcone`, port `et-0/0/11`)

**Using `vlan` mode:**

```bash
set vlans Vlan_3607 vlan-id 3607
set vlans Vlan_3607 description "urn:ogf:network:service+858b5c37...:vt+l2-policy::Connection_1"
set interfaces et-0/0/11 unit 0 family ethernet-switching vlan members Vlan_3607
set interfaces vlan unit 3607 family inet6 address fc00:0:0:0:0:0:0:16/124
set vlans Vlan_3607 vlan-id 3607 l3-interface vlan.3607
```

**Using `irb` mode:**

```bash
set vlans Vlan_3607 vlan-id 3607
set vlans Vlan_3607 description "urn:ogf:network:service+858b5c37...:vt+l2-policy::Connection_1"
set interfaces et-0/0/11 unit 0 family ethernet-switching vlan members Vlan_3607
set interfaces irb unit 3607 family inet6 address fc00:0:0:0:0:0:0:16/124
set vlans Vlan_3607 l3-interface irb.3607
```

### Delete VLAN

**Using `vlan` mode:**

```bash
delete vlans Vlan_3607
delete interfaces et-0/0/11 unit 0 family ethernet-switching vlan members Vlan_3607
delete interfaces vlan unit 3607 family inet6 address fc00:0:0:0:0:0:0:16/124
```

**Using `irb` mode:**

```bash
delete vlans Vlan_3607
delete interfaces et-0/0/11 unit 0 family ethernet-switching vlan members Vlan_3607
delete interfaces irb unit 3607 family inet6 address fc00:0:0:0:0:0:0:16/124
delete interfaces irb unit 3607
```

---

## MX / PTX Virtual-Switch Mode

Juniper **MX** and **PTX** routers do not use the `family ethernet-switching` VLAN model of the EX/QFX switches. Instead, SiteRM places SENSE VLANs inside a dedicated `virtual-switch` **routing-instance** and bridges tagged sub-units into it. This path is selected per-device with `ansparams.vlanmode`:

| `vlanmode` | Platform | Routing-instance keyword |
|---|---|---|
| `mx` | Juniper MX (vJunos-router) | `bridge-domains` |
| `ptx` | Juniper PTX / Evolved (vJunosEvolved) | `vlans` |

The two modes are structurally identical; only the keyword inside the routing-instance differs (`bridge-domains` for MX, `vlans` for PTX).

### Routing-Instance Name (`routing_instance`)

The name of the `virtual-switch` routing-instance is set with `ansparams.routing_instance`. **This field is optional — when omitted it defaults to `SENSE-Vlans`.** Set it explicitly only if the site uses a different routing-instance name.

```yaml
junos_s0:
  ansparams:
    vlanmode: mx                      # or 'ptx'
    # routing_instance: SENSE-Vlans   # optional; defaults to SENSE-Vlans when omitted
```

### Naming Convention

In MX/PTX mode, the VLAN object name follows the **`VLAN-<id>`** format (uppercase, hyphen) — for example `VLAN-1323` — rather than the `Vlan<id>` / `Vlan_<id>` form used in standard mode.

### Create VLAN — MX (example: `VLAN-1323`, members `ae14` and `ae4`)

```bash
set routing-instances SENSE-Vlans instance-type virtual-switch
set routing-instances SENSE-Vlans bridge-domains VLAN-1323 description "SC25 NENG-1985 VLAN 1323"
set routing-instances SENSE-Vlans bridge-domains VLAN-1323 vlan-id 1323
set routing-instances SENSE-Vlans bridge-domains VLAN-1323 interface ae14.1323
set interfaces ae14 unit 1323 encapsulation vlan-bridge
set interfaces ae14 unit 1323 vlan-id 1323
set routing-instances SENSE-Vlans bridge-domains VLAN-1323 interface ae4.1323
set interfaces ae4 unit 1323 encapsulation vlan-bridge
set interfaces ae4 unit 1323 vlan-id 1323
```

### Create VLAN — PTX (example: `VLAN-1326`, members `ae2` and `et-0/0/1`)

```bash
set routing-instances SENSE-Vlans instance-type virtual-switch
set routing-instances SENSE-Vlans vlans VLAN-1326 description "SC25 NENG-1985 VLAN 1326"
set routing-instances SENSE-Vlans vlans VLAN-1326 vlan-id 1326
set routing-instances SENSE-Vlans vlans VLAN-1326 interface ae2.1326
set interfaces ae2 unit 1326 encapsulation vlan-bridge
set interfaces ae2 unit 1326 vlan-id 1326
set routing-instances SENSE-Vlans vlans VLAN-1326 interface et-0/0/1.1326
set interfaces et-0/0/1 unit 1326 encapsulation vlan-bridge
set interfaces et-0/0/1 unit 1326 vlan-id 1326
```

Each member port gets a logical sub-unit numbered with the VLAN id (`<port>.<vlanid>`), configured with `encapsulation vlan-bridge` and a matching `vlan-id`, then bound into the routing-instance.

### Delete VLAN — MX

```bash
delete interfaces ae14 unit 1323
delete interfaces ae4 unit 1323
delete routing-instances SENSE-Vlans bridge-domains VLAN-1323
```

### Delete VLAN — PTX

```bash
delete interfaces ae2 unit 1326
delete interfaces et-0/0/1 unit 1326
delete routing-instances SENSE-Vlans vlans VLAN-1326
```

On teardown only the bridge-domain/vlan object and its member sub-units are removed; the parent routing-instance itself is **never** deleted. The `set routing-instances <ri> instance-type virtual-switch` line is emitted on every push (it is idempotent in Junos) so the routing-instance always exists before VLAN objects reference it.

### Custom Routing-Instance Name

When `routing_instance` is set explicitly, that name replaces `SENSE-Vlans` everywhere in the output:

```bash
# ansparams: { vlanmode: mx, routing_instance: CustomRI }
set routing-instances CustomRI instance-type virtual-switch
set routing-instances CustomRI bridge-domains VLAN-100 description "..."
set routing-instances CustomRI bridge-domains VLAN-100 vlan-id 100
set routing-instances CustomRI bridge-domains VLAN-100 interface ae0.100
set interfaces ae0 unit 100 encapsulation vlan-bridge
set interfaces ae0 unit 100 vlan-id 100
```

### Limitations in MX/PTX Mode

- **No L3 / IRB termination**: MX/PTX mode renders L2 bridging only. The `vlan`/`irb` L3 interface logic (and `ansparams.vlanip`) applies to standard mode only.
- **No QoS**: SENSE QoS rate-limiting uses `family ethernet-switching` filters, which are standard-mode only. The QoS block is skipped entirely when `vlanmode` is `mx` or `ptx`.

---

## BGP Configuration

Juniper Junos BGP configuration is also expressed in `set` style. SENSE uses a named BGP group (`SENSE-BGP-<groupName>`) to manage all SENSE BGP peers.

### Create BGP (example: ASN 64513, VRF `lhcone`, group `DEFAULT`)

```bash
# Prefix lists
set policy-options prefix-list sense-abc123-from 2001:48d0:3001:110::/64
set policy-options prefix-list sense-abc123-to 2605:d9c0:2:fff1::/64

# Policy statements (route-maps)
set policy-options policy-statement sense-abc123-mapin term 10 from prefix-list sense-abc123-from
set policy-options policy-statement sense-abc123-mapin term 10 then accept
set policy-options policy-statement sense-abc123-mapin term 11 then reject

set policy-options policy-statement sense-abc123-mapout term 10 from prefix-list sense-abc123-to
set policy-options policy-statement sense-abc123-mapout term 10 then accept
set policy-options policy-statement sense-abc123-mapout term 11 then reject

# BGP group
set protocols bgp group SENSE-BGP-DEFAULT type external
set protocols bgp group SENSE-BGP-DEFAULT local-as 64513
set protocols bgp group SENSE-BGP-DEFAULT family inet6 unicast

# BGP neighbor
set protocols bgp group SENSE-BGP-DEFAULT neighbor fc00:0:0:0:0:0:0:17 peer-as 65000
set protocols bgp group SENSE-BGP-DEFAULT neighbor fc00:0:0:0:0:0:0:17 import sense-abc123-mapin
set protocols bgp group SENSE-BGP-DEFAULT neighbor fc00:0:0:0:0:0:0:17 export sense-abc123-mapout
```

### Delete BGP

```bash
delete protocols bgp group SENSE-BGP-DEFAULT neighbor fc00:0:0:0:0:0:0:17 peer-as 65000
delete protocols bgp group SENSE-BGP-DEFAULT neighbor fc00:0:0:0:0:0:0:17
delete policy-options policy-statement sense-abc123-mapin
delete policy-options policy-statement sense-abc123-mapout
delete policy-options prefix-list sense-abc123-from 2001:48d0:3001:110::/64
delete policy-options prefix-list sense-abc123-to 2605:d9c0:2:fff1::/64
```

---

## Ping and Traceroute

SENSE can issue active probes from Juniper Junos devices (requires IP assigned to a SENSE VLAN interface).

### Ping

```bash
# IPv6
ping inet6 fc00:0:0:0:0:0:0:17 count 10 wait 5

# IPv4
ping inet 10.0.0.1 count 10 wait 5
```

**Note:** Juniper uses `inet6`/`inet` keywords and `count`/`wait` (not `-c`/`-i` flags). VRF is not part of the ping command syntax in Junos — source routing is handled via routing-instance configuration.

### Traceroute

```bash
# IPv6
traceroute inet6 fc00:0:0:0:0:0:0:17

# IPv4
traceroute inet 10.0.0.1
```

---

## Switch Configuration in `main.yaml`

```yaml
junos_s0:
  rsts_enabled: ipv4,ipv6    # Enable BGP control
  private_asn: 64513          # Private ASN assigned by SENSE team
  vrf: lhcone                 # VRF name for SENSE traffic
  vlan_mtu: 9000
  ansparams:
    vlanip: vlan              # standard mode: 'vlan' for EX series, 'irb' for QFX series
    vlanmode: standard        # 'standard' (default), 'mx', or 'ptx'
    # routing_instance: SENSE-Vlans   # optional; mx/ptx only, defaults to SENSE-Vlans
  vlan_range:
    - 3600-3699
  allports: false
  ports:
    et-0/0/11:
      capacity: 100000         # Port capacity in Mbps
    ae0:
      capacity: 400000
      isAlias: urn:ogf:network:remote-site.net:2024:switch_s0:port_xyz
      wanlink: true
```

---

## Known Limitations and Notes

- **`vlan` vs `irb` mode**: The L3 interface type must match the platform. EX series uses `vlan` units; QFX series uses `irb` units. Misconfiguration will result in the interface being created without L3 connectivity. Configure `ansparams.vlanip` in `main.yaml` accordingly.
- **`vlanmode` (standard vs mx/ptx)**: Defaults to `standard`. Set `mx` or `ptx` for MX/PTX routers that drive VLANs through a `virtual-switch` routing-instance — see [MX / PTX Virtual-Switch Mode](#mx--ptx-virtual-switch-mode). The `routing_instance` name is optional and defaults to `SENSE-Vlans`.
- **BGP group name**: All SENSE BGP peers on a device share the same BGP group (`SENSE-BGP-DEFAULT` by default). The group name can be customized via the `groupName` parameter if needed.
- **No QoS**: Juniper Junos does not support SENSE QoS rate limiting. Traffic shaping must be configured independently. In `mx`/`ptx` mode the QoS block is skipped entirely.
- **Commit required**: Junos uses a commit-based configuration model. The Ansible collection handles the commit automatically after applying configuration.
- **LLDP**: Required on trunk ports for automatic topology discovery. Without LLDP, all inter-switch links must be manually defined via `isAlias`.

---

## Useful Links

- [sense-junos-collection GitHub](https://github.com/sdn-sense/sense-junos-collection)
- [Juniper Junos CLI Reference](https://www.juniper.net/documentation/us/en/software/junos/cli-reference/)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
