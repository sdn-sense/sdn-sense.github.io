---
layout: article
title: "A practical guide to SENSE network service requests"
date: 2026-11-20 12:00:00 -0600
summary: "Practical SENSE request examples for Layer 2 paths, managed IP addressing, diagnostic IPs, Layer 3 BGP peering, and multipoint VLANs."
description: "Practical SENSE request examples for Layer 2 paths, managed IP addressing, diagnostic IPs, Layer 3 BGP peering, and multipoint VLANs."
author: SENSE team
category: guides
categories: [guides]
permalink: /blog/sense-network-service-examples/
redirect_from:
  - /guides/sense-network-service-examples/
image:
  path: /assets/images/social/sense-social-card.png
  width: 1200
  height: 630
  alt: SENSE end-to-end network orchestration for science workflows
cover: /assets/images/blog/sense-network-service-examples.svg
cover_alt: "Title card for A practical guide to SENSE network service requests"
cover_width: 1200
cover_height: 675
---
SENSE can build several kinds of network service from the same intent model. The important choice is not which button sounds closest; it is whether the application needs one Ethernet segment, managed endpoint addresses, a diagnostic address on the network, routed prefixes, or a shared multipoint LAN.

This guide covers the five stable request patterns used by the current SENSE clients and SiteRM deployments. Every example uses fictional endpoint URNs and [documentation-only address space](https://www.rfc-editor.org/rfc/rfc3849). Replace every placeholder with resources discovered from the SENSE environment in which the request will run.

<!--more-->

<div class="example-note" markdown="1">

**These examples are intentionally not submit-ready.** Endpoint URNs, address-pool names, VLAN availability, routing support, and authorized prefixes are deployment-specific. Use the [SENSE portal](https://sense.es.net/) or discovery API to select resources advertised by the active topology.

</div>

## Start with the service shape

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable overview of the five SENSE service request patterns">
    <img src="{{ '/images/service-examples/overview.svg' | relative_url }}" alt="Decision overview for choosing Layer 2 without addresses, Layer 2 with managed addresses, debug IP, Layer 3 BGP, or a multipoint VLAN, with paths traversing site routers and participating research networks" width="960" height="460">
  </div>
  <figcaption>Choose the connectivity shape first, then add addressing, diagnostics, VLAN, and bandwidth options. The topology examples show one site-network router per site.</figcaption>
</figure>

<p class="example-note"><strong>Illustrative topology:</strong> The detailed diagrams use CENIC, ESnet, and Internet2 as example network-domain labels. They do not describe a fixed production route; SENSE computes each path from the currently advertised topology. Each site is simplified to one SiteRM-controlled network router.</p>

| Need | Request pattern | Addressing result |
| --- | --- | --- |
| Connect exactly two endpoints and keep existing addressing | Layer 2 point-to-point, no IPs | SENSE provisions the VLAN path only |
| Connect two endpoints and allocate service addresses | Layer 2 point-to-point with IPs | SENSE allocates endpoint addresses from a named pool |
| Make the provisioned VLAN reachable from a capable network device for testing | Layer 2 with debug IP | SENSE adds a diagnostic address to a network-device VLAN interface |
| Exchange selected site prefixes through controlled routing policy | Layer 3 BGP peering | SENSE builds a VLAN, BGP peering, and filtered prefix exchange |
| Put three or more endpoints in one Ethernet broadcast domain | Multipoint VLAN bridge | SENSE builds one shared Layer 2 switching subnet |

The exact portal profile names can vary. In the JSON intent used by API clients, the current operational types are `Multi-Path P2P VLAN`, `Site-L3 over P2P VLAN`, and `Multi-Point VLAN Bridge`.

## Fields shared by the examples

Every request has the same basic envelope:

```json
{
  "service": "dnc",
  "alias": "a-readable-request-name",
  "data": {
    "type": "<SERVICE_TYPE>",
    "connections": []
  }
}
```

Within a connection:

- `terminals` identifies the resources to connect. A terminal `uri` must come from discovery, not from another deployment or an old request.
- `vlan_tag` can be `"any"`, an exact advertised tag such as `"1780"`, or an advertised range such as `"1780-1790"`. Different tags at opposite ends require label translation support; do not assume every path can swap VLANs.
- `bandwidth.qos_class` is commonly `bestEffort`, `softCapped`, or `guaranteedCapped`. When a capacity is used, it is expressed in Mbps. Enforcement depends on the capabilities and policy of every participating domain; see [Quality of Service]({{ '/operational/quality-of-service/' | relative_url }}).
- `ip_address_pool` selects a pool for the connection. `assign_ip` is then enabled separately on each terminal.
- `assign_debug_ip` requests a diagnostic address on capable network devices. It does not assign an address to a host.

## Layer 2 point-to-point, no IP addresses

Use this pattern when two endpoints already have the addressing they need, when the application will configure addresses itself, or when the service must carry non-IP Ethernet traffic. SENSE establishes VLAN continuity across the site and participating network domains but does not configure an endpoint or network-device address.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable Layer 2 point-to-point diagram without IP addresses">
    <img src="{{ '/images/service-examples/l2-no-ip.svg' | relative_url }}" alt="Two endpoints connected without managed IP addresses through one site-network router at each site and an illustrative CENIC-to-ESnet Layer 2 path" width="960" height="360" loading="lazy">
  </div>
  <figcaption>The service creates one end-to-end Ethernet path through the site routers and participating networks. Addressing remains with the application or site.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Service type</dt><dd>Multi-Path P2P VLAN</dd></div>
  <div><dt>Terminals</dt><dd>Exactly two</dd></div>
  <div><dt>Address controls</dt><dd>Both disabled</dd></div>
</dl>

```json
{
  "service": "dnc",
  "alias": "l2-no-ip-example",
  "data": {
    "type": "Multi-Path P2P VLAN",
    "connections": [
      {
        "name": "Site A to Site B",
        "bandwidth": {
          "qos_class": "bestEffort"
        },
        "terminals": [
          {
            "uri": "urn:ogf:network:a.example.net:2026:endpoint-a",
            "vlan_tag": "any",
            "assign_ip": false
          },
          {
            "uri": "urn:ogf:network:b.example.net:2026:endpoint-b",
            "vlan_tag": "any",
            "assign_ip": false
          }
        ],
        "assign_debug_ip": false
      }
    ]
  }
}
```

SENSE-O chooses a feasible multi-domain path and coordinates the VLAN labels. A participating SiteRM may create a host VLAN interface, add a VLAN to a switch port, and apply supported QoS, but it will not add an IP address. Verify the returned manifest for the selected VLAN at each terminal, then test with the protocol the application owns.

## Layer 2 point-to-point with managed IP addresses

This is still one Layer 2 broadcast domain. The difference is that SENSE also allocates an address to each terminal from a named pool. Use it when the workflow wants a ready-to-use service subnet instead of managing endpoint addresses separately.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable Layer 2 point-to-point diagram with managed IP addresses">
    <img src="{{ '/images/service-examples/l2-managed-ip.svg' | relative_url }}" alt="Two addressed endpoints connected through one site-network router at each site and an illustrative CENIC-to-ESnet Layer 2 path" width="960" height="380" loading="lazy">
  </div>
  <figcaption>The provider path remains Layer 2. The pool belongs to the connection, and <code>assign_ip</code> controls which terminals receive an address from it.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Service type</dt><dd>Multi-Path P2P VLAN</dd></div>
  <div><dt>Address pool</dt><dd>Required</dd></div>
  <div><dt>assign_ip</dt><dd>true per endpoint</dd></div>
</dl>

```json
{
  "service": "dnc",
  "alias": "l2-managed-ip-example",
  "data": {
    "type": "Multi-Path P2P VLAN",
    "connections": [
      {
        "name": "Addressed L2 service",
        "bandwidth": {
          "qos_class": "guaranteedCapped",
          "capacity": "1000"
        },
        "ip_address_pool": {
          "name": "<AVAILABLE_IPV6_POOL>",
          "netmask": "/64"
        },
        "terminals": [
          {
            "uri": "urn:ogf:network:a.example.net:2026:endpoint-a",
            "vlan_tag": "any",
            "assign_ip": true
          },
          {
            "uri": "urn:ogf:network:b.example.net:2026:endpoint-b",
            "vlan_tag": "any",
            "assign_ip": true
          }
        ],
        "assign_debug_ip": false
      }
    ]
  }
}
```

The example requests 1,000 Mbps of guaranteed-capped service and a `/64` from an available IPv6 pool. The pool name is deliberately a placeholder. IPv4 and IPv6 allocation are both represented by SENSE, but the usable family, netmask, and pool depend on the active profile and participating sites.

After provisioning, read the manifest rather than guessing the addresses. Confirm that each endpoint has the returned address on the returned VLAN interface and that traffic uses those service addresses.

## Layer 2 with a debug IP

A debug IP adds an address to a SiteRM-controlled VLAN interface on a capable site router or other network device. It gives operators a point from which to ping, trace, or otherwise test the provisioned segment. It is not another host address and it does not replace terminal-level `assign_ip`.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable Layer 2 diagram with endpoint and network-device diagnostic addresses">
    <img src="{{ '/images/service-examples/debug-ip.svg' | relative_url }}" alt="A SENSE Layer 2 service through illustrative CENIC and ESnet domains, with endpoint addresses and a separate debug IP on each site's single network-router VLAN interface" width="960" height="400" loading="lazy">
  </div>
  <figcaption>Endpoint addresses serve the application. Debug addresses make the VLAN visible from each capable site router shown on the provisioned path.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Base service</dt><dd>Layer 2 or multipoint</dd></div>
  <div><dt>Capability</dt><dd>config-debug-ip</dd></div>
  <div><dt>assign_debug_ip</dt><dd>true</dd></div>
</dl>

```json
{
  "service": "dnc",
  "alias": "l2-debug-ip-example",
  "data": {
    "type": "Multi-Path P2P VLAN",
    "connections": [
      {
        "name": "L2 service with diagnostics",
        "bandwidth": {
          "qos_class": "guaranteedCapped",
          "capacity": "1000"
        },
        "ip_address_pool": {
          "name": "<AVAILABLE_IPV6_POOL>",
          "netmask": "/64"
        },
        "terminals": [
          {
            "uri": "urn:ogf:network:a.example.net:2026:endpoint-a",
            "vlan_tag": "any",
            "assign_ip": true
          },
          {
            "uri": "urn:ogf:network:b.example.net:2026:endpoint-b",
            "vlan_tag": "any",
            "assign_ip": true
          }
        ],
        "assign_debug_ip": true
      }
    ]
  }
}
```

This combined form—endpoint addresses plus debug addresses—is the portable, checked-in example. Request it only when the selected switching services advertise `config-debug-ip`. SiteRM applies the diagnostic address to the provisioned VLAN interface; device support for active probes still varies, so check the [network-device capability table]({{ '/getting-started/install-supported-network-devices/' | relative_url }}).

## Layer 3 BGP peering

Use a Layer 3 request when the application traffic belongs to routed prefixes rather than to two directly addressed Ethernet endpoints. SENSE first provisions the VLAN used by the routers, allocates peering addresses, and then coordinates filtered BGP exchange. Each site remains authoritative for its ASN, allowed prefix pools, routing policy, and device configuration.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable Layer 3 BGP peering diagram">
    <img src="{{ '/images/service-examples/l3-bgp.svg' | relative_url }}" alt="One site-network router at Site A and Site B exchanges a documentation IPv6 prefix through a SENSE peering VLAN over illustrative CENIC and ESnet domains" width="960" height="420" loading="lazy">
  </div>
  <figcaption>The site routers peer across the provisioned provider path. SENSE advertises and accepts only the requested prefixes; peering addresses remain separate from application prefixes.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Service type</dt><dd>Site-L3 over P2P VLAN</dd></div>
  <div><dt>Peering subnet</dt><dd>From an address pool</dd></div>
  <div><dt>Traffic selector</dt><dd>Prefix list per site</dd></div>
</dl>

```json
{
  "service": "dnc",
  "alias": "l3-bgp-example",
  "data": {
    "type": "Site-L3 over P2P VLAN",
    "connections": [
      {
        "name": "Filtered IPv6 BGP service",
        "bandwidth": {
          "qos_class": "guaranteedCapped",
          "capacity": "1000"
        },
        "ip_address_pool": {
          "name": "<AVAILABLE_BGP_LINK_POOL>",
          "netmask": "/64"
        },
        "terminals": [
          {
            "uri": "urn:ogf:network:a.example.net:2026:sense-router-a",
            "vlan_tag": "any",
            "assign_ip": true,
            "ipv6_prefix_list": "2001:db8:10::/64"
          },
          {
            "uri": "urn:ogf:network:b.example.net:2026:sense-router-b",
            "vlan_tag": "any",
            "assign_ip": true,
            "ipv6_prefix_list": "2001:db8:20::/64"
          }
        ]
      }
    ]
  }
}
```

`2001:db8:10::/64` and `2001:db8:20::/64` are non-routable documentation prefixes. Replace them with prefixes that the selected sites own and advertise for this service. The working request does not carry ASNs: SiteRM obtains its local private ASN and allowed subnet pools from site configuration, while the orchestrated model supplies the neighbor information and route policy.

For IPv6, SiteRM accepts `/64` or larger aggregate prefixes; it rejects a request more specific than `/64`. IPv4 routing is represented in SiteRM as well, but a usable IPv4 request requires a compatible profile, pool, and routing service at every participating site. The [complete L3 deployment example]({{ '/getting-started/l3-deployment-example/' | relative_url }}) shows the one-time site preparation and the per-request VLAN, prefix-list, route-map, neighbor, and network statements.

Verify all three layers after provisioning:

1. The request VLAN and peering addresses exist on both routers.
2. The BGP neighbors are established and each side learns only the expected remote prefix.
3. A trace between application addresses follows the provisioned path, while unrelated traffic keeps its normal route.

## Multipoint Layer 2 bridge

Use a multipoint bridge to place three or more terminals in one shared Ethernet broadcast domain. It is one switching subnet, not a collection of independent point-to-point circuits. That distinction matters for broadcast behavior, VLAN feasibility, failure domains, and path computation.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable multipoint Layer 2 bridge diagram">
    <img src="{{ '/images/service-examples/multipoint.svg' | relative_url }}" alt="Three endpoints, each behind one site-network router, connected to a shared SENSE Layer 2 service across illustrative CENIC, ESnet, and Internet2 domains" width="960" height="490" loading="lazy">
  </div>
  <figcaption>Each site enters through one illustrated site router, while the participating provider domains form one shared switching subnet. A point-to-point path is not automatically feasible as part of a multipoint tree.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Service type</dt><dd>Multi-Point VLAN Bridge</dd></div>
  <div><dt>Terminals</dt><dd>Three or more</dd></div>
  <div><dt>Layer 2 domain</dt><dd>One shared subnet</dd></div>
</dl>

```json
{
  "service": "dnc",
  "alias": "l2-multipoint-example",
  "data": {
    "type": "Multi-Point VLAN Bridge",
    "connections": [
      {
        "name": "Shared research LAN",
        "bandwidth": {
          "qos_class": "bestEffort"
        },
        "terminals": [
          {
            "uri": "urn:ogf:network:a.example.net:2026:endpoint-a",
            "vlan_tag": "any",
            "assign_ip": false
          },
          {
            "uri": "urn:ogf:network:b.example.net:2026:endpoint-b",
            "vlan_tag": "any",
            "assign_ip": false
          },
          {
            "uri": "urn:ogf:network:c.example.net:2026:endpoint-c",
            "vlan_tag": "any",
            "assign_ip": false
          }
        ],
        "assign_debug_ip": false
      }
    ]
  }
}
```

The same address-pool, `assign_ip`, and `assign_debug_ip` controls can be added when every selected endpoint and domain supports them. Compute the request before provisioning: multipoint needs a feasible tree and a compatible VLAN across every branch, and an endpoint that works in a point-to-point request may still lack the advertised multipoint capability.

## Advanced variations

The five patterns above can be combined with these modifiers without changing their basic service shape.

### QoS class and capacity

For an unconstrained path, use:

```json
{
  "bandwidth": {
    "qos_class": "bestEffort"
  }
}
```

For a 10 Gbps guaranteed-capped request, capacity is Mbps:

```json
{
  "bandwidth": {
    "qos_class": "guaranteedCapped",
    "capacity": "10000"
  }
}
```

`softCapped` is also used by SiteRM for a guaranteed minimum that may burst when capacity is available. The client schema additionally recognizes `anyAvailable`, but it is not a portable SiteRM recipe; use only classes exposed by the selected profile. Network-device policing, host shaping, and DSCP marking are capability-dependent.

### Exact VLAN, range, or orchestrator selection

Use `"any"` when the orchestrator should select a mutually available label. An exact tag pins the terminal to that tag, and a range constrains the choice:

```text
"vlan_tag": "any"
"vlan_tag": "1780"
"vlan_tag": "1780-1790"
```

These values are examples, not a statement that a particular VLAN is available. SiteRM validates the requested label against the endpoint and device configuration. MTU is site policy—commonly exposed through SiteRM's `vlan_mtu` configuration—not a demonstrated field to add to these intents.

### Multiple connections are not multipoint

`connections` is an array, so one intent may contain multiple independent point-to-point connections. That does not turn them into one shared LAN. Use `Multi-Point VLAN Bridge` when all terminals must be in the same broadcast domain.

### Scheduling and path constraints

A connection can carry `start`, `end`, or `duration` scheduling data when the chosen profile exposes scheduling. Path inclusion and exclusion lists also exist, but they use topology URIs and should be treated as an operator-guided feature. Omitting manual path steering lets SENSE-O compute from the current resource models and avoids hard-coding an obsolete internal path.

### BGP multipath

Some SiteRM routing services advertise the `l3-bgp-mp` capability. BGP multipath creates multiple equal-cost routed paths to the same destination; it is not a multipoint Ethernet bridge and it is not implied by the words `Multi-Path` in the Layer 2 type name.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable BGP multipath diagram">
    <img src="{{ '/images/service-examples/bgp-multipath.svg' | relative_url }}" alt="One network router at each site exchanging the same selected prefixes over two equal-cost illustrative provider paths through CENIC, Internet2, and ESnet" width="960" height="420" loading="lazy">
  </div>
  <figcaption>The named provider chains are illustrative. BGP multipath is available only when both routing services and the active profile advertise it.</figcaption>
</figure>

The repositories recognize the operational `Site-L3 over VLAN-MultiPath` mode, but do not contain a current generic payload that is safe to present as a portable recipe. Build this service through an advertised profile rather than hand-editing the point-to-point JSON.

## Compute, inspect, then provision

For the Python client, a safe workflow is to compute first:

```bash
sense_util.py --compute --file request.json
sense_util.py --provision --uuid <INSTANCE_UUID>
```

`--compute` compiles the intent without activating the resources and prints the instance UUID as `service_uuid`. Inspect the plan and manifest, and provision that instance only after the endpoints, VLANs, addresses, path, and bandwidth are correct. `--create --file request.json` is the shorter create-and-provision path. Without identity context, SENSE-O submits the request under your own user, and the instance may end up with no project. To submit under a licensed group or a specific project, add top-level `"principal"` and `"project"` fields to the request JSON. Client builds newer than the 1.55 release on PyPI also accept `--principal`, `--project`, and `--use-defaults` flags that set those fields.

After the work is complete, cancel the service and delete the instance according to the workflow's lifecycle policy. Leaving an unused instance active can hold VLANs, addresses, and bandwidth that the next request needs.

## Final verification checklist

- Confirm that every endpoint and address pool came from the active deployment's discovery results.
- Confirm that every selected domain advertises the requested point-to-point, multipoint, debug-IP, or routing capability.
- Inspect the computed plan before provisioning; do not infer feasibility from a previous request.
- Compare the manifest with the [SiteRM topology view]({{ '/operational/topology-view/' | relative_url }}) and active delta state.
- For Layer 2, verify the returned VLAN at each terminal and test the intended endpoint protocol.
- For debug IP, verify the diagnostic address on the network-device VLAN interface and run only tests supported by that platform.
- For Layer 3, verify the BGP neighbor, accepted and advertised prefixes, forwarding route, and end-to-end trace.
- Verify QoS with traffic measurements, not only configuration state.
- Cancel and delete the service when the workflow ends.

The durable rule is simple: let discovery describe what the domains can provide, let compute prove that the complete service is feasible, and let SiteRM keep local policy and infrastructure under each site's control.
