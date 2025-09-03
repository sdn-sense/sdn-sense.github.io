<!-- markdownlint-disable MD024 -->
[[Home](index.md)] [[Installation Information](Installation.md)] [[Docker Install](DockerInstallation.md)] [[Kubernetes Install](KubernetesInstallation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)] [[Debuggging](Debugging.md)][[QOS](QoS.md)]

# Debugging SiteRM Issues

If you encounter failures or issues with SiteRM, this guide provides debugging steps and potential fixes.

## SiteRM Frontend

SiteRM provides a few ways to monitor your endpoints. Each SiteRM Frontend runs Frontend Web UI. You can identify Web UI URL from Git configuration, for example, here is for Caltech: [FE-Config.yaml](https://github.com/sdn-sense/rm-configs/blob/master/T2_US_Caltech/FE/main.yaml#L5).

To access SiteRM Frontend, you need to have your Certificate DN Whitelisted or OIDC Authentication Service credentials. 

- (This is currently default) In case of certificate, access permissions are controlled in Github repository for FE: [Fe-Auth.yaml](https://github.com/sdn-sense/rm-configs/blob/master/T2_US_Caltech/FE/auth.yaml)
- In case of OIDC, please contact your OIDC Issuer and administrator to create you an account or provide permissions.

![Alt text](documentation/SiteRM-FE.png?raw=true "SiteRM Frontend UI")

SiteRM Frontend Web UI provides a way to monitor Site in real-time, track it's status, connectivity, health of overall system at any given site. Key features:

- Topology - Displays the current network topology, that includes all known switches, servers, enabled pors, WAN connections.
- Frontend Configuration - Displays current runtime configuration for Frontend and any registered agents. In case of config update, or node removal, this page provides a way to reload configuration (force SiteRM to read new configuration from Github) or delete host.
- ServiceStates - Show information about each Service running at the site and it's status.
- Models - View and show latest site Models in MRML, Turtle, Json-ld format. This is a format that represents Sites topology back to SENSE Orchestrator.
- Deltas - View and track state of all Deltas. Deltas are the submission by SENSE Orchestrator to make changes at the Site, e.g. Create vlan, remove vlan, set ip, etc...
- Active Requests - Shows SENSE Active requests in Json format.
- Debugging tools - Allow to request new debug action, like Ping, Traceroute, Arp, Ethr, FDT, Iperf3 tests.
- Change Active Start/End - Allows to change SENSE Active resource request start/end time. Useful if need to drain site and or some resources were not deleted correctly.

On the Top Right, Web-UI shows System status, by providing brief status overview of Alive,Ready,Readiness,Liveness. Additionally, it provides a link to a Swagger documentation for ALL APIs supported by SiteRM.

## Autogole monitoring and Slack alerts

SENSE team maintains an Autogole monitoring, where each Site has a dedicated dashboard and automated Slack alerts for Site issues. You can find all Sites, and each site status information here: [Autogole monitoring](https://autogole-grafana.nrp-nautilus.io). This webpage requires either Github Authentication (send your gihtub username to SENSE team) or SENSE-O account.

![Alt text](documentation/Autogole-mon.png?raw=true "Autogole Monitoring for T2_US_SDSC")

Some of the errors are described below, but not all. We continue to improve the documentation and expand explanation of error and potential fixes.

---

## Kubernetes install issues

### Error Message

```text
Error: INSTALLATION FAILED: create: failed to create: Request entity too large: limit is 3145728
```

### Cause

This error occurs when the size of the Helm chart or the generated Kubernetes resources exceeds the default size limit set by the Kubernetes API server or ingress controllers.

### Resolution

Use `helm template ... | kubectl apply -f` command and not `helm install`.
OR Use `helm template ... &> deployment.yaml && kubectl apply -f deployment.yaml`

## Docker Startup Failure (Frontend)

### Error Message

```text
ERROR: Configuration file ../conf/etc/ansible-conf.yaml was not modified. SiteRM Will fail to start.
```

### Cause

This occurs when the configuration file has not been modified. Even if your Frontend RM runs in raw switch mode, this file still needs to be modified, although it may not be used.

### Resolution

Ensure the correct information is added to the `ansible-conf.yaml` file. Refer to the documentation for proper configuration:
[NetControl Ansible Documentation](https://sdn-sense.github.io/NetControlAnsible.html).

---

## PluginException: Interface Not Found

### Error Message

```text
SiteRMLibs.CustomExceptions.PluginException: Interface enp1s0np0 was not found on the system. Misconfiguration
```

### Cause

The specified interface is not present on the system, but it is configured in the [sdn-sense/rm-configs](https://github.com/sdn-sense/rm-configs) configuration file.

### Resolution

1. Verify whether the interface exists on the system.
2. If the interface is missing, check for kernel updates that may have renamed the interface.
3. If a new interface name is required, update the configuration file and submit a pull request to [rm-configs](https://github.com/sdn-sense/rm-configs).

---

## Interface Down

### Error Message

```text
Interface {interface} is not up. Check why interface is down.
```

### Cause

The interface under SENSE control is currently down.

### Resolution

Investigate the cause of the interface being down and take appropriate action to bring it back up.

---

## Oversubscription Warning

### Error Message

```text
Interface {key} has no remaining reservable capacity! Over subscribed?
```

### Cause

The node is oversubscribed due to too many requests.

### Resolution

This is a warning. No new path requests can be provisioned on the affected node. Consider reducing load or increasing capacity.

---

## VLAN Range Not Defined

### Error Message

```text
Interface {key} has no vlan range list defined!
```

### Cause

A configured interface does not have a VLAN range defined.

### Resolution

Ensure the VLAN range is properly set in the configuration file.

---

## No Remaining VLANs

### Error Message

```text
No remaining vlans in vlan range list for interface {key}. All used?
```

### Cause

All VLANs in the range are currently in use.

### Resolution

This is a warning. No new requests can be processed until VLANs are freed up.

---

## Port Not Added to Model

### Error Message

```text
SiteRMLibs.CustomExceptions.ServiceWarning: Warning. Port aristaeos_s0Ethernet23/1 not added into model. Its status not switchport. Ansible runner returned: {'bandwidth': 100000, 'duplex': 'duplexFull', 'lineprotocol': 'notPresent', 'macaddress': '44:4c:a8:55:2d:3c', 'mtu': 9214, 'operstatus': 'notconnect'}.
```

### Cause

The port is missing the `switchport: true` flag.

### Resolution

1. The port may have gone down. Check the status.
2. The port may not have a switchport trunk defined. Refer to the device documentation for the correct configuration.

---

## VLAN Manually Configured

### Error Message

```text
Vlan {vlan} is configured manually on {host}. It comes not from delta. Either deletion did not happen or was manually configured.
```

### Cause

A VLAN allocated as part of the SENSE range is manually configured on the system.

### Resolution

1. **HOST**: If manually configured, delete it using the following command:

   ```bash
   ip link delete vlan.XXXX
   ```

2. **SWITCH**: If manually configured, delete vlan on the network device.

3. There might be cases, where SiteRM failed to delete or cancel the resource, check:
   - For **host**, check the following log file inside agent container: `/var/log/siterm-agent/Ruler/api.log`
   - For **switch**, check the following log file inside agent container: `/var/log/siterm-site-fe/{LookUpService,ProvisioningService}/api.log`

---

## Errors in `isAlias` or Switch Port Configuration

### Error Messages

```text
Interface {key} already has isAlias in git config (and we get it from Kube Labels. Which one is right?
Interface {key} already has switch port in git config (and we get it from Kube Labels. Which one is right?
Interface {key} already has switch in git config (and we get it from Kube Labels. Which one is right?
Interface {key} not found in Host. Either interface does not exist or NetInfo Plugin failed.
Interface {key} has no switch defined, nor was available from Kube (in case Kube install)!
Interface {key} has no switch port defined, nor was available from Kube (in case Kube install)!
```

### Cause

A misconfiguration in Agent settings, possibly due to missing port configuration or conflicts between Kubernetes labels and the git configuration.

### Resolution

Refer to the documentation for proper mapping of ports to resolve the issue.

---

## SiteRM Ansible Debugger and Cleaner

The `siterm-ansible-runner` script inside the SiteRM-FE container provides debugging and cleaning options.

### Usage

```text
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

### Notes

- The `exceptactive` option is safe.
- The `onlyactive` and `all` options are **dangerous**—use with caution.
- Always validate configurations before applying changes.

---

## Autogole Warning State

### Error Messages

Autogole monitoring shows a warning state for a Service.

### Cause

SiteRM executes multiple validation actions, and there might be many reasons for a warning. Please take a look at your Frontend Service states page, that will give a more detailed error message

### Resolution

Detailed error message is available on Site's Frotend Service states page.

---

## Autogole Critical Errors

### Error Messages

Autogole monitoring shows a critical error.

### Cause

SiteRM executes multiple validation actions, and some errors are considered critical, like: Node down and agent not running, Disk/CPU/Memory overloaded, or many of the errors above (interface down, wrong link port, etc...)

### Resolution

Look at Current active alerts/warnings graph and identify alert state. Autogole monitoring also provides 'SiteRM Component Status (NOT OK)' graph, that status of the Component over time.

---