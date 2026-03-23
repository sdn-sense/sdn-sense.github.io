---
title: "Software Based Router (FRR) + Data Plane Development Kit (DPDK)"
layout: single
classes: wide
permalink: "/optional-install/software-based-router-dpdk/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

This guide extends the [Software Based Router (FRR)](/optional-install/software-based-router/) guide by adding **VPP (Vector Packet Processor)** as a high-performance DPDK-based data plane. The combination of FRR (control plane) and VPP (data plane) creates a software router capable of line-rate packet forwarding, suitable for 10/40/100 Gbps science network links.

**What is VPP?** VPP (fd.io Vector Packet Processor) is an open-source framework based on DPDK (Data Plane Development Kit) that bypasses the Linux kernel for packet forwarding, achieving near wire-speed performance on commodity hardware.

**What is DPDK?** DPDK (Data Plane Development Kit) is a set of libraries that allow user-space applications to directly control NICs, bypassing the Linux kernel network stack. This eliminates interrupt overhead and enables sustained multi-gigabit forwarding.

**Architecture with FRR + VPP:**
```
┌─────────────────────────────────────────┐
│  FRR (Control Plane)                    │
│   BGP, Zebra, route-map management      │
│   Managed by: SENSE Ansible (sense.frr) │
└─────────────────┬───────────────────────┘
                  │  Routes/FIB
┌─────────────────▼───────────────────────┐
│  VPP (Data Plane - DPDK)               │
│   High-speed packet forwarding          │
│   VLAN sub-interfaces                   │
│   Direct NIC access (bypasses kernel)   │
└─────────────────────────────────────────┘
```

---

## When to Use This Setup

Use FRR + VPP when:
- Your site requires **10 Gbps or higher** routing throughput
- You are using testbed resources (e.g., FABRIC nodes) with dedicated NICs
- Standard Linux kernel forwarding is a bottleneck
- You want jumbo frame support (MTU 9000) at line rate

Use plain FRR (without VPP) when:
- Throughput requirements are below ~5 Gbps
- The Linux kernel routing stack is sufficient
- Simpler deployment is preferred

---

## Prerequisites

- A Linux host with a **DPDK-compatible NIC** (Intel X710, X520, ConnectX-5, etc.)
- The NIC must have **IOMMU** enabled in the host BIOS (`intel_iommu=on` kernel parameter)
- The host kernel must support **hugepages** (required by DPDK)
- Docker or Docker Compose installed
- FRR already installed (see the [FRR installation guide](/optional-install/software-based-router/))
- SSH access from the SiteRM Frontend

---

## Step 1 — Prepare the Host

### Enable Hugepages

VPP requires hugepages for its memory model. Configure them permanently:

```bash
# Add to /etc/default/grub GRUB_CMDLINE_LINUX:
# intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=8

# After editing grub:
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```

Verify after reboot:
```bash
grep HugePages /proc/meminfo
# Should show HugePages_Total: 8 (or however many you configured)
```

### Enable IOMMU

Verify IOMMU is active:
```bash
dmesg | grep -i iommu
# Should see: "Intel-IOMMU: enabled"
```

### Bind NIC to DPDK-compatible Driver

Identify your NIC's PCI address:
```bash
lspci | grep -i ethernet
# Example: 01:00.0 Ethernet controller: Intel Corporation X710 10GbE Controller
```

Load the vfio-pci driver and bind the NIC:
```bash
modprobe vfio-pci

# Get the vendor:device IDs
lspci -n -s 01:00.0
# Example output: 01:00.0 0200: 8086:1572

# Bind the NIC to vfio-pci
echo "8086 1572" > /sys/bus/pci/drivers/vfio-pci/new_id
```

**Important:** Once bound to DPDK, the NIC is **no longer visible to the Linux kernel** — it will disappear from `ip link show`. VPP will own it directly.

---

## Step 2 — Install VPP

Install VPP on the host system:

```bash
# Add the FD.io VPP repository (example for EL9/RHEL9):
curl -s https://packagecloud.io/install/repositories/fdio/release/script.rpm.sh | bash
dnf install -y vpp vpp-plugins vpp-api-python

# For Ubuntu 22:
curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
apt-get install -y vpp vpp-plugin-core
```

---

## Step 3 — Configure VPP

VPP configuration is split into startup configuration and runtime interface setup.

### Startup Configuration (`/etc/vpp/startup.conf`)

