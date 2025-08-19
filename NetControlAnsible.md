[[Home](index.md)] [[Installation Information](Installation.md)] [[Docker Install](DockerInstallation.md)] [[Kubernetes Install](KubernetesInstallation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)] [[Debuggging](Debugging.md)][[QOS](QoS.md)]

# Information

Site resource manager supports the following switches and control options:

|      Switch OS      | Viz in MRML | VLAN Creation | VLAN Translation | Ping/Traceroute | BGP Control | BGP Multipath |      QoS      |                                          Comments                                          |
|:-------------------:|:-----------:|:-------------:|:----------------:|:---------------:|:-----------:|:-------------:|:-------------:|:------------------------------------------------------------------------------------------:|
|         RAW         |      1      |       0       |        0         |        0        |      0      |       0       |       0       |   RAW Plugin (Fake switch, no control on hardware. use only if instructed by SENSE Team)   |
|      Dell OS 9      |      1      |       1       |        0         |        1        |      1      |       0       |       0       |    [Dell OS9 Ansible Collection](https://github.com/sdn-sense/sense-dellos9-collection)    |
|     Dell OS 10      |      1      |       1       |        0         |        1        |      1      |       1       |       0       |   [Dell OS10 Ansible Collection](https://github.com/sdn-sense/sense-dellos10-collection)   |
|     Azure SONiC     |      1      |       1       |        0         |        1        |      1      |       1       |       0       |   [Azure SONiC Ansible Collection](https://github.com/sdn-sense/sense-sonic-collection)    |
|     Arista EOS      |      1      |       1       |        0         |        1        |      0      |       0       |       1       |  [Arista EOS Ansible Collection](https://github.com/sdn-sense/sense-aristaeos-collection)  |
|    Juniper Junos    |      1      |       1       |        0         |        1        |      1      |       1       |       0       |  [Juniper Junos Ansible Collection](https://github.com/sdn-sense/sense-junos-collection)   |
|       FreeRTR       |      1      |       0       |        0         |        0        |      0      |       0       |       0       |    [FreeRTR Ansible Collection](https://github.com/sdn-sense/sense-freertr-collection)     |
|  Cisco Nexus 9/10   |      1      |       1       |        0         |        1        |      1      |       1       |       0       | [Cisco Nexus 9 Ansible Collection](https://github.com/sdn-sense/sense-cisconx9-collection) |
|   FRRouting (FRR)   |      1      |       1       |        0         |        1        |      1      |       1       |       0       |     [FRRouting Ansible Collection](https://github.com/sdn-sense/sense-frr-collection)      |
| FRRouting (FRR+VPP) |      1      |       1       |        0         |        1        |      1      |       1       |       0       |     [FRRouting Ansible Collection](https://github.com/sdn-sense/sense-frr-collection)      |
|     Mellanox OS     |      0      |       0       |        0         |        0        |      0      |       0       |       0       |                          Development, expected 2025                                        |
|     Nokia SR OS     |      0      |       0       |        0         |        0        |      0      |       0       |       0       |                          Development, expected 2025                                        |

Here is description of each action:

* **Viz in MRML** means that SiteRM is capable to receive configuration from the network device and represent ports im MRML Model. Here is an example what commands SiteRM will execute on the Dell OS 10 device to get all information for visualization. For other devices, take a look at their individual ansible collections.

```angular2html
show running-config
show lldp neighbors detail
show interfaces
show interface port-channel
show system
```

* **VLAN Creation** means that SiteRM is capable to create and delete VLAN on the device. Here is an example of what commands SiteRM will execute on the Dell OS 10 to create or delete SENSE provisioned VLAN. Allowed IP Ranges, MTU, VRF, and allowed ports are controllable per device inside your site git configuration [https://github.com/sdn-sense/rm-configs/](https://github.com/sdn-sense/rm-configs/). For other devices, look at the templates here: [https://github.com/sdn-sense/ansible-templates/tree/master/project/templates](https://github.com/sdn-sense/ansible-templates/tree/master/project/templates)

```angular2html
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

* **Ping/Traceroute** is capable to issue ping or traceroute (only if IP set on a specific created VLAN). Here is an example of what commands SiteRM will execute on the Dell OS 10 to Ping/Traceroute. For other devices, please look at templates here: [https://github.com/sdn-sense/ansible-templates/tree/master/project/templates](https://github.com/sdn-sense/ansible-templates/tree/master/project/templates) ending with `_ping.j2` or `_traceroute.j2`

```angular2html
ping6 vrf Vrf_sense01 fc00:0:504:4000:0:0:0:2 -c 10 -i 5
traceroute vrf Vrf_sense01 fc00:0:504:4000:0:0:0:2
```

* **BGP Control** allows SiteRM and SENSE based on configuration to control BGP on the device. Based on your git configuration, SiteRM will accept advertisements of configured ranges. Git configuration also includes control for BGP ASN Number, Allowed IPv6 ranges, Allowed Private IPv6 ranges, use of vrf and vrf name. Here is an example of Dell OS 10 executed commands and for other devices, please look at templates here: [https://github.com/sdn-sense/ansible-templates/tree/master/project/templates](https://github.com/sdn-sense/ansible-templates/tree/master/project/templates)

```angular2html
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

```angular2html
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

Arista has certain limits. For example:

```angular2html
    max_policy_rate is the maximum police rate that can be set for a class.
    burst_size is the maximum burst size.
```

SENSE can request one of the following bandwidth types: guaranteedCapped, softCapped, or bestEffort. When SiteRM receives a request, it calculates the bandwidth for all requests based on the following parameters:

* Available port capacity (can be overridden by RM config if the site wants to reserve a certain percentage of bandwidth for other purposes).
* If the request is guaranteedCapped, SiteRM will add the following configuration on the Arista device:

```angular2html
    policy-map type quality-of-service SENSE_QOS
       class VLAN{VLAN_ID}
          set traffic-class {TRAFFICCLASSGC}
          police rate {GC_REQUEST_BW} mbps burst-size {BURST_SIZE} mbytes
```

* After all guaranteedCapped allocations are configured, SiteRM calculates the remaining bandwidth:

```angular2html
{NewRemainingCapacity} = {AvailablePortCapacity} - {ActiveGuaranteedCapped}
```

* For softCapped, SiteRM will configure:

```angular2html
   class VLAN{VLAN_ID}
      set traffic-class {TRAFFICCLASSSC}
      police rate {SC_REQUEST_BW} mbps burst-size {BURST_SIZE} mbytes \
         action set drop-precedence rate {NewRemainingCapacity} mbps burst-size {BURST_SIZE} mbytes
```

* For bestEffort, SiteRM will configure (always allowing at least 100 Mbps, up to the maximum remaining capacity):

```angular2html
   class VLAN{VLAN_ID}
      set traffic-class {TRAFFICCLASSBE}
      police rate 100 mbps burst-size {BURST_SIZE} mbytes \
         action set drop-precedence rate {NewRemainingCapacity} mbps burst-size {BURST_SIZE} mbytes
```

Note: SoftCapped and BestEffort are very similar in that both can reach the maximum remaining capacity of the link (excluding guaranteedCapped request). However, if both compete for bandwidth simultaneously, traffic class prioritization applies (2 vs 4), and BestEffort has lower priority than SoftCapped.

# Allow Switch control for SENSE

Each switch which we want to allow SENSE to control, must be added to Sites configuration [here](https://github.com/sdn-sense/rm-configs). Few important notes:

1. Define all switch names under Site -> switch. (Name must match same name defined inside the ansible configuration)
2. If LLDP is enabled on switches - you do not need to make individual links (isAlias) between them. isAlias in most cases mainly needed for pointer to Network Resource manager STP.
   **NOTE: isAlias is needed for PortChannels and LAGs.**
3. vsw - Virtual Switching - to allow vlan creation (Most of the times it is the same as switch name);
4. rst - Routing Service - to allow configure BGP (private_asn number is mandatory to define if rst is defined). **NOTE: There can be only 1 rst defined per site**.
5. if allports flag set to True - it will include allPorts, except the ones listed inside the ports_ignore list.
6. if allports flag set to False - it will only include ports listed inside ports list.
7. Each port can override few parameters via configuration:

```angular2html
"Ethernet 1/1/30":
  vlan_range: [3985-3989,3610,3611,3612]
  desttype: switch
  isAlias: "urn:ogf:network:ultralight.org:2013:dellos9_s0:hundredGigE_1-13"
  wanlink: True
```

Many examples are available [here](https://github.com/sdn-sense/rm-configs)

# Configuration layout directory

Ansible inventory, configuration and template file examples are available [here](https://github.com/sdn-sense/ansible-templates)

Few notes:

1. If you installed Site-RM using siterm-startup git repo - you need to prepare `fe/conf/etc/ansible-conf.yaml`. Based on your device(s) - look for examples below.
2. Ansible can be configured to use SSH-Password and SSH-PrivKey authentication. Documentation below explains both methods.
3. **Switch defined inside the Ansible inventory file will not be represented in topology - unless it is explicitly mentioned inside the configuration for Site [here](https://github.com/sdn-sense/rm-configs)**
4. **IMPORTANT** If your network device accepts only SSH via IPv6 (and Site-RM install uses docker) - docker is known to have issues with IPv6. Please use "-n host" for frontend container startup.
5. **IMPORTANT** Ports in SENSE control on the network device, must be in trunk mode and not use access vlan. Use native vlan for traffic without vlan tag.
6. **IMPORTANT** Cisco NX OS9 and Arista EOS devices require to have empty list of allowed vlans (or any other vlans not controlled by SENSE). Please make sure SENSE controlled ports have `switchport trunk allowed vlan <none|or any other non sense controlled vlans>` parameter.
7. **IMPORTANT** If you use Dell OS9 and `rate_limit: True` - Dell OS 9 allows maximum 3 rate limits per port. If you have more than 3 rate limits per port - you will get an error. Please make sure to remove rate limits which are not needed. SENSE does not limit of how many rate limits can be set on the port.

# General ansible configuration template file

```angular2html
inventory:
  dellos9_s0: # This name must match same name inside Site configuration [here](https://github.com/sdn-sense/rm-configs)
    network_os: <NETWORK_OS_BASED_ON_MODEL_SEE_BELOW>
    host: 192.168.1.1 # Change this to IP of the device
    # One of two (pass or sshkey) must be defined. Defining both or none with result in failure.
    user: <Change to user which will be used to access device>
    pass: <Change To pass if using password. Remove if using sshkey>
    sshkey: <Change to ssh key path, if using sshkey. See Section 'How to use SSH Keys' on path location. Remove if using pass>
    become: <true|false|0|1> # Change it to true or false if it is required to use become feature on your network device.
    ssh_common_args: <Change to ssh common args if needed. For example -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q  username@jump.host.net -i <sshkey>" Will allow to use jump host>
    snmp_params:
      session_vars:
        # See 'How to enable SNMP' section for supported parameters
        community: <SNMP COMMUNITY>
        hostname: <SNMP HOSTNAME>
        <ANY_OTHER_SNMP_METADATA_PARAMS>
```

# Plugin configuration

## RAW plugin configuration

**NOTE: This plugin is not very useful for L2/L3/BGP Control. Only Sites instructed by SENSE Team should use this.**

This is dummy switch only for modelling. It has no real hardware to control. Configuration is only defined in [https://github.com/sdn-sense/rm-configs](https://github.com/sdn-sense/rm-configs) repo and it does not require `fe/conf/etc/ansible-conf.yaml` file modification.

In case you use RAW (fake virtual switch) plugin - you do not need to modify `fe/conf/etc/ansible-conf.yaml` file. Make an inventory variable empty dictionary. Like this:

```angular2html
inventory: {}
```

## Dell OS 9

If you device is Dell OS 9, for network_os make sure to set `sense.dellos9.dellos9`

## Dell OS 10

If you device is Dell OS 10, for network_os make sure to set `sense.dellos10.dellos10`

## Azure SONiC

If you device is Azure SONiC, for network_os make sure to set `sense.sonic.sonic`

## Arista EOS

If you device is Arista EOS, for network_os make sure to set `sense.aristaeos.aristaeos`

## Juniper Junos

If you device is Juniper Junos , for network_os make sure to set `sense.junos.junos`

## FreeRTR

If you device is FreeRTR, for network_os make sure to set `sense.freertr.freertr`

## Cisco Nexus 9

If you device is Cisco Nexus 9, for network_os make sure to set `sense.cisconx9.cisconx9`

## Cisco Nexus 10

If you device is Cisco Nexus 10, for network_os make sure to set `sense.cisconx9.cisconx9`

## FRRouting (FRR)

If you device is FRRouting (FRR), for network_os make sure to set `sense.frr.frr`
For VPP - plugin expects to have vpp container running. In case no vpp container running - it will work as FRR plugin without VPP.

## FRRouting (FRR+VPP)

If you device is FRRouting (FRR+VPP), for network_os make sure to set `sense.frr.frr`
For VPP - plugin expects to have vpp container running. In case no vpp container running - it will work as FRR plugin without VPP.

# How to use SSH Keys

To configure Site-RM to use ssh keys to access device, you need to put all ssh keys in this directory `fe/conf/opt/siterm/config/ssh-keys/`. (if you use siterm-startup scripts).
For example, if you put a key with name `fe/conf/opt/siterm/config/ssh-keys/id-rsa-sense`, then in siterm to use that key, modify `fe/conf/etc/ansible-conf.yaml` and set `sshkey` parameter to: `/opt/siterm/config/ssh-keys/id-rsa-sense`.
Be aware that key is put in path: `fe/conf/opt/siterm/config/ssh-keys/id-rsa-sense`, but for SiteRM config you use `/opt/...`. Docker will mount this directory `fe/conf/opt/` under `/opt` inside container.

# How to enable SNMP

Site-RM uses easysnmp library to query devices and their usage. Site-RM support those parameters under `session_vars```. All parameters can be found [here](https://easysnmp.readthedocs.io/en/latest/session_api.html). Here are few examples below:

1. SNMPv1:

```angular2html
snmp_params:
  session_vars:
    community: public
    hostname: 123.123.123.123
    version: 1
```

1. SNMPv2c:

```angular2html
snmp_params:
  session_vars:
    community: public
    hostname: 123.123.123.123
    version: 2
```

1. SNMPv3:

```angular2html
snmpParams:
  session_vars:
    version: 3
    hostname: <full-qualified-domain-name.com>
    security_level: <auth_with_privacy>
    security_username: <security_username>
    auth_protocol: <auth_protocol, like: SHA, MD5>
    auth_password: <auth_password>
    privacy_protocol: <privacy_protocol, like: DES, AES>
    privacy_password: <privacy_password>
```
