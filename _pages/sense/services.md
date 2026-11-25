---
title: "SENSE services and use cases"
summary: "The network services SENSE provisions, and the science communities and infrastructure projects that use them."
description: "SENSE network services and use cases: Layer 2 and Layer 3 services, the Priority Network Service for LHC data, and AmSC resource orchestration."
layout: single
classes: wide
permalink: "/services/"
author_profile: false
sidebar:
  nav: "docs"
---

## Network services

| Service | What it provides |
|---|---|
| Layer 2 point-to-point with DTN attachment | A point-to-point connection with Data Transfer Nodes (DTNs) attached at both ends. |
| Layer 2 multipoint with DTN attachment | One Layer 2 broadcast domain with several attachment points. DTNs can attach in multiple locations, and VLANs at the edge are the service demarcation point. |
| Layer 3 VPN with DTN attachment | Attaches DTNs, other systems, or specific traffic flows to an existing Layer 3 VPN for a period the user requests. It can be one part of a larger multi-domain service. |
| Site L3 over P2P VLAN | Joins site IPv6 routing to a traffic-engineered Layer 2 path across the wide area. Sites keep their IP routing and add a few IPv6 addresses to DTN dataplane interfaces, so Layer 2 does not have to reach the DTN cluster. |

The [service request guide]({{ '/blog/sense-network-service-examples/' | relative_url }}) has diagrams and JSON for the request patterns that clients use today.

### Bandwidth classes

A service can be best effort, soft capped, or hard capped. Best effort is enough in many cases and is expected to be the most common request. Enforcement depends on the capabilities and policy of every domain on the path. [Quality of Service]({{ '/operational/quality-of-service/' | relative_url }}) describes what SiteRM does at a site.

## Priority Network Service

The SENSE Priority Network Service is an IPv6 shortcut-routing service between two sites. SENSE builds a Layer 2 path at each site and joins them across the wide area with an ESnet OSCARS circuit. SiteRM then manages private BGP routing over that circuit, so only the IPv6 subnets chosen for the transfer use it.

Site storage clusters see a routed Layer 3 service, and the segment that crosses ESnet is Layer 2. SENSE presents Layer 3 to users and uses Layer 2 where traffic engineering needs it. OSCARS is currently the only ESnet option for traffic-engineered paths with guaranteed bandwidth, so the service uses it. The design can adopt other ESnet services if they become available.

When the service ends or fails, traffic returns to the default routed path.

## Use cases

| Aspect | Priority Network Service | AmSC resource orchestration |
|---|---|---|
| Status | Operational, with production deployments | Design and prototype stage |
| Resources orchestrated | Network | Compute, data, and network |
| Community | LHC CMS and ATLAS, through Rucio | American Science Cloud and IRI facilities |
| Role of SENSE | The service itself | Foundation for AmSC-IRO |
| Main abstraction | A priority network service instance over OSCARS | A FacilitySpace, managed as a SENSE service instance |

### Rucio Priority Data Transfer Service

Rucio uses the Priority Network Service to give authorized CMS and ATLAS users priority for a replication rule, which may cover a few files or many thousands. Rucio says which transfers matter most. SENSE answers whether the path can be provided, based on what every domain along it permits.

The work is a collaboration among ESnet, UCSD/SDSC, Fermilab, Caltech, the Open Science Grid, CMS, ATLAS, several LHC Tier 2 sites, and the teams that develop and run Rucio, FTS, XRootD, and dCache. The service runs on production infrastructure at several US-CMS and US-ATLAS sites. ESnet's [High Energy Physics Network Requirements Review](https://www.es.net/assets/Uploads/20251001-HEP-RR-Final.pdf) (October 2025, section 6.11.2.7.3.5) records plans by both experiments to extend the SENSE/Rucio integration to all of their Tier 2 sites.

Talks on this work are in the [SENSE Blog]({{ '/blog/' | relative_url }}), including the [productization roadmap]({{ '/blog/rucio-sense-productization-2026/' | relative_url }}) and the [ATLAS integration]({{ '/blog/atlas-sense-rucio-priority-transfers-chep-2026/' | relative_url }}).

### AmSC resource orchestration

In the American Science Cloud (AmSC), resource orchestration is the layer that provisions compute, data, and network resources across different infrastructures. Its orchestration core, the AmSC Infrastructure Resource Orchestrator (AmSC-IRO), is designed on the SENSE Orchestrator framework:

| AmSC-IRO function | SENSE component |
|---|---|
| Resource catalog | Information model and metadata service |
| Service orchestration | Orchestration core |
| Policy management | SENSE SSO |
| Inter-facility API | Intent-based northbound REST API |

The two use cases meet in data management. The orchestrator first sets up the data plane, which can include SENSE Layer 2 or Layer 3 circuits, and then sends the task to a workload agent.

The [AmSC-IRO / SENSE-O user manual](https://amsc-iro-docs-c88e53.gitlab.io/user-manual/index.html) and [API reference](https://amsc-iro-docs-c88e53.gitlab.io/api-reference/index.html) are public.

### Other science integrations

Earlier SENSE work includes DTN priority flows, streaming from the LCLS online cache to SLAC data transfer nodes for ExaFEL, BigData Express, and WAN path selection from user requirements. The [SENSE project site](https://sense.es.net/sense-services-and-use-cases) describes these.

## What SENSE adds

- Alternative paths: two facilities usually have several routes between them and use one. SENSE can provision a path over less congested, higher-bandwidth, or special-purpose links, including one member link of an ECMP aggregate.
- Guaranteed bandwidth: per-flow QoS lets a workflow operator choose which transfers matter most and plan them alongside compute and storage.
- Observability: a more deterministic path makes it easier to measure site resources and find where a problem is.

SENSE works alongside ECMP, L3VPN, link aggregation, and overprovisioning. Those improve network use for all flows together. SENSE adds control of individual flows, changed in real time by workflows or network operators. The [FAQ]({{ '/faq/' | relative_url }}) covers how these interact.
