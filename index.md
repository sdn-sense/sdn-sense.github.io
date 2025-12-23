---
title: "SDN for End-to-End Networked Science at the Exascale"
layout: single
classes: wide
author_profile: false
sidebar:
  nav: "docs"
---

Domain science applications and workflow processes are currently forced to view the network as an opaque infrastructure into which they inject data and hope that it emerges at the destination with an acceptable Quality of Experience.  There is little ability for applications to interact with the network to exchange information, negotiate performance parameters, discover expected performance metrics, or receive status/troubleshooting information in real time.  

The Software-Defined Network for End-to-end Networked Science at Exascale (SENSE) system is motivated by a vision for a new smart network and smart application ecosystem that will provide a more deterministic and interactive environment for domain science workflows.  The Software-Defined Network for End-to-end Networked Science at Exascale (SENSE) system includes a model-based architecture, implementation, and deployment which enables automated end-to-end network service instantiation across administrative domains.  

An intent based interface allows applications to express their high-level service requirements, an intelligent orchestrator and resource control systems allow for custom tailoring of scalability and real-time responsiveness based on individual application and infrastructure operator requirements.  This allows the science applications to manage the network as a first-class schedulable resource as is the current practice for instruments, compute, and storage systems.

# SENSE Architeture

In the SENSE Architecture there are three distinct functional roles:

- **Orchestrators** – accept user and workflow intents, perform end-to-end planning, and coordinate provisioning over multiple domains
- **Resource Managers (RMs)** – manage and commit resources within a single administrative domain
- **Addons** – capability-specific extensions that augment orchestration (e.g., Real-Time Monitoring dashboards, Container Runtime, Janus controller)

![alt]({{ site.url }}{{ site.baseurl }}/images/sense-arch.png "SENSE Architecture")


Traditional scientific workflows interact with the network blindly. Applications inject data and hope the network behaves well enough. When performance degrades, it is unclear whether the cause is the network, the host, the storage system, or the application itself.

SENSE addresses this by introducing:

- **Intent-based requests** from applications and workflows
- **Automated orchestration** across administrative domains
- **Real-time visibility and control** of network and end-system behavior

Within this architecture, **SiteRM** is the component that makes *site-local reality* visible, controllable, and enforceable.

## SiteRM Resource Manager


![alt]({{ site.url }}{{ site.baseurl }}/images/sense-detail-arch.png "SENSE Detailed Architecture")

SiteRM is the **site-level resource manager** within the **SENSE (Software-Defined Network for End-to-End Networked Science at Exascale)** ecosystem. It provides the missing link between *global intent* expressed by orchestrators and *concrete, enforceable actions* on real sites infrastructure: hosts, switches.

The core idea: **Treat the network and end systems as first-class, schedulable resources**, just like compute and storage. SiteRM exists to make that idea operational in multi-domain context.


## What SiteRM Is (and Is Not)

**SiteRM is:**

- A site-controlled service that exposes capabilities, state, and policy to SENSE Orchetrator
- An execution point for approved configuration changes on the network and host devices
- A monitoring and telemetry source for hosts and networks
- A policy enforcement layer protecting site resources based on administrator policies

**SiteRM is not:**

- A global scheduler
- A user-facing workflow engine
- A replacement for batch systems, SDN controllers

## SiteRM Components

SiteRM is modular. At a minimum, it consists of three cooperating components usually running at the Sites:

### 1. SiteRM Frontend (FE)

The **SiteRM Frontend** is the authoritative control and visibility plane for a site. The Frontend is the *only* component that external systems talk to directly. It is responsible for:

- Expose REST APIs for Orchestrator(s)
- Maintain site policy and authorization information
- Aggregate and normalize telemetry
- Produce MRML Model and accept Delta (Model changes)
- Accept, Check, Deny/Approve configuration actions before execution
- Interface with local site controllers and network devices (e.g., OVS, Switches, Software Based Routers)
- Accept Debug actions (Ping, Traceroute, IPerf, tcpdump, arp)

### 2. SiteRM Agent

The **SiteRM Agent** runs on the resources it manages (data transfer nodes, storage nodes, compute nodes). Agents never act autonomously. Every action is explicitly approved and dispatched by the Frontend. It is responsible for:

- Collect detailed system and network telemetry
- Execute approved configuration changes from SiteRM Frontend (Create/Delete vlan, Add/Remove IP)
- Enforce QoS and traffic policies

---

### 3. SiteRM Debugger

The **SiteRM Debugger** provides observability and introspection. Debugger never act's on its own. All debug actions come from the Frontend. it is responsible for action execution on the host. The Debugger is critical for distinguishing **network problems from host or application problems**. TODO: ADD Link to Debugger Actions for more details.
