---
layout: article
title: "SENSE QoS on Layer 3 paths: finding the right hosts"
date: 2026-11-24 09:30:00 -0600
summary: "How SiteRM finds the hosts behind a Layer 3 request from their address range, what it configures there, and how to shape XRootD pods on Kubernetes workers with siterm-qos."
description: "How SiteRM matches Layer 3 requests to hosts by address range, what it configures, and how siterm-qos shapes XRootD pods on Kubernetes workers."
author: SENSE team
category: guides
categories: [guides]
permalink: /blog/sense-qos-layer-3/
image:
  path: /assets/images/social/sense-social-card.png
  width: 1200
  height: 630
  alt: SENSE end-to-end network orchestration for science workflows
cover: /assets/images/blog/sense-qos-layer-3.svg
cover_alt: "Title card for SENSE QoS on Layer 3 paths: finding the right hosts"
cover_width: 1200
cover_height: 675
---
In a Layer 2 request, SENSE knows the host. It creates a VLAN there and shapes that VLAN, as described in [SENSE QoS in plain words]({{ '/blog/sense-qos-in-plain-words/' | relative_url }}). A Layer 3 request stops at the site routers. The hosts behind them get no new interface and are not named in the request, so SiteRM has to find them.

This post follows one request from the prefix in the JSON to the traffic class on the host, and then looks at the case where this search fails: XRootD in a Kubernetes pod with a Multus interface.

<!--more-->

<div class="example-note" markdown="1">