```
unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
}

api-trace {
  on
}

cpu {
  ## Assign cores to VPP main and worker threads
  ## main-core 1
  ## corelist-workers 2-3
}

dpdk {
  ## List of DPDK-managed NICs by PCI address
  dev 0000:01:00.0 {
    name eth0
  }
  ## Optionally add more NICs:
  # dev 0000:01:00.1 {
  #   name eth1
  # }
  num-rx-queues 4
  num-tx-queues 4
}

buffers {
  buffers-per-numa 128000
}
```

### Start VPP

```bash
systemctl enable --now vpp
```

### Configure VPP Interfaces at Runtime

Use the VPP CLI (`vppctl` or `vpp_api_test`) to set up interfaces:

```bash
# Enter VPP CLI
vppctl

# Show available interfaces
show interface

# Bring up the DPDK interface
set interface state eth0 up

# Configure VLAN sub-interfaces (SENSE will manage these automatically)
# Example: Create VLAN 3600 on eth0
create sub eth0 3600
set interface state eth0.3600 up
set interface ip address eth0.3600 2001:db8::/64

# Show current IP config
show interface address
```

---

## Step 4 — Configure FRR alongside VPP

FRR handles the **control plane** (BGP route exchange). Follow the FRR installation guide for the Docker Compose setup, but make one important change: since VPP owns the NIC, FRR uses a separate interface (such as a loopback or a Linux TAP/MEMIF interface created by VPP) for BGP peering.

**Important:** Do NOT bind the interface used for BGP management traffic to DPDK — only the high-speed data interfaces should be DPDK-managed.

Example FRR BGP configuration for a VPP-backed router:

```
!
router bgp 65001
 bgp router-id 10.0.0.1
 neighbor 10.0.0.2 remote-as 65002
 !
 address-family ipv6 unicast
  network 2001:db8::/32
  neighbor 10.0.0.2 activate
  neighbor 10.0.0.2 soft-reconfiguration inbound
 exit-address-family
exit
!
```

---

## Step 5 — Configure SiteRM Frontend

The Ansible inventory for an FRR+VPP node uses **the same `sense.frr.frr` plugin** as a plain FRR deployment. SENSE manages the FRR control plane; VPP data-plane changes (VLAN sub-interfaces, IP addresses) are handled via additional Ansible tasks.

```yaml
# fe/conf/etc/ansible-conf.yaml
inventory:
  vpp_frr_router:
    network_os: sense.frr.frr
    host: 10.0.1.100             # Management IP of the VPP+FRR host
    user: ubuntu
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: true                 # May need sudo to run vppctl
    ssh_common_args: "-o StrictHostKeyChecking=no"
```

In `main.yaml`, register the node as a switch with VPP-managed ports:

```yaml
MAIN:
  general:
    sitename: T2_US_YOURSITE
    ...
  site:
    ...
    switch:
      vpp_frr_router:
        allports: false
        ports:
          "eth0":
            capacity: 100000         # 100 Gbps NIC
            vlan_range: [3600-3699]
```

---

## Step 6 — Tune Interfaces for High Throughput

Run the interface tuning script on each data interface **before** binding to DPDK. This sets optimal NIC parameters for jumbo frames and high queue depth:

```bash
#!/bin/bash
INTF=$1
echo "Tuning interface $INTF for high-throughput..."

# Set jumbo frame MTU
ip link set dev $INTF mtu 9000

# Increase TX queue length
ip link set dev $INTF txqueuelen 10000

# Disable adaptive interrupt coalescing
ethtool -C $INTF adaptive-rx off

# Set fixed interrupt coalescing (1ms)
ethtool -C $INTF rx-usecs 1000

# Set maximum ring buffer sizes
MAX_RX=$(ethtool -g $INTF | grep 'RX:' | awk '{print $2}' | head -1)
MAX_TX=$(ethtool -g $INTF | grep 'TX:' | awk '{print $2}' | head -1)
ethtool -G $INTF rx $MAX_RX tx $MAX_TX

echo "Done tuning $INTF"
```

Usage:
```bash
chmod +x tune-interface.sh
./tune-interface.sh enp1s0
```

---

## Kernel TCP Tuning

Apply the following sysctl settings for maximum throughput across all flows:

```bash
# TCP buffer sizes (2 GiB max)
sysctl -w net.core.rmem_max=2147483647
sysctl -w net.core.wmem_max=2147483647
sysctl -w net.ipv4.tcp_rmem="4096 87380 268435456"
sysctl -w net.ipv4.tcp_wmem="4096 87380 268435456"

# Network backlog and TCP tuning
sysctl -w net.core.netdev_max_backlog=250000
sysctl -w net.ipv4.tcp_no_metrics_save=1
sysctl -w net.ipv4.tcp_adv_win_scale=1
sysctl -w net.ipv4.tcp_low_latency=1
sysctl -w net.ipv4.tcp_timestamps=0
sysctl -w net.ipv4.tcp_sack=1
sysctl -w net.ipv4.tcp_moderate_rcvbuf=1

# Use BBR congestion control + fq queueing disc
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.ipv4.tcp_mtu_probing=1
sysctl -w net.core.default_qdisc=fq
```

