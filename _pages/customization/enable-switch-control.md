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

To configure SSH key access to network devices when running SiteRM Frontend on Kubernetes, store the SSH private key as a Kubernetes Secret and mount it into the Frontend pod.

**Step 1 — Create a Kubernetes Secret with the SSH key:**

```bash
kubectl create secret generic siterm-ssh-keys \
  --from-file=id-rsa-sense=/path/to/your/id_rsa_sense \
  -n sense
```

**Step 2 — Reference the secret in your Helm `values.yaml`:**

```yaml
# In siterm-fe/values.yaml
extraVolumes:
  - name: ssh-keys
    secret:
      secretName: siterm-ssh-keys
      defaultMode: 0400

extraVolumeMounts:
  - name: ssh-keys
    mountPath: /opt/siterm/config/ssh-keys
    readOnly: true
```

**Step 3 — Set the `sshkey` path in `ansible-conf.yaml`:**

```yaml
inventory:
  my_switch:
    network_os: sense.dellos10.dellos10
    host: 192.168.1.1
    user: admin
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
```

The key is mounted at `/opt/siterm/config/ssh-keys/id-rsa-sense` inside the Frontend pod, matching the path used in Docker deployments.

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

Below are complete `ansible-conf.yaml` examples for each supported network OS.

**Dell OS 9 (SNMPv2c + SSH password):**

```yaml
inventory:
  dellos9_s0:
    network_os: sense.dellos9.dellos9
    host: 10.0.1.10
    user: admin
    pass: mysecretpassword
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
    snmp_params:
      session_vars:
        community: public
        hostname: 10.0.1.10
        version: 2
```

**Dell OS 10 (SSH key + SNMPv3):**

```yaml
inventory:
  dellos10_s0:
    network_os: sense.dellos10.dellos10
    host: 10.0.1.11
    user: admin
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
    snmp_params:
      session_vars:
        version: 3
        hostname: 10.0.1.11
        security_level: authPriv
        security_username: snmpuser
        auth_protocol: SHA
        auth_password: authpassword
        privacy_protocol: AES
        privacy_password: privpassword
```

**Azure SONiC (SSH key + SNMPv2c):**

```yaml
inventory:
  sonic_s0:
    network_os: sense.sonic.sonic
    host: 10.0.1.12
    user: admin
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: true
    ssh_common_args: "-o StrictHostKeyChecking=no"
    snmp_params:
      session_vars:
        community: public
        hostname: 10.0.1.12
        version: 2
```

**Arista EOS (SSH key + SNMPv2c):**

```yaml
inventory:
  arista_s0:
    network_os: sense.aristaeos.aristaeos
    host: 10.0.1.13
    user: admin
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
    snmp_params:
      session_vars:
        community: public
        hostname: 10.0.1.13
        version: 2
```

**Juniper Junos (SSH key + SNMPv3):**

```yaml
inventory:
  junos_s0:
    network_os: sense.junos.junos
    host: 10.0.1.14
    user: netadmin
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-junos
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
    snmp_params:
      session_vars:
        version: 3
        hostname: 10.0.1.14
        security_level: authPriv
        security_username: snmpv3user
        auth_protocol: SHA
        auth_password: authpass
        privacy_protocol: AES
        privacy_password: privpass
```

**Cisco NX-OS 9 (SSH password + SNMPv2c):**

```yaml
inventory:
  cisco_s0:
    network_os: sense.cisconx9.cisconx9
    host: 10.0.1.15
    user: admin
    pass: mysecretpassword
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
    snmp_params:
      session_vars:
        community: public
        hostname: 10.0.1.15
        version: 2
```

**FRRouting (FRR) - Software Router (SSH key):**

```yaml
inventory:
  frr_router:
    network_os: sense.frr.frr
    host: 10.0.1.20
    user: ubuntu
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
```

**FreeRTR (SSH password):**

```yaml
inventory:
  freertr_router:
    network_os: sense.freertr.freertr
    host: 10.0.1.21
    user: admin
    pass: mysecretpassword
    become: false
    ssh_common_args: "-o StrictHostKeyChecking=no"
```

**Using a Jump Host (for devices not directly reachable from Frontend):**

```yaml
inventory:
  switch_behind_firewall:
    network_os: sense.dellos10.dellos10
    host: 192.168.100.50
    user: admin
    sshkey: /opt/siterm/config/ssh-keys/id-rsa-sense
    become: false
    ssh_common_args: >-
      -o StrictHostKeyChecking=no
      -o UserKnownHostsFile=/dev/null
      -o ProxyCommand="ssh -W %h:%p -q admin@jump.host.example.net -i /opt/siterm/config/ssh-keys/id-rsa-jumphost"
```

For full configuration repository examples with real-world switch configurations, see the [SiteRM rm-configs repository](https://github.com/sdn-sense/rm-configs).