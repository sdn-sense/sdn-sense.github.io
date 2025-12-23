---
title: "SiteRM Operations"
layout: single
classes: wide
permalink: "/operational/siterm-operations/"
author_profile: false
sidebar:
  nav: "docs"
---

## Operations information

SiteRM Frontend runs an httpd server and servers html website. You can access it via https://<hostname_of_fe>:<port_of_fe>. It is the same url as defined inside SiteRM configuration general->webdomain.

Frontend allows you to view and interact with SiteRM, e.g.:

* View topology
* View Frontend and Agent Configurations;
* Reload Configuration for frontend or Agent
* Delete host from SiteRM Frontend;
* View state of all Services running (on FE and Agents)
* View latest models and deltas;
* Request and view debug action's, like rapid ping, tcpdump, arptable, iperf.

Additionally, all SiteRMs are monitored by Prometheus and Grafana under AUTOGOLE. It can alert you once services are failing or if there are any issues with your SiteRM. It can be accessed here: [URL](https://autogole-grafana.nrp-nautilus.io) (Requires github or SENSE authentication - please contact SENSE team to add your git username). Slack Alerts are also sent by Grafana once failure, fix occurs.
Please join Slack Workspace ["Autogole Alarms"](https://autogolealarms.slack.com) Please join at least the channel for your domain, and address problems identified in the alerts as soon as possible. This is a free version of Slack, so messages only visible for last 90 days

Channel Organizations:

* one channel for each Site-RM Domain
* one channel for each NSI Domain
* channel for all_nsi_endpoints
* channel for all_siterm_endpoints

## Configuration reload

SiteRM by default reloads configuration **every hour** if there is a configuration change.
SiteRM Frontend and Agent can be reloade manually via Frontend. This is useful when you want to apply new configuration to Frontend or Agent faster than the cycle of automated refresh.
This can be done under **Frontend Configuration** section on the WEB UI.

## Delete host from SiteRM Frontend

SiteRM Frontend allows you to delete host from SiteRM Frontend. This is useful when you want to remove host from SiteRM Frontend, but keep it in the network. This can be done under **Frontend Configuration** section on the WEB UI.

## Frontend CLI Commands

**All commands must be executed inside the Frontend container**

## Command siterm-fe-helper

**siterm-fe-helper** - An interactive helper utility for inspecting and managing SiteRM resources from the Frontend container. All commands below are expected to be executed **inside the SiteRM Frontend container shell**.

```bash
siterm-fe-helper
--------------------------------------------------
Available commands:
--------------------------------------------------
print-help        : Print all available commands
print-active      : Print all active resources in SiteRM.
print-hosts       : Print all hosts information in Frontend
change-delta      : Change Delta State
cancel-resource   : Cancel resource in SiteRM.
cancel-all        : Cancel all active resources in SiteRM.
exit              : Exit helper script.
--------------------------------------------------
Which command you want to execute?
```

* **print-help** Displays all available helper commands.
* **print-active** Lists all currently active SiteRM resources.
* **print-hosts** Shows host-related information known to the Frontend.
* **change-delta**  Modifies the internal delta state (Used to force re-apply).
* **cancel-resource** Cancels a specific active resource in SiteRM.
* **cancel-all** Cancels *all* active resources in SiteRM.
* **exit** Exits the helper interface.

## Command siterm-ansible-runner

**siterm-ansible-runner** command inside the SiteRM FE container provides a way to run Ansible manually and print full output, configuration, clean switch, or run in full debug mode and see full Ansible output.

```bash
siterm-ansible-runner -h
usage: siterm-ansible-runner [-h] [--printports] [--dumpconfig] [--cleanswitch {exceptactive,onlyactive,all}] [--autoapply] [--fulldebug]

SENSE Ansible test runner

optional arguments:
  -h, --help            show this help message and exit
  --printports          Run ansible and print ports for rm-configs.
  --dumpconfig          Run ansible and dump configuration received from ansible.
  --cleanswitch {exceptactive,onlyactive,all}
                        Run ansible to clean switch with specified option: 'exceptactive', 'onlyactive', or 'all'.It will not execute on the device, just print the
                        commands. Default is None.IMPORTANT:While exceptactive is safe to run, onlyactive and all are dangerous and execute only if you know what you are
                        doing.exceptactive - clean all vlans except active ones/provisioned by SENSE.onlyactive - clean all vlans provisioned by SENSE.all - clean all
                        vlans.
  --autoapply           auto apply the configuration to the switch. Only for 'cleanswitch' option.
  --fulldebug           Run ansible with full debug output.
```

---

## Frontend and Agent CLI commands

**All commands must be executed inside the Frontend container**

## Liveness check `siterm-liveness`

Kubernetes **liveness probe** checker with an option to enable/disable controls. Used by Kubernetes to determine whether the container should be restarted. If disabled, Kubernetes will not restart container if any liveness checks fail.

```bash
siterm-liveness [OPTIONS]
-h, --help       Show help message and exit
--enable         Enable the liveness check
--disable        Disable the liveness check
--ignorelock     Ignore the liveness lock file and run all checks
                 (useful for debugging failing services)
```

## Readiness check `siterm-readiness`

Kubernetes **readiness probe** checker with runtime enable/disable controls. Controls whether Kubernetes considers the service *ready to receive traffic*. If disabled, Kubernetes will not restart container if any readiness checks fail.

```bash
siterm-readiness [OPTIONS]
-h, --help       Show help message and exit
--enable         Enable the readiness check
--disable        Disable the readiness check
--ignorelock     Ignore the readiness lock file and run all checks
                 (useful for debugging failing service)
```

## Log Archiver for Developers `siterm-log-archiver`

Utility command to create a compressed archive of SiteRM logs for support

```bash
siterm-log-archiver
```

The script checks for log directories in the following order and archives all of them:

1. `/var/log/siterm-agent/`
2. `/var/log/siterm-site-fe/`
3. `/var/log/httpd/`

Finally, creates a `tar.gz` archive of SiteRM logs and stores it in `/tmp/log-YYMMDD.tar.gz`.

## Network devices debugging

In case you want to debug and see all actions performed on your network devices, you can use the following commands:

* Enter your FE docker/Kubernetes pod container and go to this directory `cd /opt/siterm/config/ansible/sense`
* Run `python3 test-runner.py` to see all actions performed on your network devices (this runs in a full debug mode, and can be very verbose)

## In case of issue with a Service

* Look at the logs of the service. You can access logs via `/var/log/siterm-site-fe/<Service>/api.log` or `/var/log/siterm-site-agent/<Service>/api.log`
* In case of unknown issue, please create a ticket [here](https://github.com/sdn-sense/siterm)
* We might ask you to provide us with the full logs of the service. You can do this by running `siterm-log-archiver` on the host where the service is running. This will create a tarball with all logs of the service. Please provide us with this tarball privately (DO NOT UPLOAD TARBALL TO GITHUB)

## Host cleaner

In case you want to remove all configurations from the host, you can use the following command:

* Enter your FE docker/Kubernetes pod container and run the following command: `siterm-agent-cleaner`. It will print all commands to clean all SENSE configurations on the host. Script will not execute any commands, it will only print them.

## Monitoring inside Autogole

All SiteRMs are monitored by Prometheus and Grafana under AUTOGOLE. It can alert you once services are failing or if there are any issues with your SiteRM. It can be accessed here: [URL](https://autogole-grafana.nrp-nautilus.io) (Requires github or SENSE-O authentication - please contact SENSE team to add your git username). Slack Alerts are also sent by Grafana once failure, fix occurs.
In case of a new FE or Agent, please contact SENSE team to add it to the monitoring system. Admin with full privileges [URL](https://github.com/sdn-sense/autogole-monitoring) can force resync of the monitoring endpoints and push it prometheus.

![alt]({{ site.url }}{{ site.baseurl }}/images/Autogole-mon.png "Autogole monitoring view")

### Custom Monitorings

In case you want to add custom monitoring, please contact SENSE team. We can add custom monitoring to the monitoring system as needed. For example, right now there are few additional tools:

* NSI SNMPMonitor - monitors NSI Domains. This includes ESnet Startdust wrapper, Internet2 OESS wrapper, CENIC SNMP. This can be expanded to other network providers;
* XrootD Node Exporter - SiteRM monitors node level endpoint, but sometimes for pods you might want to monitor xrootd service. This is done by adding node exporter in your xrootd pod and updating configuration.
* All custom configs are added manually here: [URL](https://github.com/sdn-sense/autogole-monitoring/blob/main/scripts/default-prometheus-config.yml)
