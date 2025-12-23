---
title: "Agent Configuration"
layout: single
classes: wide
permalink: "/customization/configuration-agent/"
author_profile: false
sidebar:
  nav: "docs"
---

## Intro

As higlighted in [Directory layour](/customization/configuration-layout/) page, Agent support only one configuration file inside the configuration directory:

* main.yaml - Main configuration file for Agent;

File must exist in the Agent directory. Directory layout will be:

```bash
└── T3_US_SITENAME
    ├── Agent01 (directory)
    │   └── main.yaml (file)
    ├── FE (directory)
    └── mapping.yaml (file)
```

Below you will find details for configuration parameters and available options.

## Agent Configuration (`Agent01/main.yaml`)

### `MAIN.general`

| Key | Required | Default | Description |
| --- | --- | --- | --- |
| `ip` | Yes | - | IP of the host. This is used as unique identifier for an Agent during registration to the frontend |
| `sitename`  | Yes | - | Sitename in format of `T<level>_<country_2_letter>_<facility_name>`. It must match Sitename configured for Frontend |
| `webdomain` | Yes | - | Frontend full HTTP URL. |
| `logDir` | No | `/var/log/siterm-agent/` | Directory for Agent logs. |
| `logLevel` | No | `INFO` | Logging verbosity (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`). |
| `privatedir` | No | `/opt/siterm/config/` | Base directory for runtime artifacts. |
| `node_exporter` | No | - | Node exporter hostname:port. See [Node Exporter Installation](/main-install/node-exporter/) |

---

### `MAIN.agent`

| Key | Required | Default | Description |
| --- | --- | --- | --- |
| `interfaces` | Yes | - | List of all interfaces for SENSE to control |
| `hostname` | Yes | - | Full qualified hostname |

---

### `MAIN.<PORT_NAME>`

All interfaces listed under `MAIN.agent.interfaces` require to have configuration for each port. Port configuration parameters:

| Key | Required | Default | Description |
| --- | --- | --- | --- |
| `switch` | Yes | - | Name of the switch the host port is connected to |
| `port` | Yes | - | Name of the switch port the host port is connected to |
| `vlan_range` | Yes | - | VLAN range per interface for SENSE Control. This tells which VLANs are allowed to be created on the interface by SENSE between one or more ports. Supports comma and dash syntax (`100-200,300`). |

### 8.3 `MAIN.qos`

This controls QoS parameters for any SENSE created paths. More detailed QoS behavior defined in [Quality of Service page](/operational/quality-of-service/)

| Key | Required | Default | Description |
| --- | --- | --- | --- |
| `policy` | Yes | - | Which policy to use: hostlevel or privatens. In most cases, use hostlevel, if your Host sees all IPs at the host. In case Private network namespaces used, use privatens. See [Quality of Service page](/operational/quality-of-service/) for more details |
| `qos_params` | No | `mtu 9000 mpu 9000 quantum 200000 burst 300000 cburst 300000 qdisc sfq balanced` | Quality of service parameters. These are tuned for high-throughput transfers, see this for more details: [Quality of Service page](/operational/quality-of-service/) page for more details |
| `interfaces` | Yes | - | list all interfaces that QoS is allowed to be configured. This must include master_intf. In case bridges are used, interface_name and master_intf can be different. SiteRM requires to know which master interface carries the traffic. For more details see [Quality of Service page](/operational/quality-of-service/) |

Example for QoS configuration:

```yaml
qos:
  policy: hostlevel
  qos_params: "mtu 9000 mpu 9000 quantum 200000 burst 300000 cburst 300000 qdisc sfq balanced"
  interfaces:
    ens1f0np0:
      master_intf: ens1f0np0
```
