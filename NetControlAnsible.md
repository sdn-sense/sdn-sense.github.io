[[Home](index.md)]   [[Installation](Installation.md)]  [[Network Control via Ansible](NetControlAnsible.md)]

# Information

Site resource manager supports the following switches and control:

| Switch OS    | Visualization in MRML | VLAN Creation | VLAN Translation | VLAN IPv46 Assignment | BGP Control | Comments |
| :--: | :---: | :---: | :---: | :---: | :---: | :---: |
| RAW           | 1 | 0 | 0 | 0 | 0 | RAW Plugin (Fake switch, no control on hardware) |
| Dell OS 9     | 1 | 1 | 0 | 1 | 1 | Full Control using [Dell OS9 Ansible Collection](https://github.com/sdn-sense/sense-dellos9-collection) |
| Dell OS 10    | 1 | 1 | 0 | 0 | 0 | Work in progress to support BGP using [Dell OS10 Ansible Collection](https://github.com/sdn-sense/sense-dellos10-collection) |
| Azure SONiC   | 1 | 1 | 0 | 1 | 1 | Full Control sing ssh and [custom build python script](https://github.com/sdn-sense/siterm-startup/blob/main/fe/conf/opt/siterm/config/ansible/sense/project/scripts/sonic.py) Rewriting to Ansible Collection |
| Arista EOS    | 1 | 1 | 0 | 1 | 0 | Full contronl [Arista EOS Ansible Collection](https://github.com/sdn-sense/sense-aristaeos-collection)|
| Juniper Junos | 1 | 0 | 0 | 0 | 0 | Work in progress using cloned [Juniper Ansible Collection](https://github.com/sdn-sense/junipernetworks.junos)|
| FreeRTR       | 1 | 0 | 0 | 0 | 0 | Work in progress using custom build [FreeRTR Ansible Collection](https://github.com/sdn-sense/sense-freertr-collection) |
| Cisco Nexus   | 1 | 0 | 0 | 0 | 0 | Work in progress using custom build [TO BE UPDATED] |

# Configuration layout directory

Ansible inventory, configuration and template files are available here: https://github.com/sdn-sense/siterm-startup/tree/main/fe/conf/opt/siterm/config/ansible/sense

Few notes:
1. If you installed SiteRM using siterm-startup git repo - docker startup already mounts local directory.
2. Ansible can be configured to SSH-Pass and SSH-PrivKey authentication. Documentation below provides examples for SSH-Pass. Please consult ansible documentation for more options: https://docs.ansible.com/ansible/latest/user_guide/connection_details.html
3. Kubernetes containers will not have siterm-startup. At first runtime - please clone the repository and apply all the necessary changes.
4. Currently - SiteRM cant' mix Ansible and RAW plugins. (In near future - it will allow to use separate plugin based on switch, e.g.: Ansible,netconf,raw)
5. **Switch defined inside the Ansible inventory file will not be represented in topology - unless it is explicitly mentioned inside the configuration for Site here: https://github.com/sdn-sense/rm-configs. Please refer to (Allow Switch control for SENSE)**

# RAW Switch plugin configuration

This is dummy switch only for modelling. It has no real hardware to control. Configuration is only defined in https://github.com/sdn-sense/rm-configs repo. Configuration example:
```
T2_US_UH_GOREX:
  domain: hawaii.edu
  latitude: 21.2971
  longitude: -157.8171
  plugin: raw
  privatedir: /opt/siterm/config/T2_US_UH_GOREX/
  year: 2022
  switch:
    - "s0"
s0:
  vsw: "s0"
  ports:
    - "1_1"
    - "1_2"
    - "1_3"
  vlan_range: [3605-3609]
  port_1_1_capacity: 100
  port_1_1_desttype: switch
  port_1_1_isAlias: "urn:ogf:network:uhnet.net:2021:hawaii-scidmz:uhmanoa-dtn"
  port_1_1_vlan_range: [3605-3609]
  port_1_2_capacity: 100
  port_1_2_vlan_range: [3605-3609]
  port_1_3_capacity: 100
  port_1_3_vlan_range: [3605-3609]
```

# Dell OS 9 plugin configuration

1. Modify `inventory/inventory.yaml` file and add switch information:
```
dellos9:
  hosts:
    dellos9_s0:
      ansible_host: 192.168.1.1
```
You can add more than one, like this:
```
dellos9:
  hosts:
    dellos9_s0:
      ansible_host: 192.168.1.1
    dellos9_s1:
      ansible_host: 192.168.1.2
    dellos9_s2:
      ansible_host: 192.168.1.3
```
2. For each host defined inside the `inventory/inventory.yaml` file - create host configuration file at `inventory/host_vars/<host_from_inventory>.yaml` (like `inventory/host_vars/dellos9_s0.yaml`):
```
ansible_become: false
ansible_network_os: dellos9
ansible_ssh_pass: MySuperDuperPassword
ansible_user: MySuperDuperUsername
hostname: dellos9_s0
```
For additional Dell OS9 Ansible parameters, look here: https://docs.ansible.com/ansible/latest/network/user_guide/platform_dellos9.html

# Dell OS 10 plugin configuration

**This plugin is not yet available for general use. It is on development phase**

1. Modify `inventory/inventory.yaml` file and add switch information:
```
dellos10:
  hosts:
    dellos10_s0:
      ansible_host: 192.168.1.1
```
You can add more than one, like this:
```
dellos10:
  hosts:
    dellos10_s0:
      ansible_host: 192.168.1.1
    dellos10_s1:
      ansible_host: 192.168.1.2
    dellos10_s2:
      ansible_host: 192.168.1.3
```
2. For each host defined inside the `inventory/inventory.yaml` file - create host configuration file at `inventory/host_vars/<host_from_inventory>.yaml` (like `inventory/host_vars/dellos10_s0.yaml`):
```
ansible_become: false
ansible_network_os: dellos10
ansible_ssh_pass: MySuperDuperPassword
ansible_user: MySuperDuperUsername
hostname: dellos9_s0
```
For additional Dell OS10 Ansible parameters, look here: https://docs.ansible.com/ansible/latest/network/user_guide/platform_dellos10.html

# Azure SONiC plugin configuration

SENSE uses SSH and custom python script to communicate with Azure SONiC devices. There is no official Azure SONiC Ansible module/collection. [custom build python script](https://github.com/sdn-sense/siterm-startup/blob/main/fe/conf/opt/siterm/config/ansible/sense/project/scripts/sonic.py)

1. Modify `inventory/inventory.yaml` file and add switch information:
```
sonic:
  hosts:
    sn3700_s0:
      ansible_host: 192.168.1.1
```
You can add more than one, like this:
```
sonic:
  hosts:
    sn3700_s0:
      ansible_host: 192.168.1.1
    sn3700_s1:
      ansible_host: 192.168.1.2
    sn3700_s2:
      ansible_host: 192.168.1.3
```
2. For each host defined inside the `inventory/inventory.yaml` file - create host configuration file at `inventory/host_vars/<host_from_inventory>.yaml` (like `inventory/host_vars/sn3700_s0.yaml`):
```
ansible_become: true
ansible_network_os: sonic
ansible_user: sense
hostname: sn3700_s0
```
For additional SSH Ansible parameters, look here: [https://docs.ansible.com/ansible/latest/network/user_guide/platform_dellos10.html](https://docs.ansible.com/ansible/6/collections/ansible/builtin/ssh_connection.html#ssh-connection)

# Arista EOS plugin configuration

1. Modify `inventory/inventory.yaml` file and add switch information:
```
aristaeos:
  hosts:
    aristaeos_s0:
      ansible_host: 192.168.1.1
```
You can add more than one, like this:
```
aristaeos:
  hosts:
    aristaeos_s0:
      ansible_host: 192.168.1.1
    aristaeos_s1:
      ansible_host: 192.168.1.2
    aristaeos_s2:
      ansible_host: 192.168.1.3
```
2. For each host defined inside the `inventory/inventory.yaml` file - create host configuration file at `inventory/host_vars/<host_from_inventory>.yaml` (like `inventory/host_vars/aristaeos_s0.yaml`):
```
ansible_become: true
ansible_become_method: enable
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: arista.eos.eos
ansible_ssh_pass: MySuperDuperPassword
ansible_user: MySuperDuperUsername
hostname: aristaeos_s0
```
For additional Arista EOS Ansible parameters, look here: https://docs.ansible.com/ansible/latest/collections/arista/eos/index.html

# Juniper Junos plugin configuration
**This plugin is not yet available for general use. It is on development phase**

SENSE uses modified Juniper Junos collection. Modification is to allow control switch with Jinja templates (same as most other switches). In near future SENSE will support Netconf - which is the default for Juniper devices. 
Ansible collection repo: https://github.com/sdn-sense/junipernetworks.junos
Modification allow modify via Jinja: https://github.com/sdn-sense/junipernetworks.junos/commit/c0665f4755428cd3f8454ccf1f25dbe27574a04d

1. Modify `inventory/inventory.yaml` file and add switch information:
```
junos:
  hosts:
    ex4550_s0:
      ansible_host: 192.168.1.1
```
You can add more than one, like this:
```
junos:
  hosts:
    ex4550_s0:
      ansible_host: 192.168.1.1
    ex4550_s1:
      ansible_host: 192.168.1.2
    ex4550_s2:
      ansible_host: 192.168.1.3
```
2. For each host defined inside the `inventory/inventory.yaml` file - create host configuration file at `inventory/host_vars/<host_from_inventory>.yaml` (like `inventory/host_vars/ex4550_s0.yaml`):
```
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: junipernetworks.junos.junos
ansible_ssh_pass: MySuperDuperPassword
ansible_user: MySuperDuperUsername
hostname: ex4550_s0
```
For additional Juniper Junos Ansible parameters, look here: https://docs.ansible.com/ansible/latest/collections/junipernetworks/junos/index.html

# FreeRTR plugin configuration
**This plugin is not yet available for general use. It is on development phase**


SENSE uses modified Custom build FreeRTR Ansible collection. Ansible module location is here: https://github.com/sdn-sense/rare-freertr-collection

1. Modify `inventory/inventory.yaml` file and add switch information:
```
freertr:
  hosts:
    freertr_s0:
      ansible_host: 192.168.1.1
      ansible_user: rare
```
You can add more than one, like this:
```
freertr:
  hosts:
    freertr_s0:
      ansible_host: 192.168.1.1
    freertr_s1:
      ansible_host: 192.168.1.2
    freertr_s2:
      ansible_host: 192.168.1.3
```
2. For each host defined inside the `inventory/inventory.yaml` file - create host configuration file at `inventory/host_vars/<host_from_inventory>.yaml` (like `inventory/host_vars/freertr_s0.yaml`):
```
ansible_become: false
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: rare.freertr.freertr
ansible_ssh_pass: MySuperDuperPassword
ansible_user: MySuperDuperUsername
hostname: freertr_s0
```
For additional FreeRTR Ansible parameters, look here: https://github.com/sdn-sense/rare-freertr-collection

# Allow Switch control for SENSE

Each switch which we want to allow SENSE to control, must be added to Site's configuration. Few important notes:
1. Define all switch names under Site -> switch. (Name must match same name defined inside the ansible configuration)
2. If LLDP is enabled on switches - you do not need to make individual links (isAlias) between them. isAlias in most cases mainly needed for pointer to Network Resource manager STP.
3. vsw - Virtual Switching - to allow vlan creation;
4. rst - Routing Service - to allow configure BGP (private_asn number is mandatory to define if rst is defined).
5. if allports flag set to True - it will include allPorts, excepts the ones listed inside the ports_ignore list.
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


