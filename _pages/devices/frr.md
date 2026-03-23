---
title: "FRRouting (FRR)"
layout: single
classes: wide
permalink: "/devices/frr/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

**FRRouting (FRR)** is an open-source IP routing protocol suite for Linux systems. SiteRM controls FRR-based software routers using the `sense.frr` Ansible collection. This collection is also used to manage FRR when combined with VPP (DPDK-accelerated data plane) for high-performance software routing.

| Property | Value |
|---|---|
| **Ansible `network_os`** | `sense.frr.frr` |
| **Ansible Collection** | [sense-frr-collection](https://github.com/sdn-sense/sense-frr-collection) |
| **VLAN Creation** | Yes |
| **BGP Control** | Yes |
| **BGP Multipath** | Yes |
| **QoS (network-level)** | No |
| **Ping / Traceroute** | Yes |

**Note:** When used with VPP (DPDK), the same `sense.frr.frr` collection is used. The FRR instance runs alongside VPP and handles control-plane routing while VPP handles the high-performance data plane. See the [FRR + VPP DPDK guide](/optional-install/software-based-router-dpdk/) for hardware setup.

---

## Ansible Inventory Configuration

```yaml
inventory:
  frr_s0:
    network_os: sense.frr.frr
    host: 192.168.1.10
    user: admin
    pass: <password>            # or use sshkey
    # sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: true                # FRR requires root or sudo access
    ssh_common_args: "-o StrictHostKeyChecking=no"
```

**Note:** FRR devices typically do not use SNMP for monitoring. The `snmp_params` block can be omitted.

---

## Facts Collection

SiteRM collects topology and interface information from FRR-based systems using standard Linux networking commands (executed via SSH):

```bash
ip addr
ip r
ip -6 r
ip neigh
```

Additionally, interface information is gathered from the Linux kernel filesystem:

```
/sys/class/net/<interface>/operstate
/sys/class/net/<interface>/mtu
/sys/class/net/<interface>/speed
/sys/class/net/<interface>/address
```

**Information extracted:**
- IPv4 and IPv6 addresses with subnet masks
- IPv4 and IPv6 routing tables (all routes)
- ARP/NDP neighbor table with MAC address mapping by VLAN
- Interface operational status (`up`/`down`)
- MTU, TX queue length, link speed
- MAC addresses
- VLAN interface configuration (sub-interfaces and bridges)

---

## VLAN Creation and Deletion

FRR-based systems use Linux VLAN sub-interfaces or bridge/VLAN interfaces. The `sense.frr` collection configures the Linux networking stack directly via commands or by interacting with the FRR management daemon.

### Example: VLAN 3617, VRF `lhcone`, physical interface `eth0`

Creating a VLAN sub-interface and associated VRF binding:

```bash
# Create VLAN interface
ip link add link eth0 name eth0.3617 type vlan id 3617
ip link set eth0.3617 mtu 9000

# Assign to VRF
ip link set eth0.3617 master lhcone

# Assign IPv6 address
ip -6 addr add fc00:0:0:0:0:0:0:59/124 dev eth0.3617

# Bring up
ip link set eth0.3617 up
```

### Delete VLAN

```bash
ip link set eth0.3617 down
ip link del eth0.3617
```

---

## BGP Configuration

FRR BGP is configured through FRR's vtysh management shell. The `sense.frr` collection applies configuration by communicating with the FRR daemon.

### Example: BGP (ASN 64513, VRF `lhcone`)

```bash
# Enter vtysh
vtysh

# Configure prefix lists
configure terminal
ipv6 prefix-list sense-abc123-from permit 2001:48d0:3001:110::/64
ipv6 prefix-list sense-abc123-to permit 2605:d9c0:2:fff1::/64

# Configure route maps
route-map sense-abc123-mapin permit 10
 match ipv6 address prefix-list sense-abc123-from
route-map sense-abc123-mapout permit 10
 match ipv6 address prefix-list sense-abc123-to

# Configure BGP
router bgp 64513 vrf lhcone
 address-family ipv6 unicast
  network 2605:d9c0:2:fff1::/64
  neighbor fc00:0:0:0:0:0:0:5a remote-as 64512
  neighbor fc00:0:0:0:0:0:0:5a activate
  neighbor fc00:0:0:0:0:0:0:5a soft-reconfiguration inbound
  neighbor fc00:0:0:0:0:0:0:5a route-map sense-abc123-mapin in
  neighbor fc00:0:0:0:0:0:0:5a route-map sense-abc123-mapout out
end
write memory
```

### Delete BGP

```bash
vtysh
configure terminal

no ipv6 prefix-list sense-abc123-from
no ipv6 prefix-list sense-abc123-to
no route-map sense-abc123-mapin
no route-map sense-abc123-mapout

router bgp 64513 vrf lhcone
 address-family ipv6 unicast
  no network 2605:d9c0:2:fff1::/64
  no neighbor fc00:0:0:0:0:0:0:5a
end
write memory
```

---

## Ping and Traceroute

SENSE can issue active probes from FRR-based systems (requires IP assigned to a SENSE VLAN interface).

### Ping

```bash
# IPv6
ping6 -c 10 -W 5 fc00:0:0:0:0:0:0:5a

# IPv6 with VRF (Linux network namespace)
ip netns exec lhcone ping6 -c 10 -W 5 fc00:0:0:0:0:0:0:5a

# IPv4
ping -c 10 -W 5 10.0.0.1
```

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
frr_s0:
  rsts_enabled: ipv4,ipv6    # Enable BGP control
  private_asn: 64513          # Private ASN assigned by SENSE team
  vrf: lhcone                 # VRF name for SENSE traffic
  vlan_mtu: 9000
  vlan_range:
    - 3600-3699
  allports: false
  ports:
    eth0:
      capacity: 100000         # Port capacity in Mbps
    eth1:
      capacity: 100000
      isAlias: urn:ogf:network:remote-site.net:2024:frr_s0:port_xyz
      wanlink: true
```

---

## Deployment Options

### Docker / Bare-metal

FRR is commonly deployed as a Docker container on a bare-metal host. Refer to the [Software Based Router (FRR) guide](/optional-install/software-based-router/) for Docker Compose deployment instructions.

**Critical requirement:** FRR containers must use `network_mode: host` — bridge networking does not work because FRR needs direct access to the Linux kernel routing table.

### Docker + VPP (DPDK, bare-metal)

For high-throughput deployments (10/40/100 Gbps), FRR can be paired with VPP as a DPDK-accelerated data plane. VPP bypasses the kernel for packet forwarding; FRR handles BGP via Linux mirror interfaces (LCP). See the [FRR + VPP DPDK guide](/optional-install/software-based-router-dpdk/).

### Kubernetes with Multus (VPP+FRR in a pod)

VPP+FRR can be deployed as a Kubernetes **StatefulSet** with physical NICs passed into the pod via [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) and the `host-device` plugin. This is suited for sites managing SENSE infrastructure on Kubernetes.

Two manifest variants are available:

| Variant | NICs | Hugepages | Description |
|---|---|---|---|
| `vpp-frr-router.yaml` | 1 NIC | 1Gi + 2Mi | Single uplink, static IPAM on Multus interface |
| `new-vpp-frr.yaml` | 2 NICs bonded | 2Mi only | Dual uplink with XOR/L3-4 bond for higher throughput |

Both variants:
- Use the `sdnsense/vppfrr:dev` Docker image
- Run VPP with DPDK (privileged pod, `NET_ADMIN`/`SYS_RAWIO`/`IPC_LOCK` capabilities)
- Create Linux mirror interfaces via VPP LCP (`lcp create`) so FRR can use them for BGP
- Expose SSH on port **22334** at the pod's WAN IPv6 address for SENSE Ansible management
- Accept the SiteRM Frontend's SSH public key via a Kubernetes Secret

SENSE connects to the pod using the standard `sense.frr.frr` Ansible collection with the pod's IPv6 address and port 22334 as the management endpoint.

See the [FRR + VPP DPDK guide](/optional-install/software-based-router-dpdk/#kubernetes-deployment-with-multus) for full manifest examples and configuration details.

---

## Required Kernel Modules for QoS (Agent-side)

When the SiteRM Agent runs on the same host as FRR, host-level QoS (Linux TC / FireQOS) requires these kernel modules:

```bash
sch_htb sch_sfq ifb sch_ingress cls_u32 act_mirred
```

These are loaded automatically by the Agent's `run.sh` script. If missing:

```bash
modprobe sch_htb sch_sfq ifb sch_ingress cls_u32 act_mirred
```

---

## Known Limitations and Notes

- **No network-level QoS**: QoS rate limiting on FRR is applied at the Linux host level by the SiteRM Agent (using `tc`/FireQOS), not at the FRR/switch level.
- **BGP Multipath**: Supported via ECMP in FRR. Multiple BGP peers for the same destination will create multipath routes.
- **VRF isolation**: Linux VRF (via L3 master devices) is required for VRF-scoped routing. Ensure VRF interfaces are created before FRR attempts to add VRF-scoped routes.
- **Host networking required**: FRR Docker deployments must use `network_mode: host` for the container to access the host's VLAN interfaces and routing tables.

---

## Useful Links

- [sense-frr-collection GitHub](https://github.com/sdn-sense/sense-frr-collection)
- [FRRouting Documentation](https://docs.frrouting.org/)
- [Software Based Router (FRR) Installation Guide](/optional-install/software-based-router/)
- [FRR + VPP DPDK Installation Guide](/optional-install/software-based-router-dpdk/)
- [Back to Supported Network Devices](/getting-started/install-supported-network-devices/)
