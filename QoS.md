<!-- markdownlint-disable MD024 -->
[[Home](index.md)] [[Installation Information](Installation.md)] [[Docker Install](DockerInstallation.md)] [[Kubernetes Install](KubernetesInstallation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)] [[Debuggging](Debugging.md)][[QOS](QoS.md)]

# SENSE and SiteRM QoS Support

## Overview

SENSE supports multiple types of Quality of Service (QoS) requests, providing differentiated handling for:

- **End-to-End Path Requests**: Targeting a single host with explicit QoS.
- **L3 Path Requests Between Routers**: Targeting an IP range where multiple hosts may reside behind the same subnet. SiteRM dynamically calculates QoS allocations for hosts (physical, containerized, or virtual) registered in the SiteRM Frontend.
- **Multipath L3 Path Requests Between Routers**: Similar to **L3 Path Requests Between Routers**, but uses Multiple paths between BGP Peers.

SiteRM uses the **FireHol FireQOS** tool to implement QoS configurations. FireQOS simplifies rule definitions and translates them into Linux TC (Traffic Control) commands. [More info here](https://firehol.org/tutorial/fireqos-new-user/).

---

## End-to-End Path Requests (Layer2)

For End-to-End Path requests with QoS, SiteRM-Agent can enforce three modes:

### HardQoS

- Example: 10 Gbps NIC; VLAN 3600; IP 10.1.2.3/24; Request = 1 Gbps Hard QoS
- SiteRM-Agent sets and guarantees that only 1 Gbps will go through VLAN interface and the rest is limited accordingly.
  
  ```bash
  vlan.3600 committed 1 Gbps, max 1 Gbps
    class default rate 1Gbps
  <master_interface> committed 9 Gbps max 9 Gbps
  ```

### SoftQoS

- Example: 10 Gbps NIC; VLAN 3600; IP 10.1.2.3/24; Request = 1 Gbps Soft QoS.
- SiteRM-Agent sets and allows exceeding 1 Gbps if no contention, but guarantees 1 Gbps minimum.

  ```bash
  vlan.3600 committed 1 Gbps, max 10 Gbps
    class default rate 1Gbps
  <master_interface> committed 9 Gbps max 10 Gbps
  ```

### BestEffort

- Example: 10 Gbps NIC; VLAN 3600; IP 10.1.2.3/24; Request = 1 Gbps bestEffort QoS.
- SiteRM-Agent sets and allows exceeding 10 Gbps if no contention, but guarantees 100 Mbps.

  ```bash
  vlan.3600 committed 1 Gbps, max 10 Gbps
    class default rate 100mbps
  <master_interface> committed 9 Gbps max 10 Gbps
  ```

---

## L3 Path Requests Between Routers

When an L3 Path request is made for a specific IP range, SiteRM-FE and SiteRM-Agents coordinate to enforce host-level QoS.

In case of Multipath BGP configuration, QoS values are summed together from all different path requests.

### Example Scenario

- Site Uplink: 100 Gbps
- 10 SiteRM Agents, each on a 10 Gbps NIC
- Request: 50 Gbps to an IP range shared among multiple hosts

#### Calculation

- `TotalHostSpeed = 10 × 10 Gbps = 100 Gbps`
- `Requested = 50 Gbps`
- `NewRate = 5 Gbps/server`

QoS is proportionally distributed among servers based on their NIC speeds (e.g., if one server has 100 Gbps and another has 40 Gbps, allocation will reflect this difference).

### Host-Level Enforcement Modes

#### HardQoS

- Each host's rule for the IP range (e.g., 192.168.0.0/24) and allows exceeding 5 Gbps if no contention, but guarantees 5 Gbpss.
  
```bash
  <master_interface> committed 5 Gbps max 10 Gbps
    class priority1 commit 5Gbps max 5Gbps
      match <src_ip_range|dst_ip_range>
    class default commit 5Gbps max 5Gbps
```

#### SoftQoS

- Each host's rule for the IP range (e.g., 192.168.0.0/24) and allows exceeding 5 Gbps if no contention, but guarantees 5 Gbps.
  
```bash
  <master_interface> committed 5 Gbps max 10 Gbps
    class priority1 commit 5Gbps max 10Gbps
      match <src_ip_range|dst_ip_range>
    class default commit 5Gbps max 10Gbps
```

### BestEffort

- Each host's rule for the IP range (e.g., 192.168.0.0/24) and allows exceeding 100mbps if no contention, but guarantees 100 Mbps.

  ```bash
  <master_interface> committed 100mbps max 10 Gbps
    class priority1 commit 100mbps max 10Gbps
      match <src_ip_range|dst_ip_range>
    class default commit 9900mbps max 10Gbps
  ```

## Traffic Control Tuning Support

SiteRM enables administrators to fine-tune traffic shaping parameters through its configuration file.
This includes advanced `tc` tuning options such as:

```bash
mtu 9000 mpu 9000 quantum 200000 burst 300000 cburst 300000 qdisc sfq balanced
```

These parameters allow for optimized traffic handling in high-throughput environments,
accommodating scenarios like jumbo frames and bursty traffic patterns. Adjusting values such as `mtu`,
`quantum`, and `burst` helps tailor Quality of Service (QoS) behavior to the specific performance
characteristics of your network.

For a comprehensive explanation of these parameters and additional tuning examples, please refer to the
[FireQOS documentation](https://firehol.org/fireqos-manual.html).

### Network-Level Enforcement (Beta Feature)

SiteRM also supports QoS provisioning at the switch/router level for Dell OS9-based systems.

- If a request is for 50 Gbps for an L3 path, SiteRM-FE’s ProvisioningService can configure policing rules on the network device:
  - IP Range (e.g., 192.168.0.0/24): **policed at 50 Gbps**
  - See Dell OS9 rate-police CLI: [Dell Documentation](https://www.dell.com/support/manuals/en-us/dell-emc-os-9/s4048-on-9.14.2.8-cli-pub/rate-police?guid=guid-ad1fa7fb-ad93-4ae2-973b-84dce2c6f057&lang=en-us)

Note: This feature is currently limited to Dell OS9 platforms and is under evaluation for broader device support. SENSE team is investaging a broader use of QoS Control on network devices.

---

## Summary

SENSE and SiteRM provide robust, flexible QoS enforcement mechanisms:

- **End-to-End QoS** on VLAN interfaces with Hard, Soft, or Best Effort configurations.
- **L3 Path QoS** with intelligent per-host allocation and network-level enforcement.
- **FireQOS** simplifies rule management and leverages Linux TC for actual packet shaping.
- Soft vs Hard QoS modes help balance between guaranteed performance and flexible utilization.

These capabilities ensure SENSE can deliver predictable and optimized network performance for science workflows.