Persist these in `/etc/sysctl.conf`.

---

## Verification

After the setup is complete:

1. **Verify VPP is forwarding:**
   ```bash
   vppctl show interface
   vppctl show interface address
   vppctl show ip6 fib
   ```

2. **Verify FRR BGP peering:**
   ```bash
   docker exec -it frr vtysh -c "show bgp summary"
   docker exec -it frr vtysh -c "show bgp ipv6 unicast"
   ```

3. **Test connectivity:**
   ```bash
   ping6 <peer_IPv6_address>
   tracepath6 <remote_host>
   ```

4. **Verify SENSE manages the node:**
   From SiteRM Frontend, run:
   ```bash
   siterm-ansible-runner --hostname vpp_frr_router --action getfacts
   ```

---

## Kubernetes Deployment with Multus

VPP+FRR can also be deployed as a Kubernetes **StatefulSet** using [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) to pass physical NICs directly into the pod. This is the recommended approach for sites already managing SENSE infrastructure on Kubernetes.

**How it works:**
- `NetworkAttachmentDefinition` objects define each physical NIC attachment using the `host-device` CNI plugin
- The DPDK NIC is passed directly into the pod (PCI passthrough via `vfio-pci`)
- VPP inside the pod binds the NIC and creates **Linux mirror interfaces** via LCP (`lcp create`) — these are the interfaces FRR uses for BGP and routing
- SENSE connects to FRR via SSH on a dedicated port (22334) using the pod's IPv6 address

Two variants are provided in the [vpp-frr repository](https://github.com/sdn-sense/vpp-frr):

| File | NICs | Hugepage type | Use case |
|---|---|---|---|
| `vpp-frr-router.yaml` | 1 NIC | 1Gi + 2Mi | Standard single-uplink router |
| `new-vpp-frr.yaml` | 2 NICs, bonded | 2Mi only | Dual-uplink with XOR/L3-4 bond |

---

### Prerequisites for Kubernetes Deployment

- Kubernetes cluster with **Multus CNI** installed
- Node with a **DPDK-compatible NIC** bound to `vfio-pci` (see Step 1 of bare-metal guide above)
- **Hugepages** configured on the target node:

```bash
# For 2Mi hugepages (both variants):
echo 4096 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# For 1Gi hugepages (vpp-frr-router.yaml only):
echo 1 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
```

Persist in `/etc/default/grub`: `hugepagesz=2M hugepages=4096 hugepagesz=1G hugepages=1`

- The `sense` namespace must exist: `kubectl create namespace sense`

---

### Variant 1: Single NIC (`vpp-frr-router.yaml`)

Uses one physical NIC passed into the pod. The NIC is attached via a `NetworkAttachmentDefinition` with static IPAM to give the pod a management IP before VPP starts.

**Resources:** 32 CPU, 50Gi RAM, 1Gi hugepages-1Gi + 8Gi hugepages-2Mi

**Step 1 — Create the `NetworkAttachmentDefinition`:**

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: pci-pt-interface-1
  namespace: sense
spec:
  config: '{
    "cniVersion": "0.4.0",
    "name": "net1",
    "plugins": [
      {
        "type": "host-device",
        "pciBusID": "0000:17:00.1",
        "ipam": {
          "type": "static",
          "addresses": [{"address": "10.77.50.10/24", "gateway": "10.77.50.1"}],
          "routes": [{"dst": "10.77.50.0/24"}]
        }
      },
      {
        "type": "tuning",
        "sysctl": {
          "net.ipv6.conf.net1.autoconf": "0",
          "net.ipv6.conf.net1.accept_ra": "0"
        }
      }
    ]
  }'
```

**Step 2 — Create the VPP startup ConfigMap:**

The `startup.gate` file configures VPP interfaces at startup. It runs after VPP initializes the DPDK NIC and sets up VLAN sub-interfaces:

```
comment { LAN interface }
set interface state Ethernet1/0/0 up
set interface mtu packet 9216 Ethernet1/0/0
set interface feature gso Ethernet1/0/0 enable
lcp create Ethernet1/0/0 host-if e1

