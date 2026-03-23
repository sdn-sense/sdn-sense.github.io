---
title: "Supported Network Devices"
layout: single
classes: wide
permalink: "/getting-started/install-supported-network-devices/"
author_profile: false
sidebar:
  nav: "docs"
---

Site resource manager supports the following switches and control options:

|      Switch OS      | Viz in MRML | VLAN Creation | VLAN Translation | Ping/Traceroute | BGP Control | BGP Multipath |      QoS      |                                          Comments                                          |
|:-------------------:|:-----------:|:-------------:|:----------------:|:---------------:|:-----------:|:-------------:|:-------------:|:------------------------------------------------------------------------------------------:|
|         RAW         |      1      |       0       |        0         |        0        |      0      |       0       |       0       |   RAW Plugin (Fake switch, no control on hardware. use only if instructed by SENSE Team)   |
|      [Dell OS 9](/devices/dell-os9/)      |      1      |       1       |        0         |        1        |      1      |       0       |  1 (see note below)  |    [Dell OS9 Ansible Collection](https://github.com/sdn-sense/sense-dellos9-collection)    |
|     [Dell OS 10](/devices/dell-os10/)      |      1      |       1       |        0         |        1        |      1      |       1       |       0       |   [Dell OS10 Ansible Collection](https://github.com/sdn-sense/sense-dellos10-collection)   |
|     [Azure SONiC](/devices/azure-sonic/)     |      1      |       1       |        0         |        1        |      1      |       1       |       0       |   [Azure SONiC Ansible Collection](https://github.com/sdn-sense/sense-sonic-collection)    |
|     [Arista EOS](/devices/arista-eos/)      |      1      |       1       |        0         |        1        |      0      |       0       |       1       |  [Arista EOS Ansible Collection](https://github.com/sdn-sense/sense-aristaeos-collection)  |
|    [Juniper Junos](/devices/juniper-junos/)    |      1      |       1       |        0         |        1        |      1      |       1       |       0       |  [Juniper Junos Ansible Collection](https://github.com/sdn-sense/sense-junos-collection)   |
|       [FreeRTR](/devices/freertr/)       |      1      |       0       |        0         |        0        |      0      |       0       |       0       |    [FreeRTR Ansible Collection](https://github.com/sdn-sense/sense-freertr-collection)     |
|  [Cisco Nexus 9/10](/devices/cisco-nexus/)   |      1      |       1       |        0         |        1        |      1      |       1       |       0       | [Cisco Nexus 9 Ansible Collection](https://github.com/sdn-sense/sense-cisconx9-collection) |
|   [FRRouting (FRR)](/devices/frr/)   |      1      |       1       |        0         |        1        |      1      |       1       |       0       |     [FRRouting Ansible Collection](https://github.com/sdn-sense/sense-frr-collection)      |
| [FRRouting (FRR+VPP)](/devices/frr/) |      1      |       1       |        0         |        1        |      1      |       1       |       0       |     [FRRouting Ansible Collection](https://github.com/sdn-sense/sense-frr-collection)      |
|     Mellanox OS     |      0      |       0       |        0         |        0        |      0      |       0       |       0       |                          Development, expected 2026                                        |
|     [Nokia SR OS](/devices/nokia-sros/)     |      0      |       0       |        0         |        0        |      0      |       0       |       0       |    [Nokia SR-OS Collection](https://github.com/sdn-sense/sense-nokiasros-collection) — Development, expected 2026   |

Here is description of each action:

* **Viz in MRML** means that SiteRM is capable to receive configuration from the network device and represent it in MRML Model. Here is an example what commands SiteRM will execute on the Dell OS 10 device to get all information for visualization. For other devices, take a look at their individual ansible collections.

```bash
  show running-config
  show lldp neighbors detail
  show interfaces
  show vlans
  show interface port-channel
  show system
```

* **VLAN Creation** means that SiteRM is capable to create and delete VLAN on the device. Here is an example of what commands SiteRM will execute on the Dell OS 10 to create or delete SENSE provisioned VLAN. Allowed IP Ranges, MTU, VRF, and allowed ports are controllable per device inside your Site GIT configuration [https://github.com/sdn-sense/rm-configs/](https://github.com/sdn-sense/rm-configs/). For other devices, look at the templates here: [https://github.com/sdn-sense/ansible-templates/tree/master/project/templates](https://github.com/sdn-sense/ansible-templates/tree/master/project/templates)

```bash
# Create
interface vlan 3618
 mtu 9216
 ip vrf forwarding Vrf_sense01
 description urn:ogf:network:service+8731092c-0bcb-4233-992d-d70c0a9fe144:vt+l2-policy::Connection_2
 ipv6 address fc00:0:504:4000:0:0:0:1/64
 no shutdown
interface Port-channel 102
 switchport trunk allowed vlan 3618
# Delete
no interface vlan 3618
# Note: It does not execute vlan deletion from switchport trunk, as Dell OS 10 takes care that automatically once vlan deleted. This might be diff for other devices, as each has unique set of commands.
```

* **VLAN Translation** Currently not supported.

* **Ping/Traceroute** tells that SiteRM is capable to issue ping or traceroute (only if IP set on a specific created VLAN). Here is an example of what commands SiteRM will execute on the Dell OS 10 to Ping/Traceroute. For other devices, please look at templates here: [https://github.com/sdn-sense/ansible-templates/tree/master/project/templates](https://github.com/sdn-sense/ansible-templates/tree/master/project/templates) ending with `_ping.j2` or `_traceroute.j2`

```bash
ping6 vrf Vrf_sense01 fc00:0:504:4000:0:0:0:2 -c 10 -i 5
traceroute vrf Vrf_sense01 fc00:0:504:4000:0:0:0:2
```

* **BGP Control** allows SiteRM and SENSE to control BGP on the device. Based on Sites GIT configuration, SiteRM will accept advertisements for configured ranges only. Git configuration also includes control for BGP ASN Number, allowed IPv6 ranges, allowed Private IPv6 ranges, use of vrf and vrf name. Here is an example of Dell OS 10 executed commands and for other devices, please look at templates here: [https://github.com/sdn-sense/ansible-templates/tree/master/project/templates](https://github.com/sdn-sense/ansible-templates/tree/master/project/templates)

```bash
#BPG Create
route-map sense-eb95dea88c650f9564357b952959e48d-mapin permit 10
 match ipv6 address sense-eb95dea88c650f9564357b952959e48d-from
route-map sense-eb95dea88c650f9564357b952959e48d-mapout permit 10
 match ipv6 address sense-eb95dea88c650f9564357b952959e48d-to

router bgp 64516
 vrf Vrf_sense01
  address-family ipv6 unicast
   network 2605:d9c0:6:2655::/64
  neighbor fc00:0:504:4000:0:0:0:2
   remote-as 65000
   no shutdown
   address-family ipv6 unicast
     activate
     route-map sense-eb95dea88c650f9564357b952959e48d-mapin in
     route-map sense-eb95dea88c650f9564357b952959e48d-mapout out
ipv6 prefix-list sense-eb95dea88c650f9564357b952959e48d-from permit 2001:48d0:3001:11c::/64
ipv6 prefix-list sense-eb95dea88c650f9564357b952959e48d-to permit 2605:d9c0:6:2655::/64

# BGP Delete
no route-map sense-eb95dea88c650f9564357b952959e48d-mapin
no route-map sense-eb95dea88c650f9564357b952959e48d-mapout

router bgp 64516
 vrf Vrf_sense01
  address-family ipv6 unicast
   no network 2605:d9c0:6:2655::/64
  no neighbor fc00:0:504:4000:0:0:0:2
no ipv6 prefix-list sense-eb95dea88c650f9564357b952959e48d-from
no ipv6 prefix-list sense-eb95dea88c650f9564357b952959e48d-to
```

* **BGP Multipath** allows SiteRM to install multiple routes to the same destination to be used simultaneously and use paths for load balancing and redundancy. There is no special configuration and SiteRM reuses same VLAN and BGP Creation (and create multiple vlans, route-maps, prefix-list and multiple bgp peers.)

* **QoS** allows to control Quality of Service on the network devices. 
The default configuration specifies the following parameters under Site Switch, which can be overridden:

```json
"qos_policy": {
    "traffic_classes": {
        "default": 1,
        "bestEffort": 2,
        "softCapped": 4,
        "guaranteedCapped": 7
    },
    "max_policy_rate": "268000",
    "burst_size": "256"
}
```

Most devices have certain limitations, like Dell (max 3 rate limits per port) or Arista maximum policy rate. For example:

```bash
    max_policy_rate is the maximum police rate that can be set for a class.
    burst_size is the maximum burst size.
```

SENSE can request one of the following bandwidth types: guaranteedCapped, softCapped, or bestEffort. When SiteRM receives a request, it calculates the bandwidth for all requests based on the following parameters:

* Available port capacity (can be overridden by RM config if the site wants to reserve a certain percentage of bandwidth for other purposes).
* If the request is guaranteedCapped, SiteRM will add the following configuration on the Arista device:

```bash
    policy-map type quality-of-service SENSE_QOS
       class VLAN{VLAN_ID}
          set traffic-class {TRAFFICCLASSGC}
          police rate {GC_REQUEST_BW} mbps burst-size {BURST_SIZE} mbytes
```

* After all guaranteedCapped allocations are configured, SiteRM calculates the remaining bandwidth:

```bash
{NewRemainingCapacity} = {AvailablePortCapacity} - {ActiveGuaranteedCapped}
```

* For softCapped, SiteRM will configure:

```bash
   class VLAN{VLAN_ID}
      set traffic-class {TRAFFICCLASSSC}
      police rate {SC_REQUEST_BW} mbps burst-size {BURST_SIZE} mbytes \
         action set drop-precedence rate {NewRemainingCapacity} mbps burst-size {BURST_SIZE} mbytes
```

* For bestEffort, SiteRM will configure (always allowing at least 100 Mbps, up to the maximum remaining capacity):

```bash
   class VLAN{VLAN_ID}
      set traffic-class {TRAFFICCLASSBE}
      police rate 100 mbps burst-size {BURST_SIZE} mbytes \
         action set drop-precedence rate {NewRemainingCapacity} mbps burst-size {BURST_SIZE} mbytes
```

Note: SoftCapped and BestEffort are very similar in that both can reach the maximum remaining capacity of the link (excluding guaranteedCapped request). However, if both compete for bandwidth simultaneously, traffic class prioritization applies (2 vs 4), and BestEffort has lower priority than SoftCapped.