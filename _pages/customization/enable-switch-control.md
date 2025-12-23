---
title: "Enable Switch Control"
layout: single
classes: wide
permalink: "/customization/enable-switch-control/"
author_profile: false
sidebar:
  nav: "docs"
---

## Allow Switch control for SENSE

Each switch for SENSE to control, must be added to Sites configuration Frontend `main.yaml` file. Few important notes:

* Define all switch names under Site -> switch. (Name must match same name defined inside the ansible configuration)
* If LLDP is enabled on the switches - you do not need to make individual links (isAlias) between them. isAlias in most cases mainly needed for pointer to Network Resource manager STP.
   **NOTE: isAlias is needed for PortChannels and LAGs.**
* if allports flag set to True - it will include all switch ports, except the ones listed inside the `ports_ignore` list under Frontend `main.yaml` file.
* if allports flag set to False - it will only include ports listed inside `ports` list under Frontend `main.yaml` file.
* Each port can override any additional parameters via configuration file `main.yaml`. For example, to override allowed `vlan_range` per port:

```yaml
"Ethernet 1/1/30":
  vlan_range: [3985-3989,3610,3611,3612]
```

Please refer to [Frontend Configuration parameters](/customization/configuration-frontend/) for more options. More examples are available in the [Github repo](https://github.com/sdn-sense/rm-configs)

## Configuration for ansible control

**IMPORTANT: Do not upload ansible configuration file to any public repos.**

Notes:

* If you installed Site-RM using siterm-startup git repo - you need to prepare `fe/conf/etc/ansible-conf.yaml`. Based on your device(s) - look for examples below.
* Ansible can be configured to use SSH-Password and SSH-PrivKey authentication. Documentation below explains both methods.
* **Switch defined inside the Ansible inventory file will not be represented in topology - unless it is explicitly mentioned inside the configuration for Site [here](https://github.com/sdn-sense/rm-configs)**
* **IMPORTANT** If your network device accepts only SSH via IPv6 (and Site-RM install uses docker) - docker is known to have issues with IPv6. Please use "-n host" for frontend container startup.
* **IMPORTANT** Ports in SENSE control on the network device, must be in trunk mode and not use access vlan. Use native vlan for traffic without vlan tag.
* **IMPORTANT** Cisco NX OS9 and Arista EOS devices require to have empty list of allowed vlans (or any other vlans not controlled by SENSE). Please make sure SENSE controlled ports have `switchport trunk allowed vlan <none|or any other non sense controlled vlans>` parameter.
* **IMPORTANT** If you use Dell OS9 and `rate_limit: True` - Dell OS 9 allows maximum 3 rate limits per port. If you have more than 3 rate limits per port - you will get an error. Please make sure to remove rate limits which are not needed. SENSE does not limit of how many rate limits can be set on the port.
* **IMPORTANT** If you use Arista EOS devices, max_policy_rate is 268Gbps. Please confirm this on the device before enabling rate_limit flag.

## General ansible configuration template file

```yaml
inventory:
  dellos9_s0: # This name must match same name inside Site configuration main.yaml file
    network_os: <NETWORK_OS_BASED_ON_MODEL_SEE_BELOW>
    host: 192.168.1.1 # Change this to IP of the device
    # One of two (pass or sshkey) must be defined. Defining both or none with result in failure.
    user: <Change to user which will be used to access device>
    pass: <Change To password if using password. Remove if using sshkey>
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

## Plugin configuration options

### Network OS Selection

* Dell OS 9 - `sense.dellos9.dellos9`
* Dell OS 10 - `sense.dellos10.dellos10`
* Azure SONiC - `sense.sonic.sonic`
* Arista EOS - `sense.aristaeos.aristaeos`
* Juniper Junos - `sense.junos.junos`
* FreeRTR - `sense.freertr.freertr`
* Cisco Nexus 9 - `sense.cisconx9.cisconx9`
* Cisco Nexus 10 - `sense.cisconx9.cisconx9`
* FRRouting (FRR) - `sense.frr.frr`
* FRRouting (FRR+VPP) - `sense.frr.frr`

### How to use SSH Keys (Docker SiteRM Frontend Installation)

To configure Site-RM to use ssh keys to access device, you need put ssh keys in this directory `fe/conf/opt/siterm/config/ssh-keys/`. (if you use `siterm-startup` scripts for docker/podman instalation).
For example, if you put a key with name `fe/conf/opt/siterm/config/ssh-keys/id-rsa-sense`, then in siterm to use that key, modify `fe/conf/etc/ansible-conf.yaml` and set `sshkey` parameter to: `/opt/siterm/config/ssh-keys/id-rsa-sense`.
Be aware that key is put in path: `fe/conf/opt/siterm/config/ssh-keys/id-rsa-sense`, but for `siterm-startup` mounts this directory `fe/conf/opt/` under `/opt` inside container.

### How to use SSH Keys (Kubernetes SiteRM Frontend Installation)

TODOTODO

### How to enable SNMP

Site-RM uses easysnmp library to query devices. Site-RM support following parameters under `session_vars`. All parameters can be found [here](https://easysnmp.readthedocs.io/en/latest/session_api.html). Here are few examples below:

* SNMPv1:

```yaml
snmp_params:
  session_vars:
    community: public
    hostname: 123.123.123.123
    version: 1
```

* SNMPv2c:

```yaml
snmp_params:
  session_vars:
    community: public
    hostname: 123.123.123.123
    version: 2
```

* SNMPv3:

```yaml
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


### Examples

TODO