---
title: "Useful Links"
layout: single
classes: wide
permalink: "/docs/useful-links/"
author_profile: false
sidebar:
  nav: "docs"
---

## SENSE Project

| Resource | URL |
|---|---|
| SENSE Project Home (ESnet) | [https://www.es.net/research-and-initiatives/sense/](https://www.es.net/research-and-initiatives/sense/) |
| SENSE Orchestrator (Production) | [https://sense-o.es.net](https://sense-o.es.net) |
| SENSE Orchestrator (Development) | [https://sense-o-dev.es.net](https://sense-o-dev.es.net) |
| SENSE Monitoring Dashboard | [https://autogole-grafana.nrp-nautilus.io](https://autogole-grafana.nrp-nautilus.io) |
| SENSE Email Contact | sense-info@es.net |

---

## SiteRM Code Repositories

| Repository | Description | URL |
|---|---|---|
| siterm | Main SiteRM Frontend and Agent source code | [https://github.com/sdn-sense/siterm](https://github.com/sdn-sense/siterm) |
| siterm-startup | Docker/Kubernetes startup scripts and configuration templates | [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup) |
| helm-charts | Kubernetes Helm charts for SiteRM deployment | [https://github.com/sdn-sense/helm-charts](https://github.com/sdn-sense/helm-charts) |
| rm-configs | Example site configuration files | [https://github.com/sdn-sense/rm-configs](https://github.com/sdn-sense/rm-configs) |
| vpp-frr | VPP + FRR software router reference implementation | [https://github.com/sdn-sense/vpp-frr](https://github.com/sdn-sense/vpp-frr) |
| sdn-sense.github.io | This documentation site | [https://github.com/sdn-sense/sdn-sense.github.io](https://github.com/sdn-sense/sdn-sense.github.io) |

---

## Ansible Collections

| Collection | Network OS | URL |
|---|---|---|
| sense-dellos9-collection | Dell OS 9 | [https://github.com/sdn-sense/sense-dellos9-collection](https://github.com/sdn-sense/sense-dellos9-collection) |
| sense-dellos10-collection | Dell OS 10 | [https://github.com/sdn-sense/sense-dellos10-collection](https://github.com/sdn-sense/sense-dellos10-collection) |
| sense-aristaeos-collection | Arista EOS | [https://github.com/sdn-sense/sense-aristaeos-collection](https://github.com/sdn-sense/sense-aristaeos-collection) |
| sense-sonic-collection | Azure SONiC | [https://github.com/sdn-sense/sense-sonic-collection](https://github.com/sdn-sense/sense-sonic-collection) |
| sense-junos-collection | Juniper Junos | [https://github.com/sdn-sense/sense-junos-collection](https://github.com/sdn-sense/sense-junos-collection) |
| sense-cisconx9-collection | Cisco Nexus 9/10 | [https://github.com/sdn-sense/sense-cisconx9-collection](https://github.com/sdn-sense/sense-cisconx9-collection) |
| sense-frr-collection | FRRouting (FRR) | [https://github.com/sdn-sense/sense-frr-collection](https://github.com/sdn-sense/sense-frr-collection) |
| sense-freertr-collection | FreeRTR | [https://github.com/sdn-sense/sense-freertr-collection](https://github.com/sdn-sense/sense-freertr-collection) |
| sense-nokiasros-collection | Nokia SR-OS | [https://github.com/sdn-sense/sense-nokiasros-collection](https://github.com/sdn-sense/sense-nokiasros-collection) |

---

## Docker Hub Images

| Image | Description | URL |
|---|---|---|
| siterm-fe | SiteRM Frontend container | [https://hub.docker.com/r/sdnsense/siterm-fe](https://hub.docker.com/r/sdnsense/siterm-fe) |
| siterm-agent | SiteRM Agent container (EL8/EL9/EL10/U22) | [https://hub.docker.com/r/sdnsense/siterm-agent](https://hub.docker.com/r/sdnsense/siterm-agent) |
| siterm-debugger | SiteRM Debugger container | [https://hub.docker.com/r/sdnsense/siterm-debugger](https://hub.docker.com/r/sdnsense/siterm-debugger) |

---

## External Tools Used by SiteRM

| Tool | Purpose | URL |
|---|---|---|
| FireHol FireQOS | Host-level QoS (HTB/TC rules) | [https://firehol.org/](https://firehol.org/) |
| FRRouting (FRR) | Software-based BGP router | [https://frrouting.org/](https://frrouting.org/) |
| VPP (fd.io) | High-performance DPDK data plane | [https://fd.io/](https://fd.io/) |
| Prometheus SNMP Exporter | Network device metrics for Prometheus | [https://github.com/prometheus/snmp_exporter](https://github.com/prometheus/snmp_exporter) |
| easysnmp | Python SNMP library used internally | [https://easysnmp.readthedocs.io/](https://easysnmp.readthedocs.io/) |
| SQLAlchemy | ORM for SiteRM database | [https://www.sqlalchemy.org/](https://www.sqlalchemy.org/) |
| FastAPI | REST API framework for SiteRM Frontend | [https://fastapi.tiangolo.com/](https://fastapi.tiangolo.com/) |
| Alembic | Database schema migrations | [https://alembic.sqlalchemy.org/](https://alembic.sqlalchemy.org/) |
| RDFLib | RDF/N3 network topology representation | [https://rdflib.readthedocs.io/](https://rdflib.readthedocs.io/) |

---

## Network Devices — Vendor Documentation

| Vendor/OS | Documentation |
|---|---|
| Dell OS 9 | [Dell EMC Networking OS9 CLI Reference](https://www.dell.com/support/manuals/en-us/dell-emc-os-9) |
| Dell OS 10 | [Dell EMC SmartFabric OS10 Documentation](https://www.dell.com/support/manuals/en-us/dell-emc-os-10) |
| Azure SONiC | [SONiC Documentation](https://sonic-net.github.io/SONiC/) |
| Arista EOS | [Arista EOS User Manual](https://arista.my.site.com/AristaCommunity/s/EOS-documentation) |
| Juniper Junos | [Junos OS Documentation](https://www.juniper.net/documentation/product/en_US/junos-os) |
| Cisco NX-OS | [Cisco Nexus NX-OS Documentation](https://www.cisco.com/c/en/us/support/ios-nx-os-software/nx-os-software.html) |
| FRRouting | [FRR Documentation](https://docs.frrouting.org/) |
| FreeRTR | [FreeRTR Documentation](http://www.freertr.org/) |

---

## Kubernetes and Helm

| Resource | URL |
|---|---|
| SiteRM Helm Chart Repository | [https://sdn-sense.github.io/helm-charts](https://sdn-sense.github.io/helm-charts) |
| Helm Documentation | [https://helm.sh/docs/](https://helm.sh/docs/) |
| Kubernetes Documentation | [https://kubernetes.io/docs/](https://kubernetes.io/docs/) |
| cert-manager | [https://cert-manager.io/docs/](https://cert-manager.io/docs/) |

---

## Research Network Infrastructure

| Resource | URL |
|---|---|
| ESnet (Energy Sciences Network) | [https://www.es.net/](https://www.es.net/) |
| Internet2 | [https://internet2.edu/](https://internet2.edu/) |
| FABRIC Testbed | [https://fabric-testbed.net/](https://fabric-testbed.net/) |
| NRP (National Research Platform) | [https://nationalresearchplatform.org/](https://nationalresearchplatform.org/) |
| WLCG (Worldwide LHC Computing Grid) | [https://wlcg.web.cern.ch/](https://wlcg.web.cern.ch/) |
| OSG (Open Science Grid) | [https://osg-htc.org/](https://osg-htc.org/) |

---

## Standards and RFCs

| Standard | Description | Link |
|---|---|---|
| RFC 2474 | Definition of the DSCP Field | [https://datatracker.ietf.org/doc/html/rfc2474](https://datatracker.ietf.org/doc/html/rfc2474) |
| RFC 3246 | Expedited Forwarding PHB | [https://datatracker.ietf.org/doc/html/rfc3246](https://datatracker.ietf.org/doc/html/rfc3246) |
| NML (Network Markup Language) | RDF schema for network topology | [https://www.ogf.org/documents/GFD.206.pdf](https://www.ogf.org/documents/GFD.206.pdf) |
| MRML (Multi-Resource Markup Language) | SENSE network model schema | [https://github.com/esnet/sense-rm](https://github.com/esnet/sense-rm) |
