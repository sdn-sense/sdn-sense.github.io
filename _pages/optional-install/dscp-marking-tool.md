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

**DSCP (Differentiated Services Code Point)** is a 6-bit field in the IP header that marks packets so that network equipment (routers, switches) can apply **per-hop quality-of-service** policies. When SENSE creates a path with QoS guarantees, DSCP marking ensures that every device along the network path treats the traffic according to its priority — not just the endpoints.

SiteRM enforces QoS at the DTN host level using [FireHol FireQOS](/operational/quality-of-service/). DSCP marking is an **optional complementary step** that marks packets with appropriate DSCP values so that the broader network infrastructure (WAN routers, campus switches) can also enforce differentiated service.

**When to configure DSCP marking:**
- Your WAN or campus network honors DSCP markings for QoS enforcement
- You need end-to-end QoS, not just host-level shaping
- Your site policy requires DSCP-based traffic classification for research network paths

---

## DSCP Values Used by SENSE

SENSE recommends the following DSCP mappings aligned with IETF and research network conventions:

| SENSE Path Type | DSCP Value | DSCP Class | Description |
|---|---|---|---|
| HardQoS (guaranteed bandwidth) | 46 (`EF`) | Expedited Forwarding | Highest priority, minimum latency |
| SoftQoS (burstable guaranteed) | 26 (`AF31`) | Assured Forwarding | Priority delivery, allows burst |
| BestEffort | 0 (`BE`) | Default (Best Effort) | Standard traffic, no guarantees |
| Science network (ESnet standard) | 8 (`CS1`) | Class Selector 1 | Some networks use for bulk science data |