comment { WAN Facing interface (VLAN 3999) }
create sub-interfaces Ethernet1/0/0 3999
set interface state Ethernet1/0/0.3999 up
set interface mtu packet 1500 Ethernet1/0/0.3999
set interface feature gso Ethernet1/0/0.3999 enable
set interface ip address Ethernet1/0/0.3999 2605:9a00:10:7::1/127

comment { LAN-WAN interface 2540 }
create sub-interfaces Ethernet1/0/0 2540
set interface state Ethernet1/0/0.2540 up
set interface mtu packet 9212 Ethernet1/0/0.2540
set interface feature gso Ethernet1/0/0.2540 enable
set interface ip address Ethernet1/0/0.2540 2605:9a00:10:2010::/64
```

- **`lcp create Ethernet1/0/0 host-if e1`** — creates Linux interface `e1` mirroring the VPP interface. FRR uses `e1` for control-plane traffic.
- Sub-interfaces (`Ethernet1/0/0.2540`, etc.) are the SENSE-managed VLAN data paths.
- MTU 9212 on LAN-WAN interfaces accounts for VLAN header overhead on a 9216 outer MTU.

**Step 3 — Create the SSH key Secret:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vppfrr-ssh-key
  namespace: sense
type: Opaque
stringData:
  authorized_keys: |
    ssh-ed25519 AAAA... your-sense-ssh-public-key
```

The SiteRM Frontend connects to the VPP+FRR pod via SSH (port 22334) to run Ansible. Add the Frontend's public key here.

**Step 4 — Deploy the StatefulSet:**

Key fields in the StatefulSet spec:

```yaml
annotations:
  k8s.v1.cni.cncf.io/networks: pci-pt-interface-1   # Attach the NIC via Multus
securityContext:
  privileged: true
  capabilities:
    add: [NET_ADMIN, SYS_RAWIO, IPC_LOCK]            # Required for DPDK/VPP
env:
  - name: ENV_MAIN_CORE
    value: "0"                                         # VPP main thread core
  - name: ENV_CORELIST_WORKERS
    value: "1-8"                                       # VPP forwarding worker cores
  - name: ENV_BUFFERS_PER_NUMA
    value: "24576"                                     # Packet buffer pool size
  - name: ENV_PUBLIC_INTF
    value: "net1"                                      # Multus interface name in pod
  - name: ENV_PUBLIC_INTF_PCI
    value: "0000:17:00.1"                             # PCI address of the NIC
  - name: SSH_PORT
    value: "22334"                                     # SSH port for SENSE management
  - name: SSH_LISTEN6_ADDRESS
    value: "[2605:9a00:10:7::1]"                      # IPv6 addr VPP assigns to WAN iface
```

Deploy:
```bash
kubectl apply -f vpp-frr-router.yaml
kubectl -n sense get pods -l app=vpp-frr
```

---

### Variant 2: Dual NIC with Bonding (`new-vpp-frr.yaml`)

Uses two physical NICs that VPP bonds together in XOR/L3-4 mode for higher throughput and link redundancy. Neither NIC has IPAM — VPP handles all addressing.

**Resources:** 24 CPU, 24Gi RAM, 8Gi hugepages-2Mi (no 1Gi hugepages)

**Two `NetworkAttachmentDefinition`s** (one per NIC, no IPAM):

```yaml
# Interface 1
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: pci-pt-interface-1
  namespace: sense
spec:
  config: '{"cniVersion":"0.4.0","name":"net1","plugins":[
    {"type":"host-device","pciBusID":"0000:17:00.1"},
    {"type":"tuning","sysctl":{"net.ipv6.conf.net1.autoconf":"0","net.ipv6.conf.net1.accept_ra":"0"}}
  ]}'
---
# Interface 2
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: pci-pt-interface-2
  namespace: sense
spec:
  config: '{"cniVersion":"0.4.0","name":"net2","plugins":[
    {"type":"host-device","pciBusID":"0000:17:00.0"},
    {"type":"tuning","sysctl":{"net.ipv6.conf.net2.autoconf":"0","net.ipv6.conf.net2.accept_ra":"0"}}
  ]}'
```

**VPP `startup.gate` for bonded NICs:**

