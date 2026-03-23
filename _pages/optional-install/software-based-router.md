---
title: "Software Based Router (FRR)"
layout: single
classes: wide
permalink: "/optional-install/software-based-router/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

[FRRouting (FRR)](https://frrouting.org/) is an open-source software-based routing suite for Linux and Unix platforms. When physical network equipment is unavailable or impractical, FRR can act as a software-defined router, providing full BGP routing capabilities fully controllable by SENSE.

SENSE provides a dedicated Ansible collection (`sense.frr`) that allows SiteRM Frontend to manage FRR routers the same way it manages hardware switches. This means SENSE can:

- Create and delete VLANs on FRR nodes
- Configure BGP peering and prefix-list advertisements
- Apply QoS and routing rules through the Ruler

**Typical use case**: Sites that want BGP connectivity between their network domains but do not have a dedicated hardware router, or sites using FABRIC testbed nodes or Kubernetes-hosted routing pods.

---

## Architecture

```
SENSE Orchestrator
       |
  SiteRM Frontend
       | (Ansible via sense.frr collection)
       |
  FRR Node (Docker or bare metal)
       | (BGP)
  Peer Routers / DTN Hosts
```

The FRR node runs as a Docker container (using the official `frrouting/frr` image) with host networking, giving it direct access to all host interfaces and routing tables. SiteRM manages its configuration through the `sense.frr` Ansible collection.

---

## Prerequisites

- A Linux host with **Docker** or **Docker Compose** installed
- The host must be reachable from the SiteRM Frontend (for Ansible SSH access)
- At least one physical or VLAN interface the FRR node will use for BGP peering
- An AS number assigned to the FRR node
- SSH access from SiteRM Frontend to the host

---

## Step 1 — Install FRR via Docker Compose

Clone or copy the following `docker-compose.yml` to your FRR host (e.g., `/opt/frr/docker-compose.yml`):

```yaml
services:
  frr:
    image: frrouting/frr
    container_name: frr
    network_mode: "host"
    privileged: true
    cap_add:
      - ALL
    volumes:
      - ./etc/frr/daemons:/etc/frr/daemons
      - ./etc/frr/frr.conf:/etc/frr/frr.conf
      - ./etc/frr/vtysh.conf:/etc/frr/vtysh.conf
```

**Why `network_mode: host`?** FRR needs direct access to all host network interfaces and the kernel routing table. Host networking is required for BGP and VLAN management to function correctly.

---

## Step 2 — Configure FRR Daemons

Create the daemons configuration file at `./etc/frr/daemons`:

```bash
# Enable BGP and Zebra (required for SENSE)
bgpd=yes
zebra=yes

# All other daemons can remain off unless your site needs them
ospfd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
pim6d=no
ldpd=no
bfdd=no
vrrpd=no

vtysh_enable=yes
zebra_options="  -A 127.0.0.1 -s 90000000"
bgpd_options="   -A 127.0.0.1"
```

---

## Step 3 — Create Initial FRR Configuration

Create the initial configuration at `./etc/frr/frr.conf`. Replace `REPLACEME_HOSTNAME` and `REPLACEME_ASN` with your site's values:

```
!
frr version 8.4_git
frr defaults traditional
hostname REPLACEME_HOSTNAME
service integrated-vtysh-config
log file /var/log/frr/bgpd.log informational
log stdout
!
router bgp REPLACEME_ASN
!
end
```

**Example for two peering FRR nodes** (Node A and Node B):

Node A (`192.168.101.1`, ASN 65001):
```
!
router bgp 65001
 bgp router-id 192.168.101.1
 neighbor 192.168.101.2 remote-as 65002
 !
 address-family ipv4 unicast
  network 192.168.0.0/24
  neighbor 192.168.101.2 soft-reconfiguration inbound
  neighbor 192.168.101.2 route-map IMPORT_POLICY in
  neighbor 192.168.101.2 route-map EXPORT_POLICY out
 exit-address-family
exit
!
ip prefix-list ALLOWED_PREFIXES seq 5 permit 192.168.1.0/24
ip prefix-list ADVERTISED_PREFIXES seq 5 permit 192.168.0.0/24
!
route-map IMPORT_POLICY permit 10
 match ip address prefix-list ALLOWED_PREFIXES
exit
!
route-map EXPORT_POLICY permit 10
 match ip address prefix-list ADVERTISED_PREFIXES
exit
!
end
```

Node B (`192.168.101.2`, ASN 65002):
```
!
router bgp 65002
 bgp router-id 192.168.101.2
 neighbor 192.168.101.1 remote-as 65001
 !
 address-family ipv4 unicast
  network 192.168.1.0/24
  neighbor 192.168.101.1 soft-reconfiguration inbound
  neighbor 192.168.101.1 route-map IMPORT_POLICY in
  neighbor 192.168.101.1 route-map EXPORT_POLICY out
 exit-address-family
exit
!
ip prefix-list ALLOWED_PREFIXES seq 5 permit 192.168.0.0/24
ip prefix-list ADVERTISED_PREFIXES seq 5 permit 192.168.1.0/24
!
route-map IMPORT_POLICY permit 10
 match ip address prefix-list ALLOWED_PREFIXES
exit
!
route-map EXPORT_POLICY permit 10
 match ip address prefix-list ADVERTISED_PREFIXES
exit
!
end
```

Create the `vtysh.conf`:
```
service integrated-vtysh-config
```

---

## Step 4 — Start FRR

```bash
cd /opt/frr
docker compose up -d

# Verify FRR is running
docker exec -it frr vtysh -c "show version"
docker exec -it frr vtysh -c "show bgp summary"
```

---

## Step 5 — Configure SiteRM Frontend

### 5a — Add FRR to the Ansible Inventory

In the SiteRM Frontend ansible configuration (`fe/conf/etc/ansible-conf.yaml`), add your FRR node:

```yaml
inventory:
  frr_router:                          # This name must match the switch name in main.yaml
    network_os: sense.frr.frr          # FRR network OS plugin
    host: 192.168.1.100                # IP of the host running FRR Docker container
    user: ubuntu                       # SSH user on the host
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense   # Path to SSH key inside container
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
```

**Note:** SiteRM connects to the **host** running the FRR Docker container via SSH, then executes commands inside the container using `docker exec`. The `network_os: sense.frr.frr` plugin handles this automatically.

### 5b — Register FRR Node in Site Configuration

In the SiteRM Frontend `main.yaml`, add the FRR node as a switch:

```yaml
MAIN:
  general:
    sitename: T2_US_YOURSITE
    ...
  site:
    ...
    switch:
      frr_router:                        # Must match the ansible inventory name
        allports: false
        ports:
          "eth0":
            capacity: 10000             # Port capacity in Mbps
            vlan_range: [3600-3699]
```

---

## Step 6 — Apply Kernel Tuning (Recommended)

For high-throughput BGP routing, apply these kernel TCP tuning parameters on the FRR host:

```bash
# Save as /opt/frr/tuning.sh and run as root
sysctl -w net.core.rmem_max=2147483647
sysctl -w net.core.wmem_max=2147483647
sysctl -w net.ipv4.tcp_rmem="4096 87380 268435456"
sysctl -w net.ipv4.tcp_wmem="4096 87380 268435456"
sysctl -w net.core.netdev_max_backlog=250000
sysctl -w net.ipv4.tcp_no_metrics_save=1
sysctl -w net.ipv4.tcp_adv_win_scale=1
sysctl -w net.ipv4.tcp_low_latency=1
sysctl -w net.ipv4.tcp_timestamps=0
sysctl -w net.ipv4.tcp_sack=1
sysctl -w net.ipv4.tcp_moderate_rcvbuf=1
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.ipv4.tcp_mtu_probing=1
sysctl -w net.core.default_qdisc=fq
```

To persist across reboots, add these to `/etc/sysctl.conf`.

---

## Verification

After the FRR container is running and SiteRM Frontend is configured:

1. **Check BGP peering from inside FRR:**
   ```bash
   docker exec -it frr vtysh -c "show bgp summary"
   docker exec -it frr vtysh -c "show ip route"
   ```

2. **Verify SiteRM can reach FRR via Ansible:**
   ```bash
   # From inside the SiteRM Frontend container:
   siterm-ansible-runner --hostname frr_router --action getfacts
   ```

3. **Check the topology includes FRR node:** Log into the SiteRM Web UI and navigate to the Topology section. The FRR node should appear as a managed router.

---

## Notes and Limitations

- The FRR container must use **host networking** (`network_mode: host`). Bridge networking will not work.
- SiteRM manages BGP prefix advertisements via Ansible — do not manually change `route-map` or `prefix-list` entries that SENSE controls, as they will be overwritten.
- FRR supports both IPv4 and IPv6 BGP. SENSE primarily uses IPv6 for path management.
- For FRR + DPDK (high-performance data plane with VPP), see the [Software Based Router (FRR) + DPDK](/optional-install/software-based-router-dpdk/) guide.
- For Kubernetes deployments with Multus CNI (VPP+FRR in a pod with physical NIC passthrough), see the [Kubernetes Deployment with Multus](/optional-install/software-based-router-dpdk/#kubernetes-deployment-with-multus) section of the DPDK guide.