**Reference:** [IETF RFC 2474](https://datatracker.ietf.org/doc/html/rfc2474) defines the DSCP field; [RFC 3246](https://datatracker.ietf.org/doc/html/rfc3246) defines EF behavior class.

---

## Prerequisites

- Linux host running SiteRM Agent (DTN node)
- Root access (required for `iptables`/`ip6tables` and `tc` commands)
- `iptables` and `ip6tables` packages installed
- The VLAN interfaces for SENSE-controlled paths must already exist (created by SiteRM Agent)

---

## Approach 1 — DSCP Marking with `iptables` / `ip6tables`

This is the simplest approach. Use `iptables` to mark traffic on SENSE VLAN interfaces as it leaves the host.

### Mark all traffic on a SENSE VLAN interface with EF (DSCP 46):

```bash
# IPv4 — mark outgoing traffic on VLAN interface as Expedited Forwarding (DSCP 46)
iptables -t mangle -A OUTPUT -o vlan.3600 -j DSCP --set-dscp 46

# IPv6 — same rule for IPv6 traffic
ip6tables -t mangle -A OUTPUT -o vlan.3600 -j DSCP --set-dscp 46

# IPv4 — mark incoming traffic (PREROUTING) — useful if you want to remark ingress
iptables -t mangle -A PREROUTING -i vlan.3600 -j DSCP --set-dscp 46
ip6tables -t mangle -A PREROUTING -i vlan.3600 -j DSCP --set-dscp 46
```

**Replace `vlan.3600`** with the actual VLAN interface name SiteRM creates on your system (e.g., `bond0.3600`, `enp1s0.3600`).

### Mark traffic by destination IP range:

```bash
# Mark traffic destined for a specific SENSE-controlled subnet as AF31 (DSCP 26)
ip6tables -t mangle -A OUTPUT \
  -d 2001:48d0:3001:110::/64 \
  -j DSCP --set-dscp 26

# IPv4 equivalent
iptables -t mangle -A OUTPUT \
  -d 192.168.100.0/24 \
  -j DSCP --set-dscp 26
```

### Make rules persistent across reboots:

**EL8/EL9/EL10 (RHEL-based):**
```bash
dnf install -y iptables-services
service iptables save
service ip6tables save
systemctl enable iptables ip6tables
```

**Ubuntu 22:**
```bash
apt-get install -y iptables-persistent
netfilter-persistent save
```

---

## Approach 2 — DSCP Marking with Linux `tc` (Traffic Control)

`tc` with the `dsfield` action allows DSCP marking to be done at the traffic-control layer, which is particularly useful when you also have FireQOS/HTB queuing in place.

### Add DSCP remark rule to FireQOS HTB

If SiteRM's QoS is already managing a VLAN interface with FireQOS, you can add DSCP marking inside the FireQOS configuration:

```bash
# Example FireQOS interface configuration
# (/etc/firehol/fireqos.conf or inline in FireHol rules)

interface4 vlan.3600 sense_vlan3600 rate 1Gbps max 10Gbps
  class default rate 1Gbps max 1Gbps
    match all dscp 46    # remark to EF
```

For `tc` directly (no FireQOS):

```bash
# Add a u32 filter to remark DSCP on egress
tc qdisc add dev vlan.3600 root handle 1: htb default 10
tc class add dev vlan.3600 parent 1: classid 1:10 htb rate 10gbit

# Add DSCP remark action
tc filter add dev vlan.3600 parent 1: \
  protocol ip u32 match ip dst 0.0.0.0/0 \
  action pedit ex munge ip dsfield set 0xb8 pipe \
  action mirred egress redirect dev vlan.3600
```

**Note:** `0xb8` is the DSCP EF value (46) shifted left by 2 bits into the DS field byte position.

---

## Approach 3 — Automated Marking via SiteRM Agent (Recommended)

The cleanest integration is to configure DSCP marking rules that are automatically applied when SiteRM Agent activates a VLAN interface. You can achieve this by adding a post-up script to the interface configuration or by using a udev rule.

### Using a systemd service that watches for VLAN interface creation:

```bash
# Create /usr/local/sbin/sense-dscp-mark.sh
#!/bin/bash
INTF=$1
DSCP=$2

# Apply DSCP marking on newly created SENSE VLAN interface
ip6tables -t mangle -A OUTPUT -o "$INTF" -j DSCP --set-dscp "$DSCP"
ip6tables -t mangle -A PREROUTING -i "$INTF" -j DSCP --set-dscp "$DSCP"
iptables -t mangle -A OUTPUT -o "$INTF" -j DSCP --set-dscp "$DSCP"
iptables -t mangle -A PREROUTING -i "$INTF" -j DSCP --set-dscp "$DSCP"

echo "DSCP $DSCP marking applied to interface $INTF"
```

```bash
chmod +x /usr/local/sbin/sense-dscp-mark.sh

# Call it from a udev rule when a VLAN interface comes up
# /etc/udev/rules.d/80-sense-dscp.rules
ACTION=="add", SUBSYSTEM=="net", KERNEL=="*.3[0-9][0-9][0-9]", \
  RUN+="/usr/local/sbin/sense-dscp-mark.sh %k 46"
```

---

## Verifying DSCP Marking

Use `tcpdump` to confirm DSCP bits are being set correctly:

```bash
# Capture traffic on the VLAN interface and display ToS byte
tcpdump -i vlan.3600 -v -c 20 | grep -i "tos"

# Expected output for EF (DSCP 46):
# IP ... tos 0xb8 (DSCP EF, ECN 0)
```

Verify IPv6 traffic class:
```bash
tcpdump -i vlan.3600 -v ip6 -c 20 | grep "class"
# class 0xb8 means DSCP EF on IPv6
```

---

## DSCP and Firewall Considerations

- Ensure your site firewall does **not** reclassify or zero out the DSCP field on packets leaving the site.
- Most WAN/campus networks operate on a **trust boundary** policy — verify with your network team whether DSCP marks from DTN hosts are honored upstream.
- ESnet and Internet2 typically accept and honor DSCP markings from participating sites for science traffic.

---

## Summary

| Approach | Best For | Pros | Cons |
|---|---|---|---|
| `iptables`/`ip6tables` | Simple per-interface marking | Easy, persistent | Must manage rules manually per VLAN |
| `tc` with u32 filters | Integration with existing QoS | Precise per-flow control | More complex; requires tc expertise |
| udev + script | Automated marking on VLAN creation | Automatic for all SENSE VLANs | Requires udev configuration |

For most sites, **Approach 1** (iptables) applied to each SENSE VLAN interface provides a straightforward and maintainable solution.

---

## Related Topics

- [Quality of Service (QoS)](/operational/quality-of-service/) — SiteRM host-level QoS using FireQOS
- [Agent Configuration](/customization/configuration-agent/) — Interface and QoS configuration for the SiteRM Agent
