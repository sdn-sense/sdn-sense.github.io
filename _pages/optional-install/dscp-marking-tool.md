---
title: "DSCP Marking"
layout: single
classes: wide
permalink: "/optional-install/dscp-marking/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**DSCP (Differentiated Services Code Point)** is a 6-bit field in the IP header that marks packets so that network equipment (routers, switches) can apply **per-hop quality-of-service** policies. When SENSE creates a path with QoS guarantees, DSCP marking ensures that every device along the network path treats the traffic according to its priority.

SiteRM Agent **automatically applies DSCP marking** on DTN hosts for all active deltas that have a service class. No manual configuration is needed. The Agent's Ruler component converges DSCP rules on every execution cycle, adding rules for newly activated deltas and removing stale rules when deltas are decommissioned.

---

## How It Works

DSCP marking is driven by the **service class** (`hasService.type`) of each active delta. The SiteRM Agent uses two mechanisms depending on the path type:

### L2 Paths (VLAN interfaces)

For L2 connections (`vsw` and `kube` delta types), the Agent uses Linux **`tc` (traffic control)** to rewrite the DSCP field on all egress traffic on the VLAN interface:

1. A root `prio` qdisc is added to the VLAN interface (`vlan.<VLAN_ID>`)
2. `u32` catch-all filters with `pedit` actions rewrite the TOS byte (IPv4) or Traffic Class field (IPv6)
3. **All traffic** on the VLAN interface is marked with the DSCP value corresponding to the delta's service class

Example commands the Agent applies automatically for a `guaranteedCapped` delta on `vlan.3600`:

```bash
# Root qdisc
tc qdisc add dev vlan.3600 root handle 1: prio

# IPv4: rewrite TOS byte to 0xb8 (DSCP 46 / EF)
tc filter add dev vlan.3600 parent 1: protocol ip prio 1 \
  u32 match u32 0 0 \
  action pedit munge ip tos set 0xb8 action ok

# IPv6: rewrite Traffic Class across bytes 0-1 of the IPv6 header
tc filter add dev vlan.3600 parent 1: protocol ipv6 prio 11 \
  u32 match u32 0 0 \
  action pedit munge offset 0 u8 set 0x6b \
  action pedit munge offset 1 u8 set 0x80 action ok
```

When a delta is decommissioned, the Agent removes the root qdisc (which removes all attached filters).

### L3 Paths (Routed, IPv6 only)

For L3 routing service (`rst`) deltas, the Agent uses **`ip6tables`** to mark traffic by destination IPv6 prefix:

```bash
# Mark traffic to a specific IPv6 prefix with DSCP 46 (EF)
ip6tables -t mangle -A OUTPUT \
  -d 2605:9a00:10:2010::/64 \
  -m comment --comment "SENSE_guaranteedCapped_DSCP46_<uuid>" \
  -j DSCP --set-dscp 46
```

Key details:
- Rules go in the **mangle** table, **OUTPUT** chain (marks locally-originated traffic)
- Each rule is tagged with a structured comment (`SENSE_<type>_DSCP<value>_<uuid>`) for identification
- Rules are applied idempotently: the Agent checks if a rule already exists before adding
- L3 DSCP marking is **IPv6 only**
- If `ip6tables` is not installed on the host, L3 DSCP marking is skipped

---

## DSCP Values

The following DSCP values are applied automatically based on the delta's service class:

| Service Class | DSCP Value | DSCP Name | IPv4 TOS Byte | Description |
|---|---|---|---|---|
| `guaranteedCapped` | 46 | EF (Expedited Forwarding) | `0xB8` | Highest priority, minimum latency |
| `softCapped` | 18 | AF21 (Assured Forwarding 21) | `0x48` | Priority delivery with burst allowance |
| `bestEffort` | 0 | BE (Best Effort) | `0x00` | Default, no QoS guarantees |

The TOS byte is the DSCP value left-shifted by 2 bits (DSCP occupies the upper 6 bits of the TOS/Traffic Class byte). For example, DSCP 46 = `0x2E`, shifted left by 2 = `0xB8`.

If a delta does not specify a service class, it defaults to `bestEffort` (DSCP 0), which is functionally a no-op since DSCP 0 is the default for unmarked traffic.

**Reference:** [IETF RFC 2474](https://datatracker.ietf.org/doc/html/rfc2474) defines the DSCP field; [RFC 3246](https://datatracker.ietf.org/doc/html/rfc3246) defines EF behavior.

---

## Prerequisites

DSCP marking runs automatically as part of the SiteRM Agent Ruler. The only prerequisites are:

- **SiteRM Agent** installed and running on the DTN host
- **Root access** (required for `tc` and `ip6tables` commands)
- **`ip6tables`** installed if you need L3 (routed IPv6) DSCP marking; L2 marking works without it

There is no separate toggle to enable or disable DSCP marking. It runs whenever the Agent's rule enforcement is active (`norules` is not set to `True` in the agent configuration).

---

## Verifying DSCP Marking

### Check active `tc` rules (L2)

```bash
# Show qdisc on a VLAN interface
tc qdisc show dev vlan.3600

# Show filters
tc filter show dev vlan.3600 parent 1:
```

### Check active `ip6tables` rules (L3)

```bash
# List all SENSE DSCP rules in the mangle table
ip6tables -t mangle -L OUTPUT -n --line-numbers | grep SENSE
```

### Verify with `tcpdump`

```bash
# Capture traffic and display ToS byte (IPv4)
tcpdump -i vlan.3600 -v -c 20 | grep -i "tos"
# Expected for EF (DSCP 46): tos 0xb8

# Capture IPv6 traffic and display Traffic Class
tcpdump -i vlan.3600 -v ip6 -c 20 | grep "class"
# Expected for EF (DSCP 46): class 0xb8
```

---

## Firewall Considerations

- Ensure your site firewall does **not** reclassify or zero out the DSCP field on packets leaving the site.
- Most WAN/campus networks operate on a **trust boundary** policy -- verify with your network team whether DSCP marks from DTN hosts are honored upstream.
- ESnet and Internet2 typically accept and honor DSCP markings from participating sites for science traffic.

---

## Related Topics

- [Quality of Service (QoS)](/operational/quality-of-service/) -- SiteRM host-level QoS
- [Agent Configuration](/customization/configuration-agent/) -- Interface and QoS configuration for the SiteRM Agent