```
comment { === Interface 1 === }
set interface state Ethernet1/0/0 up
set interface mtu packet 9216 Ethernet1/0/0
set interface feature gso Ethernet1/0/0 enable
lcp create Ethernet1/0/0 host-if e1

comment { === Interface 2 === }
set interface state Ethernet2/0/0 up
set interface mtu packet 9216 Ethernet2/0/0
set interface feature gso Ethernet2/0/0 enable
lcp create Ethernet2/0/0 host-if e2

comment { === Create bond (XOR L3+L4 hash) === }
create bond mode xor load-balance l34
bond add BondEthernet0 Ethernet1/0/0
bond add BondEthernet0 Ethernet2/0/0

set interface state BondEthernet0 up
set interface mtu packet 9216 BondEthernet0
set interface feature gso BondEthernet0 enable
lcp create BondEthernet0 host-if bond0

comment { === WAN Facing interface (VLAN 3999) === }
create sub-interfaces BondEthernet0 3999
set interface state BondEthernet0.3999 up
set interface mtu packet 1500 BondEthernet0.3999
set interface ip address BondEthernet0.3999 2605:9a00:10:7::1/127

comment { === LAN-WAN interface 2540 === }
create sub-interfaces BondEthernet0 2540
set interface state BondEthernet0.2540 up
set interface mtu packet 9212 BondEthernet0.2540
set interface ip address BondEthernet0.2540 2605:9a00:10:2010::/64
```

- **Bond mode `xor load-balance l34`** — hashes on Layer 3 (IP) + Layer 4 (TCP/UDP) for per-flow load balancing across both NICs.
- Both physical interfaces are mirrored to Linux (`e1`, `e2`), and the bond aggregate is mirrored to `bond0` for FRR.

**StatefulSet** — references both Multus networks:

```yaml
annotations:
  k8s.v1.cni.cncf.io/networks: pci-pt-interface-1,pci-pt-interface-2
env:
  - name: ENV_PUBLIC_INTF
    value: "net1"
  - name: ENV_PUBLIC_INTF_PCI
    value: "0000:17:00.1"
  - name: ENV_PRIVATE_INTF
    value: "net2"
  - name: ENV_PRIVATE_INTF_PCI
    value: "0000:17:00.0"
```

Deploy:
```bash
kubectl apply -f new-vpp-frr.yaml
kubectl -n sense get pods -l app=vpp-frr
```

---

### Connecting SENSE to the Kubernetes VPP+FRR Pod

The pod exposes SSH on port **22334** at the IPv6 address assigned to the WAN sub-interface (e.g., `2605:9a00:10:7::1`). Configure the SiteRM Ansible inventory to reach it:

```yaml
inventory:
  vpp_frr_k8s:
    network_os: sense.frr.frr
    host: "2605:9a00:10:7::1"     # IPv6 addr of pod's WAN interface
    user: root
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no -p 22334"
```

The SiteRM Debugger should also be deployed in the same Kubernetes network namespace (or configured with the pod's IP) to enable ping/traceroute probes from within the VLAN.

---

### Node Pinning

Both manifests use `nodeSelector` and `nodeAffinity` to pin the pod to the specific node that has the DPDK NIC bound:

```yaml
nodeSelector:
  kubernetes.io/hostname: c020.af.uchicago.edu
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - c020.af.uchicago.edu
```

Update these values to match the hostname of your DPDK node.

---

## Troubleshooting

| Symptom | Cause | Resolution |
|---|---|---|
| VPP fails to start | Hugepages not configured | Check `/proc/meminfo` for `HugePages_Total` > 0; check node hugepage allocation |
| NIC not visible in VPP | PCI binding not complete | Re-run `vfio-pci` binding steps; verify `NetworkAttachmentDefinition` PCI address |
| Pod stuck in `Pending` | Hugepages not available on node or NIC in use | Check `kubectl describe pod`, verify hugepage resource on node |
| BGP sessions not establishing | FRR and VPP using same NIC | Separate management and data NICs; use LCP mirror interface for FRR |
| SENSE Ansible fails | SSH not accessible on pod IP/port | Verify pod is running, SSH port 22334 reachable, authorized_keys Secret is correct |
| Packet drops at high rate | Insufficient hugepages or worker cores | Increase hugepages on node and assign more `ENV_CORELIST_WORKERS` |
| Bond not forming | Second NIC not passed to pod | Verify both `NetworkAttachmentDefinition`s exist and both PCI addresses are correct |

---

## Notes

- VPP is the **data plane** only. All BGP, route-maps, and prefix lists are managed by FRR and by extension by SENSE via Ansible.
- SENSE's `sense.frr.frr` Ansible plugin targets FRR, not VPP directly. VPP interface configuration is expected to be handled separately (or via custom Ansible tasks).
- For testbed environments (e.g., FABRIC), SmartNICs or FPGA-based NICs may have different DPDK driver requirements.
- Reference implementation and demo playbooks are available in the [vpp-frr GitHub repository](https://github.com/sdn-sense/vpp-frr).
