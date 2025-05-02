[[Home](index.md)] [[Installation Information](Installation.md)] [[Docker Install](DockerInstallation.md)] [[Kubernetes Install](KubernetesInstallation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)] [[Debuggging](Debugging.md)]

# Debugging SiteRM Issues

If you encounter failures or issues with SiteRM, this guide provides debugging steps and potential fixes.

---

## Docker Startup Failure (Frontend)

### Error Message:

```
ERROR: Configuration file ../conf/etc/ansible-conf.yaml was not modified. SiteRM Will fail to start.
```

### Cause:

This occurs when the configuration file has not been modified. Even if your Frontend RM runs in raw switch mode, this file still needs to be modified, although it may not be used.

### Resolution:

Ensure the correct information is added to the `ansible-conf.yaml` file. Refer to the documentation for proper configuration:
[NetControl Ansible Documentation](https://sdn-sense.github.io/NetControlAnsible.html).

---

## PluginException: Interface Not Found

### Error Message:

```
SiteRMLibs.CustomExceptions.PluginException: Interface enp1s0np0 was not found on the system. Misconfiguration
```

### Cause:

The specified interface is not present on the system, but it is configured in the [sdn-sense/rm-configs](https://github.com/sdn-sense/rm-configs) configuration file.

### Resolution:

1. Verify whether the interface exists on the system.
2. If the interface is missing, check for kernel updates that may have renamed the interface.
3. If a new interface name is required, update the configuration file and submit a pull request to [rm-configs](https://github.com/sdn-sense/rm-configs).

---

## Interface Down

### Error Message:

```
Interface {interface} is not up. Check why interface is down.
```

### Cause:

The interface under SENSE control is currently down.

### Resolution:

Investigate the cause of the interface being down and take appropriate action to bring it back up.

---

## Oversubscription Warning

### Error Message:

```
Interface {key} has no remaining reservable capacity! Over subscribed?
```

### Cause:

The node is oversubscribed due to too many requests.

### Resolution:

This is a warning. No new path requests can be provisioned on the affected node. Consider reducing load or increasing capacity.

---

## VLAN Range Not Defined

### Error Message:

```
Interface {key} has no vlan range list defined!
```

### Cause:

A configured interface does not have a VLAN range defined.

### Resolution:

Ensure the VLAN range is properly set in the configuration file.

---

## No Remaining VLANs

### Error Message:

```
No remaining vlans in vlan range list for interface {key}. All used?
```

### Cause:

All VLANs in the range are currently in use.

### Resolution:

This is a warning. No new requests can be processed until VLANs are freed up.

---

## Port Not Added to Model

### Error Message:

```
SiteRMLibs.CustomExceptions.ServiceWarning: Warning. Port aristaeos_s0Ethernet23/1 not added into model. Its status not switchport. Ansible runner returned: {'bandwidth': 100000, 'duplex': 'duplexFull', 'lineprotocol': 'notPresent', 'macaddress': '44:4c:a8:55:2d:3c', 'mtu': 9214, 'operstatus': 'notconnect'}.
```

### Cause:

The port is missing the `switchport: true` flag.

### Resolution:

1. The port may have gone down. Check the status.
2. The port may not have a switchport trunk defined. Refer to the device documentation for the correct configuration.

---

## VLAN Manually Configured

### Error Message:

```
Vlan {vlan} is configured manually on {host}. It comes not from delta. Either deletion did not happen or was manually configured.
```

### Cause:

A VLAN allocated as part of the SENSE range is manually configured on the system.

### Resolution:

1. If manually configured, delete it using:
   ```
   ip link delete vlan.XXXX
   ```
2. If SiteRM failed to delete or cancel the resource, check:
   - **Provisioning Service Logs**
   - **Lookup Service Logs**

For host issues, check:

```
/var/log/siterm-agent/Ruler/
```

For network device issues, check:

```
/var/log/siterm-site-fe/{LookUpService,ProvisioningService}
```

---

## Errors in `isAlias` or Switch Port Configuration

### Error Messages:

```
Interface {key} already has isAlias in git config (and we get it from Kube Labels. Which one is right?
Interface {key} already has switch port in git config (and we get it from Kube Labels. Which one is right?
Interface {key} already has switch in git config (and we get it from Kube Labels. Which one is right?
Interface {key} not found in Host. Either interface does not exist or NetInfo Plugin failed.
Interface {key} has no switch defined, nor was available from Kube (in case Kube install)!
Interface {key} has no switch port defined, nor was available from Kube (in case Kube install)!
```

### Cause:

A misconfiguration in Agent settings, possibly due to missing port configuration or conflicts between Kubernetes labels and the git configuration.

### Resolution:

Refer to the documentation for proper mapping of ports to resolve the issue.

---

## SiteRM Ansible Debugger and Cleaner

The `siterm-ansible-runner` script inside the SiteRM-FE container provides debugging and cleaning options.

### Usage:

```
# siterm-ansible-runner -h
usage: siterm-ansible-runner [-h] [--printports] [--dumpconfig] [--cleanswitch {exceptactive,onlyactive,all}] [--autoapply] [--fulldebug]

SENSE Ansible test runner

optional arguments:
  -h, --help            show this help message and exit
  --printports          Run ansible and print ports for rm-configs.
  --dumpconfig          Run ansible and dump configuration received from ansible.
  --cleanswitch {exceptactive,onlyactive,all}
                        Clean switch VLANs:
                        - `exceptactive`: Clean all VLANs except active ones provisioned by SENSE.
                        - `onlyactive`: Clean only VLANs provisioned by SENSE.
                        - `all`: Clean all VLANs (Dangerous!).
  --autoapply           Auto-apply configuration to the switch (for `cleanswitch` only).
  --fulldebug           Run ansible with full debug output.
```

### Notes:

- The `exceptactive` option is safe.
- The `onlyactive` and `all` options are **dangerous**—use with caution.
- Always validate configurations before applying changes.

---
