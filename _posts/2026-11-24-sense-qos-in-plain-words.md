---
layout: article
title: "SENSE QoS in plain words: what each class does"
date: 2026-11-24 09:00:00 -0600
summary: "What guaranteedCapped, softCapped, and bestEffort do to your traffic on the host and on the switch, with a diagram and the resulting configuration for each one."
description: "What the SENSE QoS classes guaranteedCapped, softCapped, and bestEffort do on the host and on the switch, with diagrams and the resulting configuration."
author: SENSE team
category: guides
categories: [guides]
permalink: /blog/sense-qos-in-plain-words/
image:
  path: /assets/images/social/sense-social-card.png
  width: 1200
  height: 630
  alt: SENSE end-to-end network orchestration for science workflows
cover: /assets/images/blog/sense-qos-in-plain-words.svg
cover_alt: "Title card for SENSE QoS in plain words: what each class does"
cover_width: 1200
cover_height: 675
---
Every SENSE request has a field called `qos_class`. It takes one of three values: `guaranteedCapped`, `softCapped`, or `bestEffort`. This field decides how much traffic a path lets through, and it is the first thing to check when two circuits on the same hardware run at different speeds.

This post explains the problem and shows what SiteRM configures for each class. It covers Layer 2 paths, where SENSE puts a VLAN on the host and on the switch. Layer 3 paths work differently and have [their own post]({{ '/blog/sense-qos-layer-3/' | relative_url }}).

<!--more-->

<div class="example-note" markdown="1">

**Where the numbers come from.** The limits below come from running the SiteRM 1.6.5 code and the Arista EOS template with example values: a 100 Gbps NIC, 100 Gbps switch ports, and a 10 Gbps request. They are configured limits, so measured throughput will be lower.

</div>

## The problem

Several transfers share one link. Without QoS the link has one queue and no opinion about who is more important. Each sender takes what it can get, so a bulk copy can slow down data that has to leave the detector today.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable comparison of a shared link without QoS and with QoS">
    <img src="{{ '/images/qos-examples/problem.svg' | relative_url }}" alt="Without QoS three transfers share one 100 Gbps link and one queue. With QoS each transfer is placed in guaranteedCapped, softCapped, or bestEffort" width="960" height="420">
  </div>
  <figcaption>Without QoS the senders compete for the link. With QoS each request carries a class.</figcaption>
</figure>

On one switch this is easy to fix. A SENSE path is harder because it crosses many networks: two sites, one or two regional networks, and a backbone. Each network has its own equipment, and the same request turns into different configuration in each place. One device can shape traffic, another can only drop it, and a third cannot do either. The result is set by the weakest place on the path.

## Two ways to limit traffic

Hosts and switches limit traffic in different ways.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable comparison of shaping on a host and policing on a switch">
    <img src="{{ '/images/qos-examples/shape-vs-police.svg' | relative_url }}" alt="A host shaper holds packets in a queue and sends them at a steady rate. A switch policer forwards packets up to the rate and drops the rest" width="960" height="400" loading="lazy">
  </div>
  <figcaption>A shaper makes packets wait. A policer drops them.</figcaption>
</figure>