Addresses are [documentation prefixes](https://www.rfc-editor.org/rfc/rfc3849) and host names are fictional. The rules are output of the SiteRM code run with these example values.

</div>

## The request

```json
{
  "service": "dnc",
  "alias": "l3-qos-example",
  "data": {
    "type": "Site-L3 over P2P VLAN",
    "connections": [
      {
        "name": "Priority path for XRootD",
        "bandwidth": {
          "qos_class": "guaranteedCapped",
          "capacity": "40000"
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

SENSE builds a VLAN between the two routers and a BGP session on it. Each router announces its prefix. For QoS, Site A now has to answer one question: which hosts send traffic from `2001:db8:10::/64`?

## Step 1: each Agent looks for the range

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of Agents matching a Layer 3 request by address range">
    <img src="{{ '/images/qos-examples/l3-match.svg' | relative_url }}" alt="A Layer 3 request names two prefixes. Agents on dtn-01 and dtn-02 have addresses in the source prefix and write a rule. The Agent on dtn-03 has no matching address and writes nothing" width="960" height="486">
  </div>
  <figcaption>dtn-01 and dtn-02 have an address in the source prefix, so they write a rule. dtn-03 does not.</figcaption>
</figure>

Every Agent reads the active requests from the SiteRM Frontend and compares the source prefix with the ranges it knows:

- **Addresses on the host.** The Agent lists all interfaces and addresses in its own network namespace.
- **Ranges in the Agent configuration.** Every entry under `qos.interfaces` can list `ipv4_range` and `ipv6_range`.

When the two overlap, the Agent knows the interface that carries the traffic and its parent NIC. A host with no overlap does nothing.

The range has to be in the configuration as well, even when the host already has the address:

```yaml
qos:
  policy: hostlevel
  qos_params: "mtu 9000 mpu 9000 quantum 200000 burst 300000 cburst 300000 qdisc sfq balanced"
  interfaces:
    enp1s0f0np0:
      master_intf: enp1s0f0np0
      ipv6_range:
        - 2001:db8:10::/64
```

The next step needs these entries. If no Agent lists the range, no Layer 3 rule is written anywhere at the site, and the log does not show an error.

## Step 2: what is the share of this host?

The request is for the whole range, and several hosts share it. The Frontend adds up the NIC capacity of all Agents that list the range and still report, and publishes the total. Each Agent then calculates its part:

```text
share = request x (own NIC - reserved) / total NIC capacity behind the range
```

With two 100 Gbps hosts, 1 Gbps reserved on each, and a 40 Gbps request, the share is `40 x 99 / 200 = 19.8` Gbps per host. When the shares of all paths on the NIC add up to more than the NIC minus the reserve, the Agent divides that capacity between the paths by requested rate instead. The smallest rate the Agent uses is 1 Gbps.

## Step 3: the rule on the host

The Agent writes one shaper on the data NIC with one class per path:

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of traffic classes on a host with two Layer 3 paths">
    <img src="{{ '/images/qos-examples/l3-host-rules.svg' | relative_url }}" alt="A host with two Layer 3 paths. Class priority0 matches 2001:db8:20::/64, class priority1 matches 2001:db8:21::/64, and the default class carries everything else" width="960" height="430" loading="lazy">
  </div>
  <figcaption>Two paths on one host that has both ranges to itself. The class matches the remote prefix.</figcaption>
</figure>

```text
interface46 eth0 eth0-output output rate 100000mbit <qos_params>
  # priority0 belongs to path 1
  class priority0 commit 19800mbit max 100000mbit
    match6 dst 2001:db8:20::/64
  # priority1 belongs to path 2
  class priority1 commit 39600mbit max 100000mbit
    match6 dst 2001:db8:21::/64
  # Default - all remaining traffic gets mapped to default class
  class default commit 1000mbit max 100000mbit
    match all
```

- The host is the only one in both ranges, so the total behind each range is its own 100 Gbps. Each class commits 99/100 of its path, as in step 2: 19.8 of 20 Gbps and 39.6 of 40 Gbps.
- The match is on the remote prefix: `dst` for outgoing traffic. A second block for incoming traffic uses `src`.
- All paths on one NIC share one shaper, so here the Agent can weigh them against each other. This is different from Layer 2, where every VLAN has its own shaper.
- Rates that Layer 2 requests reserve on the same NIC are subtracted first. With a 10 Gbps VLAN on this NIC, `100000mbit` becomes `90000mbit`.

## What the class changes at Layer 3

| Class | Rate used for the path | Host ceiling by default | Host ceiling with `allowOvercommit: false` | DSCP mark |
| --- | --- | --- | --- | ---: |
| `guaranteedCapped`, 40 Gbps | 40 Gbps, divided as in step 2 | Full NIC | The committed rate | 46 |
| `softCapped`, 40 Gbps | 40 Gbps, divided as in step 2 | Full NIC | The committed rate | 18 |
| `bestEffort` | 100 Mbps, raised to 1 Gbps | Full NIC | 1 Gbps | 0 |

The host rule for `guaranteedCapped` and for `softCapped` is the same. Whether a path may go above its rate depends on the site: `allowOvercommit` in the interface section of the Agent configuration. With the default, even a `guaranteedCapped` path may use the full NIC when nothing else does. Sites that want a hard limit have to set it to `false`, and then `bestEffort` paths stop at 1 Gbps per host. When paths use several interfaces on one NIC, the Agent first divides the NIC between those interfaces by requested rate.

The class still reaches the network in two ways:

- The Agent marks IPv6 packets to the remote prefix with the [DSCP value]({{ '/optional-install/dscp-marking/' | relative_url }}) of the class, so networks that honor DSCP can treat them differently.
- On routers with network QoS support, SiteRM adds the per-VLAN policer to the request VLAN, the same one as at Layer 2. Support [differs per device]({{ '/getting-started/install-supported-network-devices/' | relative_url }}). On a router without it, the host rule is the only limit at the site.

## Where it stops: Kubernetes and Multus

Many XRootD deployments run in Kubernetes. Multus gives the pod a second interface, usually a macvlan called `net1`, with an address from the SENSE range. The pod is a full member of the range: it sends from `2001:db8:10::100`, BGP announces the prefix, and the traffic takes the priority path. The QoS rules do not apply to it.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of the namespace boundary between the Agent and a Multus pod">
    <img src="{{ '/images/qos-examples/l3-multus.svg' | relative_url }}" alt="The SiteRM Agent runs in the host network namespace. XRootD runs in a pod network namespace with interface net1. The Agent cannot see the pod address, so no traffic class, routing rule, or DSCP mark applies to the pod" width="960" height="486" loading="lazy">
  </div>
  <figcaption>The Agent looks in the host namespace. The pod address is in another one.</figcaption>
</figure>

The Agent runs with `hostNetwork`, so it sees the interfaces and addresses of the node. When the pod starts, Multus moves `net1` into the network namespace of the pod. From then on:

- The address is gone from the list the Agent reads, so step 1 finds no match and the Agent writes nothing.
- Source routing rules and DSCP marks are set in the host namespace. Packets from the pod do not pass through them.
- The Agent has no access to `net1`. To change rules there, it would have to enter the network namespace of another container, and most sites do not allow that.

### Can the range go in the configuration?

Partly. An entry under `qos.interfaces` with the pod range and the parent interface makes the Agent write a rule on the parent in the host namespace. Outgoing macvlan traffic does pass through the parent: in a small local test with a 200 Mbps class on the parent, a macvlan pod dropped from tens of Gbps to about 170 Mbps. It is still a workaround:

- The mapping is static. If the pod moves to another node, the old node keeps the range and its capacity stays in the total.
- Each parent interface has its own shaper. With one VLAN parent per range, no shaper sees the whole NIC.
- The DSCP mark is still missing.
- With an SR-IOV interface the packets do not pass through the host at all, so a host rule has nothing to act on.

## siterm-qos: traffic control inside the XRootD container

QoS for a Multus pod has to be set where its traffic starts, in the network namespace of the pod. [`siterm-qos`]({{ '/optional-install/siterm-qos/' | relative_url }}) does only that. It is one Python file that runs inside the XRootD container, or in a second container of the same pod, because containers in a pod share the network namespace.

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of siterm-qos inside the XRootD container">
    <img src="{{ '/images/qos-examples/l3-pod-service.svg' | relative_url }}" alt="siterm-qos runs next to XRootD in the same container and network namespace. It reads active requests from the SiteRM Frontend and writes traffic classes on net1" width="960" height="486" loading="lazy">
  </div>
  <figcaption>siterm-qos shares the network namespace with XRootD, so it can see and change net1.</figcaption>
</figure>

Every 60 seconds it:

1. Logs in to the SiteRM Frontend with the host certificate, the same way an Agent does, and reads the active requests.
2. Keeps the running requests whose source prefix contains an address of an interface in the pod.
3. Calculates the share of this pod.
4. Writes one class per remote prefix and a default class for everything else, and removes them when the request ends.

If the Frontend does not answer, it keeps the last known requests and still ends them on time. If an interface already has a queue discipline from another tool, it logs an error and leaves that interface alone.

| Class | Rate of the pod | Ceiling of the pod |
| --- | --- | --- |
| `guaranteedCapped` | Its share of the request | The same rate |
| `softCapped` | Its share of the request | Pod capacity |
| `bestEffort` | Its share of 100 Mbps | Pod capacity, after the other classes |

Unlike the Agent at Layer 3, `guaranteedCapped` is always a hard limit here.

## Details for a Kubernetes worker

<figure class="service-diagram">
  <div class="service-diagram__viewport" tabindex="0" aria-label="Scrollable diagram of shares on two Kubernetes workers">
    <img src="{{ '/images/qos-examples/l3-worker.svg' | relative_url }}" alt="Two workers with one 100 Gbps NIC each run two XRootD pods each. Every pod has 50 Gbps of the total 200 Gbps, so its share of a 40 Gbps request is 10 Gbps" width="960" height="470" loading="lazy">
  </div>
  <figcaption>The share of a pod is the request multiplied by its part of the total capacity.</figcaption>
</figure>

### On the worker

- Load the kernel modules. A container cannot always load them by itself:

  ```bash
  modprobe sch_htb cls_u32
  ```

- A SiteRM Agent on the same worker can stay as it is. Leave the pod ranges out of its `qos.interfaces`. If they stay there, the Agent may write a second limit on the parent interface.

### Capacity

Two pods on one worker share its NIC, and neither shaper knows about the other. Divide the NIC between them with `SITERM_QOS_CAPACITY`, and set `SITERM_QOS_TOTAL` to the sum over all pods in the range. Both are in Mbps.

| Setup | `SITERM_QOS_CAPACITY` | `SITERM_QOS_TOTAL` | Share of a 40 Gbps request |
| --- | ---: | ---: | ---: |
| 2 workers with 100 Gbps, 1 pod each | 100000 | 200000 | 20 Gbps |
| 2 workers with 100 Gbps, 2 pods each | 50000 | 200000 | 10 Gbps |
| 4 workers with 25 Gbps, 1 pod each | 25000 | 100000 | 10 Gbps |

Without `SITERM_QOS_TOTAL` the total that the Frontend reports for the range is used. If there is none, every pod gets the full request, and the log says so.

### Install it in your own image

`siterm-qos` needs Python, `ip`, `tc`, `openssl`, and `NET_ADMIN`, and no SiteRM package:

```dockerfile
FROM <XROOTD_IMAGE>
RUN dnf install -y python3 iproute iproute-tc openssl curl
RUN curl -fsSL -o /usr/local/bin/siterm-qos \
      https://raw.githubusercontent.com/sdn-sense/siterm/master/packaging/siterm-qos/siterm-qos && \
    chmod 755 /usr/local/bin/siterm-qos
COPY siterm-qos.conf /etc/siterm-qos.conf
```

The configuration file points it at the Frontend of the site:

```ini
SITERM_FRONTEND=https://sense-fe.t2.example.org:443
SITERM_SITENAME=T2_US_Example
SITERM_QOS_INTERFACES=net1
SITERM_QOS_CAPACITY=50000
SITERM_QOS_TOTAL=200000
```

The host certificate needs read permission on the Frontend. The [installation page]({{ '/optional-install/siterm-qos/' | relative_url }}) has the rest: how to start it, the Frontend permission, a second container without changes to the XRootD image, Docker and Podman, named network namespaces, all settings, and troubleshooting.

### Check it

`--dry-run` logs in, prints the commands and changes nothing. With the 40 Gbps request from the top of this post, a pod with 50 Gbps of 200 Gbps prints:

```text
# net1: 1 path(s)
qdisc add dev net1 root handle 5e5e: htb default ffff
class add dev net1 parent 5e5e: classid 5e5e:1 htb rate 50000mbit ceil 50000mbit quantum 200000 burst 300000 cburst 300000
class add dev net1 parent 5e5e:1 classid 5e5e:ffff htb rate 1000mbit ceil 50000mbit prio 2 quantum 200000 burst 300000 cburst 300000
class add dev net1 parent 5e5e:1 classid 5e5e:10 htb rate 10000mbit ceil 10000mbit prio 0 quantum 200000 burst 300000 cburst 300000
filter add dev net1 parent 5e5e: protocol ipv6 prio 1 u32 match ip6 dst 2001:db8:20::/64 flowid 5e5e:10
```

Class `5e5e:10` carries the SENSE path and `5e5e:ffff` carries the rest. While data moves, the counters of the classes show which one the traffic uses:

```bash
kubectl exec <POD> -c <CONTAINER> -- siterm-qos --dry-run
kubectl exec <POD> -c <CONTAINER> -- tc -s class show dev net1
```

`siterm-qos --cleanup` removes the rules.

### Limits

- It shapes outgoing traffic only. The other site shapes its own direction.
- It does not set DSCP marks.
- A change of a request rewrites all rules of the interface, so packets in the queue are dropped once.
- HTB uses one lock per interface. At very high rates it can limit the throughput of a pod, so test it at the rate you need.
- We ran it in a macvlan pod namespace on one machine with a test Frontend: 1 Gbps requests with a share of one half gave 472 Mbps for `guaranteedCapped` and 18.9 of 20 Gbps for `softCapped` on an idle interface. It has not run in a production XRootD pod yet.

## Checklist

1. Is the range under `qos.interfaces` on every Agent that has hosts in it, with the right `master_intf`?
2. Does `/etc/firehol/fireqos.conf` contain a `SENSE L3 Routing` block with the remote prefix while the request is active?
3. Does the site want a hard limit? Set `allowOvercommit: false` and check what that does to `bestEffort`.
4. Is the storage service in a Multus pod? Run `siterm-qos` in it, with a capacity and a total.
5. Does the router support network QoS? If it does not, the host rule is the only limit at the site.

The [Layer 3 deployment example]({{ '/getting-started/l3-deployment-example/' | relative_url }}) covers the addresses, routers, and hosts, and the [Agent configuration page]({{ '/customization/configuration-agent/' | relative_url }}) lists the QoS settings.
