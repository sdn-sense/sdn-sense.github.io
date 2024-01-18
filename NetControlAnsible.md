[[Home](index.md)]   [[Installation](Installation.md)]  [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)]

# Information

Site resource manager supports the following switches and control:

|   Switch OS   | Visualization in MRML | VLAN Creation | VLAN Translation | VLAN IPv46 Assignment | BGP Control |                                                       Comments                                                       |
|:-------------:| :---: | :---: | :---: | :---: | :---: |:--------------------------------------------------------------------------------------------------------------------:|
|      RAW      | 1 | 0 | 0 | 0 | 0 |                 RAW Plugin (Fake switch, no control on hardware. use only if instructed by SENSE Team)               |
|   Dell OS 9   | 1 | 1 | 0 | 1 | 1 |                 [Dell OS9 Ansible Collection](https://github.com/sdn-sense/sense-dellos9-collection)                 |
|  Dell OS 10   | 1 | 1 | 0 | 0 | 0 |                [Dell OS10 Ansible Collection](https://github.com/sdn-sense/sense-dellos10-collection)                |
|  Azure SONiC  | 1 | 1 | 0 | 1 | 1 |                [Azure SONiC Ansible Collection](https://github.com/sdn-sense/sense-sonic-collection)                 |
|  Arista EOS   | 1 | 1 | 0 | 1 | 0 |               [Arista EOS Ansible Collection](https://github.com/sdn-sense/sense-aristaeos-collection)               |
| Juniper Junos | 1 | 0 | 0 | 0 | 0 |                [Juniper Junos Ansible Collection](https://github.com/sdn-sense/junipernetworks.junos)                |
|    FreeRTR    | 1 | 0 | 0 | 0 | 0 |                 [FreeRTR Ansible Collection](https://github.com/sdn-sense/sense-freertr-collection)                  |
| Cisco Nexus 9 | 1 | 1 | 0 | 1 | 1 |              [Cisco Nexus 9 Ansible Collection](https://github.com/sdn-sense/sense-cisconx9-collection)              |

# Allow Switch control for SENSE

Each switch which we want to allow SENSE to control, must be added to Sites configuration [here](https://github.com/sdn-sense/rm-configs). Few important notes:
1. Define all switch names under Site -> switch. (Name must match same name defined inside the ansible configuration)
2. If LLDP is enabled on switches - you do not need to make individual links (isAlias) between them. isAlias in most cases mainly needed for pointer to Network Resource manager STP.
3. vsw - Virtual Switching - to allow vlan creation (Most of the times it is the same as switch name);
4. rst - Routing Service - to allow configure BGP (private_asn number is mandatory to define if rst is defined). **NOTE: There can be only 1 rst defined per site**.
5. if allports flag set to True - it will include allPorts, except the ones listed inside the ports_ignore list.
6. if allports flag set to False - it will only include ports listed inside ports list.
7. Each port can override few parameters via configuration:
```
  port_hundredGigE_1-7_capacity: 100
  port_hundredGigE_1-7_desttype: switch
  port_hundredGigE_1-7_isAlias: "urn:ogf:network:lsanca.pacificwave.net:2016:lax-agg10:ultralight"
  port_hundredGigE_1-7_vlan_range: [1779-1799,3600-3619,3985-3989,3870-3883,3911-3912,3870-3883]
```
Example configuration of 3 switches at one site:
```
--- 
T2_US_Caltech_Test: 
  switch:
    - "dellos9_s0"
    - "aristaeos_s0"
    - "sn3700_s0"
dellos9_s0:
  vsw: "dellos9_s0"
  rst: "dellos9_s0"
  rsts_enabled: "ipv4,ipv6"
  private_asn: 64513
  vrf: lhcone
  ports:
    - "hundredGigE 1/7"
    - "hundredGigE 1/23"
    - "Port-channel 102"
  ports_ignore:
    - "ManagementEthernet 1/1"
    - "hundredGigE 1/8"
    - "hundredGigE 1/9"
  vlan_range: [1779-1799,3600-3619,3985-3989,3870-3883,3911-3912,3870-3883]
  port_hundredGigE_1-7_capacity: 100
  port_hundredGigE_1-7_desttype: switch
  port_hundredGigE_1-7_isAlias: "urn:ogf:network:lsanca.pacificwave.net:2016:lax-agg10:ultralight"
  port_hundredGigE_1-7_vlan_range: [1779-1799,3600-3619,3985-3989,3870-3883,3911-3912,3870-3883]
  port_Port-channel_103_capacity: 200
  port_Port-channel_103_vlan_range: [1779-1799,3600-3619,3985-3989,3870-3883,3911-3912,3870-3883]
  port_Port-channel_103_capacity: 300
  port_Port-channel_103_desttype: switch
  port_Port-channel_103_isAlias: "urn:ogf:network:ultralight.org:2013:aristaeos_s0:Port-Channel111"
aristaeos_s0:
   vsw: "aristaeos_s0"
   allports: True
   ports_ignore:
    - "Ethernet15/1"
    - "Ethernet16/1"
    - "Ethernet31/1"
    - "Ethernet32/1"
   vlan_range: [1779-1799,3600-3619,3985-3989,3870-3883,3911-3912,3870-3883]
   port_Port-Channel111_capacity: 200
   port_Port-Channel111_desttype: switch
   port_Port-Channel111_isAlias: "urn:ogf:network:ultralight.org:2013:dellos9_s0:Port-channel_103"
   port_Port-Channel112_capacity: 200
   port_Port-Channel112_desttype: switch
   port_Port-Channel112_isAlias: "urn:ogf:network:sc-test.cenic.net:2020:aristaeos_s0:Port-Channel501"
   port_Port-Channel112_vlan_range: [1779-1799,3600-3619,3985-3989,3870-3883,3911-3912,3870-3883]
sn3700_s0:
   vsw: "sn3700_s0"
   allports: True
   vlan_range: [1779-1799,3600-3619,3985-3989,3870-3883,3911-3912,3870-3883]
   port_Port-channel_103_isAlias: "urn:ogf:network:sc-test.cenic.net:2020:aristaeos_s0:Port-Channel501"
```

# Configuration layout directory

Ansible inventory, configuration and template file examples are available [here](https://github.com/sdn-sense/ansible-templates)

Few notes:
1. If you installed Site-RM using siterm-startup git repo - you need to prepare `fe/conf/etc/ansible-conf.yaml`. Based on your device(s) - look for examples below.
2. Ansible can be configured to use SSH-Password and SSH-PrivKey authentication. Documentation below explains both methods.
3. Currently - SiteRM cant mix Ansible and RAW plugins. (In near future - it will allow to use separate plugin based on switch, e.g.: Ansible,netconf,raw)
4. **Switch defined inside the Ansible inventory file will not be represented in topology - unless it is explicitly mentioned inside the configuration for Site [here](https://github.com/sdn-sense/rm-configs)**
5. **IMPORTANT** If your network device accepts only SSH via IPv6 (and Site-RM install uses docker) - docker is known to have issues with IPv6. Please use "-n host" for frontend container startup.
6. **IMPORTANT** Ports in SENSE control on the network device, must be in trunk mode and not use access vlan. Use native vlan for traffic without vlan tag.
7. **IMPORTANT** Cisco NX OS9 and Arista EOS devices require to have empty list of allowed vlans (or any other vlans not controlled by SENSE). Please make sure SENSE controlled ports have `switchport trunk allowed vlan <none|or any other non sense controlled vlans>` parameter.

# General ansible configuration template file
```
inventory:
  dellos9_s0: # This name must match same name inside Site configuration [here](https://github.com/sdn-sense/rm-configs)
    network_os: <NETWORK_OS_BASED_ON_MODEL_SEE_BELOW>
    host: 192.168.1.1 # Change this to IP of the device
    # One of two (pass or sshkey) must be defined. Defining both or none with result in failure.
    pass: <Change To pass if using password. Remove if using sshkey>
    sshkey: <Change to ssh key path, if using sshkey. See Section 'How to use SSH Keys' on path location. Remove if using pass>
    become: <true|false|0|1> # Change it to true or false if it is required to use become feature on your network device.
    snmp_params:
      session_vars:
        # See 'How to enable SNMP' section for supported parameters
        community: <SNMP COMMUNITY>
        hostname: <SNMP HOSTNAME>
        <ANY_OTHER_SNMP_METADATA_PARAMS>
```

# RAW plugin configuration

In case you use RAW (fake virtual switch) plugin - you do not need to modify `fe/conf/etc/ansible-conf.yaml` file. Make an inventory variable empty dictionary. Like this:
```angular2html
inventory: {}
```

# Dell OS 9 plugin configuration

1. If you device is Dell OS 9, for network_os make sure to set `sense.dellos9.dellos9`

# Dell OS 10 plugin configuration

1. If you device is Dell OS 10, for network_os make sure to set `sense.dellos10.dellos10`

# Azure SONiC plugin configuration

1. If you device is Azure SONiC, for network_os make sure to set `sense.sonic.sonic`

# Arista EOS plugin configuration

1. If you device is Arista EOS, for network_os make sure to set `sense.aristaeos.aristaeos`

# Juniper Junos plugin configuration

**THIS IS NOT SUPPORTED YET**

1. If you device is Juniper Junos , for network_os make sure to set `sense.junos.junos`

# FreeRTR plugin configuration

1. If you device is FreeRTR, for network_os make sure to set `sense.freertr.freertr`

# Cisco Nexus 9 plugin configuration

1. If you device is Cisco Nexus 9, for network_os make sure to set `sense.cisconx9.cisconx9`

# RAW Switch plugin configuration

**NOTE: This plugin is not very useful for L3/BGP Control. Only Sites instructed by SENSE Team should use this.**

This is dummy switch only for modelling. It has no real hardware to control. Configuration is only defined in https://github.com/sdn-sense/rm-configs repo and it does not require `fe/conf/etc/ansible-conf.yaml` file modification.

# How to use SSH Keys
To configure Site-RM to use ssh keys to access device, you need to put all ssh keys in this directory `fe/conf/opt/siterm/config/ssh-keys/`. (if you use siterm-startup scripts).
For example, if you put a key with name `fe/conf/opt/siterm/config/ssh-keys/id-rsa-sense`, then in siterm to use that key, modify `fe/conf/etc/ansible-conf.yaml` and set `sshkey` parameter to: `/opt/siterm/config/ssh-keys/id-rsa-sense`.
Be aware that key is put in path: `fe/conf/opt/siterm/config/ssh-keys/id-rsa-sense`, but for SiteRM config you use `/opt/...`. Docker will mount this directory `fe/conf/opt/` under `/opt` inside container.

# How to enable SNMP
Site-RM uses easysnmp library to query devices and their usage. Site-RM support those parameters under `session_vars```. All parameters can be found [here](https://easysnmp.readthedocs.io/en/latest/session_api.html). Here are few examples below:

1. SNMPv1:
```
    snmp_params:
      session_vars:
        community: public
        hostname: 123.123.123.123
        version: 1
```

2. SNMPv2c:
```
    snmp_params:
      session_vars:
        community: public
        hostname: 123.123.123.123
        version: 2
```

3. SNMPv3: To be defined