- **The host shapes.** The SiteRM Agent writes [FireQOS](https://firehol.org/tutorial/fireqos-new-user/) rules, which become Linux traffic control (`tc`). Packets above the rate wait in a queue.
- **The switch polices.** SiteRM configures a policer on the input of every port the VLAN uses. Packets above the rate are dropped, and TCP reacts by slowing down and then speeding up again. A transfer behind a policer usually settles below the policer rate.

Policing on the input of every port covers both directions: traffic from the host is checked on the host port, and traffic from the wide-area network is checked on the uplink.

## What the classes mean

| Class | In one sentence | Base rate | Ceiling |
| --- | --- | --- | --- |
| `guaranteedCapped` | You get this rate and never more | Requested capacity | Requested capacity |
| `softCapped` | You get this rate, and more when there is room | Requested capacity | Free capacity of the port |
| `bestEffort` | You get what is left | 100 Mbps, set by SiteRM | One tenth of the free NIC on the host, free capacity of the port on the switch |

Before SiteRM accepts a request, it adds up the rates of all requests on the port that overlap in time. If the new one does not fit, SiteRM refuses it with `Insufficient bandwidth`. This check protects the base rates.

## guaranteedCapped

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of a guaranteedCapped request">
    <img src="{{ '/images/qos-examples/guaranteed-capped.svg' | relative_url }}" alt="A 10 Gbps guaranteedCapped request between two sites. The host sends up to 10 Gbps and queues the rest. The switch forwards up to 10 Gbps and drops the rest" width="960" height="486" loading="lazy">
  </div>
  <figcaption>The host and the switch use the same limit. An idle link does not change it.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Use it for</dt><dd>A transfer with a deadline</dd></div>
  <div><dt>Base rate</dt><dd>10 Gbps</dd></div>
  <div><dt>Ceiling</dt><dd>10 Gbps</dd></div>
</dl>

The request:

```json
{
  "bandwidth": {
    "qos_class": "guaranteedCapped",
    "capacity": "10000"
  }
}
```

On the host:

```text
interface vlan.3600 eth0-3600 bidirectional rate 10000mbit
```

On the switch:

```text
class VLAN3600
  set traffic-class 7
  police rate 10000 mbps burst-size 256 mbytes
```

## softCapped

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of a softCapped request">
    <img src="{{ '/images/qos-examples/soft-capped.svg' | relative_url }}" alt="A 10 Gbps softCapped request between two sites. The host may send up to 99 Gbps. The switch forwards up to 10 Gbps normally and marks traffic from 10 to 100 Gbps to be dropped first" width="960" height="486" loading="lazy">
  </div>
  <figcaption>The first 10 Gbps is normal traffic. Everything above it is marked as droppable.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Use it for</dt><dd>A transfer that can use spare capacity</dd></div>
  <div><dt>Base rate</dt><dd>10 Gbps</dd></div>
  <div><dt>Ceiling</dt><dd>99 Gbps on the host, 100 Gbps on the switch</dd></div>
</dl>

The request:

```json
{
  "bandwidth": {
    "qos_class": "softCapped",
    "capacity": "10000"
  }
}
```

On the host:

```text
interface vlan.3600 eth0-3600 bidirectional rate 99000mbit
  class default rate 10000mbit
```

On the switch:

```text
class VLAN3600
  set traffic-class 4
  police rate 10000 mbps burst-size 256 mbytes action set drop-precedence rate 100000 mbps burst-size 256 mbytes
```

The host ceiling is 99 Gbps because the Agent keeps 1 Gbps of the NIC for itself by default. On the switch, only `guaranteedCapped` requests reduce the ceiling. With one 10 Gbps `guaranteedCapped` request on the same port, the second rate becomes 90000 mbps.

## bestEffort

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of a bestEffort request">
    <img src="{{ '/images/qos-examples/best-effort.svg' | relative_url }}" alt="A bestEffort request between two sites. The host may send up to 9.9 Gbps. The switch forwards 0.1 Gbps normally and marks traffic from 0.1 to 100 Gbps to be dropped first" width="960" height="486" loading="lazy">
  </div>
  <figcaption>Almost all bestEffort traffic is marked as droppable, and the host gives it a smaller share of the NIC.</figcaption>
</figure>

<dl class="request-summary">
  <div><dt>Use it for</dt><dd>Work without a deadline</dd></div>
  <div><dt>Base rate</dt><dd>100 Mbps</dd></div>
  <div><dt>Ceiling</dt><dd>9.9 Gbps on the host, 100 Gbps on the switch</dd></div>
</dl>

The request:

```json
{
  "bandwidth": {
    "qos_class": "bestEffort"
  }
}
```

On the host:

```text
interface vlan.3600 eth0-3600 bidirectional rate 9900mbit
  class default rate 100mbit
```

On the switch:

```text
class VLAN3600
  set traffic-class 2
  police rate 100 mbps burst-size 256 mbytes action set drop-precedence rate 100000 mbps burst-size 256 mbytes
```

Two details to know:

- SiteRM replaces any capacity in a `bestEffort` request with the site default, which is 100 Mbps.
- The Agent limits a `bestEffort` VLAN to one tenth of the free NIC. On a 100 Gbps host without an Agent, or with `noqos: true`, this limit does not exist and only the switch counts.

## All three at once

Here are three requests on one host: 10 Gbps `guaranteedCapped`, 20 Gbps `softCapped`, and one `bestEffort`.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable bar chart of the limits for three requests on one host">
    <img src="{{ '/images/qos-examples/three-classes.svg' | relative_url }}" alt="Bar chart from 0 to 100 Gbps. guaranteedCapped has 10 Gbps. softCapped has 20 Gbps and may reach 88.9 Gbps. bestEffort has 0.1 Gbps and may reach 6.9 Gbps" width="960" height="400" loading="lazy">
  </div>
  <figcaption>Host limits for three requests on a 100 Gbps NIC.</figcaption>
</figure>

| Request | Requested rate | Host ceiling | Switch ceiling |
| --- | ---: | ---: | ---: |
| `guaranteedCapped` | 10 Gbps | 10 Gbps | 10 Gbps |
| `softCapped` | 20 Gbps | 88.9 Gbps | 90 Gbps |
| `bestEffort` | 0.1 Gbps | 6.9 Gbps | 90 Gbps |

The host ceilings add up to 105.8 Gbps, which is more than the NIC has. Linux shapes each VLAN interface separately, and the shapers do not talk to each other. When all three VLANs are busy they can compete for the last few Gbps inside the NIC, where the class plays no role. The class counts again on the switch, when an output port is full. SiteRM sets the mark and the traffic class (7, 4, or 2) there, and the queue settings behind each traffic class stay with the site.

## Why a 400G path can stop near 268 Gbps

Some switch platforms have a highest policer rate that is lower than the port speed. On an Arista EOS platform we use, the switch refuses anything above 268.1 Gbps, and SiteRM uses 268 Gbps as its default maximum (`max_policy_rate`).

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable chart of the policer limit on a 400 Gbps port">
    <img src="{{ '/images/qos-examples/port-400g.svg' | relative_url }}" alt="On a 400 Gbps port a bestEffort VLAN is forwarded up to 268 Gbps and everything above 268 Gbps is dropped" width="960" height="330" loading="lazy">
  </div>
  <figcaption>A bestEffort VLAN on a 400 Gbps port. The port has room, but the policer drops everything above 268 Gbps.</figcaption>
</figure>

This applies to all three classes. A `guaranteedCapped` request for 400 Gbps is configured as `police rate 268000 mbps`. With a 9000-byte MTU that leaves at most about 266 Gbps of TCP data, and a TCP transfer behind a policer ends up below that.

If one VLAN on such a port runs at almost 400 Gbps, no policer was active for that VLAN in that direction. To test the full port speed on purpose, turn SENSE QoS off for the ports involved (`rate_limit: false` in the site configuration) and remember to turn it back on.

## What QoS does not promise

- QoS decides who gets the link when it is busy, and it sets a ceiling. A slow disk or an untuned host stays slow.
- A class is enforced only where the equipment supports it. The [device table]({{ '/getting-started/install-supported-network-devices/' | relative_url }}) lists what SiteRM can configure. Provider networks apply their own rules for the same class.
- The class and the capacity in the request set the limits. A speed in the circuit name has no effect.

## Check these before you compare speeds

1. Which class and which capacity does each request have? Look at the request and ignore the circuit name.
2. Is SENSE QoS enabled on the switch and on the port (`rate_limit`)? Two ports with different settings give two different results.
3. Is the policer on every port of the path, in both directions? A missing one lets one direction run without a limit.
4. Does the host have an Agent that applies QoS? Compare `/etc/firehol/fireqos.conf` with the examples above.
5. Are the drop counters on the input ports growing during the test? Growing counters mean the policer is active.

When you compare two technologies, for example SENSE with a static VLAN or an ACL redirect, use the same QoS setting on both. Otherwise the test measures the policer.

The [Quality of Service page]({{ '/operational/quality-of-service/' | relative_url }}) and the [Arista EOS page]({{ '/devices/arista-eos/' | relative_url }}) have the operational details, and the [request guide]({{ '/blog/sense-network-service-examples/' | relative_url }}) shows complete requests.
