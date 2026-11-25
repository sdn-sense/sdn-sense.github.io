---
title: "SENSE architecture"
summary: "How one request from a science workflow becomes a network service that crosses many independently operated domains."
description: "SENSE architecture: the orchestrator, resource managers, identity, and monitoring, and how a workflow request becomes a multi-domain network service."
layout: single
classes: wide
permalink: "/architecture/"
author_profile: false
sidebar:
  nav: "docs"
---

SENSE (Software-Defined Network for End-to-end Networked Science at Exascale) is an ESnet-led project that builds service orchestration middleware. Science applications use it to schedule the network the way they already schedule instruments, compute, and storage.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" role="region" aria-label="Scrollable SENSE architecture diagram">
    <img src="{{ '/images/sense-architecture.svg' | relative_url }}" alt="Science workflows call the intent-based API of the SENSE Orchestrator, which works with SENSE SSO and RTMon, runs embedded Resource Managers, and contacts SiteRM at end sites and regional networks to build one end-to-end service" width="1120" height="600">
  </div>
  <figcaption>SENSE components and the domains they coordinate. Domain names are examples; the path for each service is computed from the resources advertised at that time.</figcaption>
</figure>

## Where SENSE fits

Application workflow agents and science middleware know what a workflow needs but have had no way to tell the network. They send data into it and find out at the other end how well it worked. The automation that controls regional networks, WAN backbones, exchange points, and end-site Science DMZs has no view of the workflow. SENSE sits between the two.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" role="region" aria-label="Scrollable diagram of SENSE placement in the research and education ecosystem">
    <img src="{{ '/images/sense-arch.png' | relative_url }}" alt="SENSE between application workflow agents above and the SDN layer below, which spans end sites, regional networks, WANs, and an SDX" width="1280" height="726" loading="lazy">
  </div>
  <figcaption>SENSE placement in the research and education network ecosystem.</figcaption>
</figure>

This placement led to two design choices:

- SENSE adapts to the automation a domain already runs, so no domain has to adopt a particular controller.
- A domain with no automation layer can deploy a SENSE-native Resource Manager and take part.

## Roles

| Role | Responsibility | Scope |
|---|---|---|
| Orchestrator (SENSE-O) | Accepts requests from users and applications, decides which Resource Managers to contact, and coordinates the end-to-end service. | Cross-domain. Orchestrators can be layered into hierarchies. |
| Resource Manager (RM) | Configures and manages local resources, and the services that run on network elements and end systems. | One administrative or technology domain. |

## How a request becomes a service

1. A workflow agent or user describes the service it needs through the intent-based API.
2. SENSE-O interprets the request and works out which Resource Managers have to participate.
3. SENSE-O coordinates those Resource Managers as one end-to-end service.
4. Each domain checks the request against its own policy, and its Resource Manager configures the resources inside that domain.
5. Status, monitoring, and troubleshooting information returns to the application through the same API until the service ends.

## Components

### SENSE Orchestrator (SENSE-O)

SENSE-O holds the end-to-end model, plans services across domains, and manages each service from request to teardown. People use it through a web portal, and workflow agents use its REST API or the [Python client](https://github.com/sdn-sense/sense-o-py-client).

### SENSE SSO

SENSE SSO is the identity component, built on Keycloak. It provides single sign-on with InCommon federated identity, role-based access control, and the service tokens that components use to authenticate to each other.

### Resource Managers

A Resource Manager can run inside the Orchestrator as an embedded driver or as a separate deployment inside the domain it manages. Embedded drivers use the control interface a domain already offers, so that domain deploys nothing extra.

| Embedded driver | Domains |
|---|---|
| NSI | Domains reachable over the Network Service Interface, including ESnet OSCARS and the NSI exchange points |
| AL2S | Internet2 AL2S |
| FABRIC | FABRIC testbed |
| L3VPN | Layer 3 VPN services |
| Cloud | Commercial cloud provider connections |

### Site Resource Manager (SiteRM)

SiteRM is the SENSE-native Resource Manager that runs at a site. It controls top-of-rack switches and data mover servers for VLANs, private BGP, and QoS. Site personnel own and operate it. Most of the documentation on this website covers SiteRM: start with the [SiteRM quick installation]({{ '/install-quick-start/' | relative_url }}) or the list of [supported network devices]({{ '/getting-started/install-supported-network-devices/' | relative_url }}).

### Real-time monitoring (RTMon)

[RTMon](https://github.com/esnet/sense-rtmon) helps troubleshoot one flow across every domain it crosses. It uses the SENSE model to find where the flow runs, collects per-flow metrics through Prometheus exporters at intervals under 30 seconds, and builds a dashboard for that service inside the SENSE-O portal. Routine infrastructure monitoring and long-term history are left to other tools.

## Intent API and the end-to-end model

The northbound API covers resource discovery, negotiation, service lifecycle, and monitoring. Applications state requirements such as endpoints, bandwidth, and schedule. Device configuration stays with the Resource Managers.

Each Resource Manager publishes a model of its infrastructure and services. SENSE-O joins these models into a single SENSE end-to-end model and plans against it. The models are updated as resources change, so planning follows the current state of the infrastructure.

For worked requests, see [SENSE network service requests]({{ '/blog/sense-network-service-examples/' | relative_url }}) and [client recipes for discovery, bandwidth, and scheduling]({{ '/blog/sense-client-discovery-and-scheduling/' | relative_url }}).

## Architectural properties

- Many-to-many: an Orchestrator can work with many Resource Managers, and a Resource Manager can serve many Orchestrators.
- Hierarchical: an Orchestrator can appear as a resource to another Orchestrator above it.
- Domain-scoped: a boundary can be administrative or technological, and each Resource Manager configures only what is inside its own.
- Adaptive: orchestration works with other network and domain automation systems.
- Model-based: services across domains are planned and provisioned from shared models.

## Domains that take part

| Domain type | Examples |
|---|---|
| ESnet | Layer 2 circuits through OSCARS, dynamic L3VPN |
| Peer WANs and testbeds | Internet2 AL2S, FABRIC |
| Regional networks and exchanges | CENIC, Great Plains Network, StarLight |
| Laboratories and computing centers | Fermilab, CERN, SDSC, MGHPCC |
| Universities | Caltech, UC San Diego, University of Chicago, University of Nebraska-Lincoln |

The home page has the current list of [participating sites and network partners]({{ '/#participants' | relative_url }}).

## Read next

- [Services and use cases]({{ '/services/' | relative_url }})
- [Frequently asked questions]({{ '/faq/' | relative_url }})
- [Selected publications]({{ '/docs/publications/' | relative_url }})
