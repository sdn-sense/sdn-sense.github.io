---
title: "SENSE frequently asked questions"
summary: "Short answers about what SENSE does, how it treats other traffic, and who controls access."
description: "Answers to common questions about SENSE: guaranteed bandwidth, effects on other traffic, access control, service profiles, operations, and support."
layout: single
classes: wide
permalink: "/faq/"
author_profile: false
sidebar:
  nav: "docs"
---

## About SENSE

### What problem does SENSE solve?

Science applications have had to treat the network as opaque. They cannot negotiate performance, find out what to expect, or get status while a transfer runs. SENSE gives them an API to ask for a service, see what is available, and follow the service until it ends.

### What are the main components?

The SENSE Orchestrator (SENSE-O), SENSE SSO for identity, Resource Managers for each domain, and RTMon for real-time monitoring. SiteRM is the Resource Manager that sites deploy. See [SENSE architecture]({{ '/architecture/' | relative_url }}).

### Does a domain have to run SENSE software?

Only if it has no control interface SENSE can use. The Orchestrator has embedded drivers for NSI domains such as ESnet OSCARS, Internet2 AL2S, FABRIC, Layer 3 VPN services, and commercial clouds. Sites that need a Resource Manager deploy [SiteRM]({{ '/install-quick-start/' | relative_url }}).

## Services

### Is the Priority Network Service Layer 2 or Layer 3?

Both, at different points. A site's storage cluster sees a routed Layer 3 service. The segment across ESnet is Layer 2, which is where traffic engineering happens. See [Priority Network Service]({{ '/services/' | relative_url }}#priority-network-service).

### What happens if a service fails or is turned off?

Traffic returns to the default routed path automatically.

### How is guaranteed bandwidth different from having enough bandwidth?

A lack of bandwidth shows up after a transfer starts, when the workflow can no longer plan around it. A reservation system such as SENSE with OSCARS answers before the transfer starts. Even when less is granted than requested, the workflow knows what it has and can plan compute, storage, and network together.

## Other traffic

### How does SENSE relate to ECMP, L3VPN, link aggregation, and overprovisioning?

SENSE works alongside them and replaces none of them. They improve network use for all flows in aggregate. SENSE handles individual flows, which workflows or network operators can create and change in real time. The two do not need to coordinate their configuration.

### Does SENSE take bandwidth from other users?

For a period, yes. OSCARS Layer 2 circuits with QoS have priority, so best-effort flows have less available during that window. The amount is limited. ESnet's OSCARS configuration sets how much one circuit and all circuits together may use, and SENSE can be set to limit provisioning further, per user or overall. Reserved bandwidth that is idle remains usable by others.

### Who decides which flows get priority?

In the Rucio service, Rucio states which transfers are priorities and how they rank. Each domain decides who may use its infrastructure and how much bandwidth they may have. SENSE checks whether a request is possible given what every domain on the path permits.

## Access

### Who can use SENSE?

Individual users and science workflow agents that act for a collaboration. Users sign in through InCommon federated identity. Workflow agents use an account that has been reviewed and approved for that purpose. Role-based access control separates administrators from the people who provision services.

### What is a Service Profile?

A definition of what one user may provision. It can set:

- the endpoints, by port, domain, or site
- the type of service and its bandwidth
- paths to include or exclude
- how many services can run at once, and in total

A SENSE service manager builds the profile and delegates it to the user. Fields can be locked or left editable within a set of allowed values. Service managers cannot run the profiles they build.

## Operations

### Who runs which part?

| Part | Run by |
|---|---|
| SENSE Orchestrator and the overall multi-domain service | SENSE project team |
| ESnet segment, such as an OSCARS circuit | ESnet |
| SiteRM at a site | Site personnel |
| Other network segments | The domain that owns them |

### How do I get an account or deploy SiteRM?

Write to [{{ site.email }}](mailto:{{ site.email }}). The [AmSC-IRO / SENSE-O user manual](https://amsc-iro-docs-c88e53.gitlab.io/user-manual/index.html) covers account requests and the web portal. Sites can read the [SiteRM quick installation]({{ '/install-quick-start/' | relative_url }}) first.

### Where is the software?

The [useful links]({{ '/docs/useful-links/' | relative_url }}) page lists the public repositories, live systems, and documentation.
