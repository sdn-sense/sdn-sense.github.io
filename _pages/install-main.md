---
title: "Quick Start Introduction"
layout: single
classes: wide
permalink: "/install-quick-start/"
author_profile: false
sidebar:
  nav: "docs"
---

Before deploying SiteRM, please consult with the SENSE team to ensure orchestration needs, policy, and security requirements: **sense-all@googlegroups.com**

A SiteRM deployment consists of three services:

## Frontend

The **SiteRM Frontend** is the control and coordination endpoint for a site. It is responsible for:

- Communication with SENSE Orchestrator(s)
- Accepting and validating requested deltas (state changes)
- Preparing the site resource model
- Coordinating LAN-level switch control and BGP Control
- Aggregating configuration and state from all DTNs and Agents

**At least one Frontend is required per administrative domain.**

---

## Agent

The **SiteRM Agent** runs on each DTN or host that SiteRM monitors or controls. It is responsible for:

- Gathering DTN and host-level information
- Creating and managing VLAN interfaces
- Applying QoS and traffic control policies
- Reporting telemetry and state to the Frontend

---

## Debugger

The **SiteRM Debugger** provides active diagnostics and probing capabilities. The Debugger typically runs alongside the Agent on each DTN or host. It is responsible for tests like:

- iPerf tests
- FDT tests
- Ping probes
- Traceroute probes

## Configuration files

- In most cases, SiteRM Frontend and Agent configuration files are stored in a central GitHub repository [here](https://github.com/sdn-sense/rm-configs/). If required, you can store this on your own repository.
- Each service periodically pulls the latest configuration from remote repository (default: once per hour)
- Configuration changes are picked up automatically

Notes:

- Frontend and Agent use their own configuration files
- The Debugger does not require a separate configuration file

---

## Firewall Requirements

The Frontend requires connectivity to the following services listed below. Access may be restricted to specific nodes.

- **Production Orchestrator**
  - `sense-o.es.net` (ports 8080, 8443)
- **Development Orchestrator**
  - `sense-o-dev.es.net` (ports 8080, 8443)
- **SENSE Monitoring and Alarming**
  - `k8s-igrok-0[1–6].calit2.optiputer.net`
  - IP range: `67.58.51.132–67.58.51.137`
  - Ports: 8080, 8443, 9100
- **Local Agents**
  - All deployed Agents must be able to reach the Frontend

## Installation Methods

SiteRM supports the following installation methods:

- Kubernetes (via Helm)
- Docker

While each site hardware and network topology is different. Proceed to component-specific documentation for detailed configuration files, installation steps, examples, and operational details. Start with:

* Frontend Installation
* Agent Installation
* Debugger Installation
* Node Exporter Installation
* Host and Switch configuration tunings