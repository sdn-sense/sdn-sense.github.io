---
title: "Quick Installation Introduction"
layout: single
classes: wide
permalink: "/install-quick-start/"
author_profile: false
sidebar:
  nav: "docs"
---

Before deploying SiteRM, please consult with the SENSE team to ensure orchestration needs, policy, and security requirements: **sense-info@es.net**

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

* Configuration preparation
* Frontend Installation
* Agent Installation
* Debugger Installation
* Node Exporter Installation
* Host and Switch configuration tunings


## Quick installation notes for new sites

### Configuration preparation

- Fork Github Configuration repo under your own username: [sdn-sense/rm-configs](https://github.com/sdn-sense/rm-configs/fork)
- Once forked, clone repository to your computer:

```bash
GIT_USERNAME=<REPLACE_ME_TO_GIT_USERNAME>
git clone https://github.com/${GIT_USERNAME}/rm-configs
```

- Create new site directory, based on provided templates:

```bash
SITENAME="T3_US_ExampleSite" # Replace sitename to T<1|2|3>_<COUNTRY_CODE>_<SITENAME>
cd rm-configs
mkdir $SITENAME
cp -R SITE_TEMPLATES/* $SITENAME/
```

- Decide where you will run Frontend. Frontend can run anywhere (on the same nodes as Agents) or have an individual Node/VM/Kubernetes container. You need to know the FQDN Hostname Frontend will be deployed on. For steps below, we will use `sense-site.sdn-sense.dev` hostname.

```bash
SENSE_FQDN="sense-site.sdn-sense.dev"
```

- Modify `mappings.yaml` file inside the new Sitename directory:
  - Change md5 for Frontend to the output of `md5sum -n "{SENSE_FQDN}"`
  - Change maintainer to either person's FirstName LastName, or email address for administrators;

- Modify `FE/main.yaml` file inside the new Sitename directory:
  - Change all `T0_XX_REPLACEME` with your SITENAME, same as your directory name;
  - Change `REPLACE_ME_WEB_DOMAIN` to URL where the Frontend will be running. For example, based on the steps above, it should be: `"https://sense-site.sdn-sense.dev:443"`;
  - Change `REPLACE_ME_DOMAIN_NAME` to your sites top level domain name. Based on the steps above, it should be: `sdn-sense.dev`
  - Update `latitude` and `longitude` for your Site location.

- Get certificate for your host. Preferrable to use any official Certificate Authority (CA) certificate, like:
  - Incommon IGTF: See OSG Documentation for requesting certificates: [link](https://osg-htc.org/docs/security/host-certs/incommon/)
  - Let's Encrypt: See Let's Encrypt documentation: [link](https://letsencrypt.org/getting-started/)
  - Other: Please follow the procedure provided by your Certificate Authority. Be aware, that SiteRM only supports certificates that are trusted by OSG Certificate Authority Distribution. More details: [link](https://osg-htc.org/security/CaDistribution/)

- Once you received certificate, execute the following command to get compat certificate DN information:

```bash
CERT_PATH=/etc/grid-security/hostcert.pem
openssl x509 -in ${CERT_PATH} -noout -issuer -subject -nameopt compat
#issuer=/C=US/O=Let's Encrypt/CN=R13
#subject=/CN=sense-site.sdn-sense.dev
```

- Open `FE/auth.yaml` file inside the your Sitename directory and add new entry, based on openssl command output:

```yaml
siterm_frontend:
  # full_dn: "<value_of_openssl_issuer><value_of_opennsl_subject>"
  full_dn: "/C=US/O=Let's Encrypt/CN=R13/CN=sense-site.sdn-sense.dev"
  permissions: w
```

- Push all configuration changes to Github repo. With this, we are ready to install SiteRM Frontend

### SiteRM Frontend Installation