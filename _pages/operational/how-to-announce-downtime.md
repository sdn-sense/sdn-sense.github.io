---
title: "How to Announce Downtime"
layout: single
classes: wide
permalink: "/operational/how-to-announce-downtime/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

SiteRM sites can announce planned or emergency downtime by adding entries to the site's `FE/downtime.yaml` file in the [rm-configs](https://github.com/sdn-sense/rm-configs/) repository.

This file is intended to give site administrators a simple, site-controlled way to tell SENSE consumers that a SiteRM, SiteRM Agent, or full site should not receive new requests for a defined period of time. Consumers such as SENSE-O and Autogole monitoring can use the file to disable drivers, suppress or annotate monitoring alerts, and show the reason why the endpoint is unavailable.

## When to Use Downtime

Use `downtime.yaml` any time a site expects SENSE service to be unavailable or unstable, especially when new requests should be paused.

Common examples:

- SiteRM Frontend upgrades or restarts
- SiteRM Agent upgrades or host maintenance
- Switch maintenance or network upgrades
- Site power work or power cuts
- Data center maintenance windows
- Routing, BGP, VLAN, or optical path work
- Debugging incidents where new requests should be temporarily stopped
- Planned outages that should be visible to Orchestrators and monitoring systems

If the site can still serve existing circuits but should not accept new requests, announce downtime for the affected service and explain that in `disable_reason`.

## File Location

Each site with a Frontend directory should have:

```text
<SITE_NAME>/FE/downtime.yaml
```

Examples:

```text
T2_US_Caltech/FE/downtime.yaml
NRM_CENIC/FE/downtime.yaml
```

An empty file means there is no announced downtime.

## File Format

The file has one top-level key: `downtimes`. This key maps to a list of downtime entries.

Downtime entries are append-only operational history. Once an entry is added, do not remove it. When a new maintenance window or outage needs to be announced, add a new item to the `downtimes` list with a new `id`.

```yaml
downtimes:
  - id: 0
    enabled: false
    disable_reason: "Frontend upgrade and switch maintenance."
    start: "2026 01 01 00:00"
    end: "2026 01 01 04:00"
    services: All
    hostname: sense-example.example.edu
    downfor:
      - sense-o.es.net
      - autogolemon.nrp.edu
```

## Fields

`id`
: Integer identifier for this downtime entry. Keep it unique in the `downtimes` list. Use a new ID for each new downtime entry.

`enabled`
: Boolean value. Use `false` when the service should be treated as unavailable. Use `true` when keeping a placeholder or recording that the endpoint is available.

`disable_reason`
: Human-readable reason shown to operators and consumers. This should explain what is happening and, when useful, what impact is expected.

`start`
: Start time in `yyyy mm dd hh:mm` format.

`end`
: End time in `yyyy mm dd hh:mm` format. The end time must be after the start time.

`services`
: Service scope for the downtime. Valid values are:

- `FE` - SiteRM Frontend only
- `Agent` - SiteRM Agent or host-side service only
- `All` - Full SiteRM service impact

`hostname`
: FQDN of the affected SiteRM component or site endpoint.

`downfor`
: List of consumers that should apply this downtime. Include the Orchestrator and monitoring systems that should stop sending new requests, disable a driver, or annotate alerting.

## Example: Frontend Upgrade

```yaml
downtimes:
  - id: 0
    enabled: false
    disable_reason: "SiteRM Frontend upgrade. New SENSE requests are paused during the maintenance window."
    start: "2026 02 10 15:00"
    end: "2026 02 10 17:00"
    services: FE
    hostname: sense-fe.example.edu
    downfor:
      - sense-o.es.net
      - autogolemon.nrp.edu
```

## Example: Site Power Maintenance

```yaml
downtimes:
  - id: 0
    enabled: true
    disable_reason: "Previous Frontend upgrade has completed."
    start: "2026 02 10 15:00"
    end: "2026 02 10 17:00"
    services: FE
    hostname: sense-fe.example.edu
    downfor:
      - sense-o.es.net
      - sense-o-dev.es.net
  - id: 1
    enabled: false
    disable_reason: "Data center power maintenance. Frontend, agents, and network devices may be unavailable."
    start: "2026 03 05 02:00"
    end: "2026 03 05 08:00"
    services: All
    hostname: sense-fe.example.edu
    downfor:
      - sense-o.es.net
      - sense-o-dev.es.net
```

## Example: Multiple Downtimes

A site can keep multiple downtime records in the same list. Add a new entry for every new event. Do not remove older entries.

```yaml
downtimes:
  - id: 0
    enabled: true
    disable_reason: "Previous network upgrade has completed."
    start: "2026 04 01 10:00"
    end: "2026 04 01 12:00"
    services: All
    hostname: sense-fe.example.edu
    downfor:
      - sense-o.es.net
      - sense-o-dev.es.net
  - id: 1
    enabled: false
    disable_reason: "Network upgrade affecting SENSE production and development requests."
    start: "2026 04 15 10:00"
    end: "2026 04 15 12:00"
    services: All
    hostname: sense-fe.example.edu
    downfor:
      - sense-o.es.net
      - sense-o-dev.es.net
```

## Operational Guidance

Before downtime starts:

1. Add or update the site's `FE/downtime.yaml` file.
2. Include a clear `disable_reason` that operators can understand without extra context.
3. Set `services` to the narrowest accurate scope.
4. Include all affected consumers in `downfor`.
5. Submit the change to [rm-configs](https://github.com/sdn-sense/rm-configs/) and allow SiteRM consumers to pick up the update.

During downtime:

- Keep the entry active for the full maintenance window.
- Extend `end` if the work runs longer than expected.
- Update `disable_reason` if the impact changes.

After downtime:

- Do not remove the downtime entry.
- Set `enabled: true` when the downtime is over, if consumers use this flag to decide current availability.
- For the next downtime, add a new list item with a new `id`.
- Confirm that SENSE-O, Autogole, and other consumers see the endpoint as available again.
- Confirm that the SiteRM Frontend and Agents are healthy before accepting new requests.

## Validation

The `rm-configs` validator checks `FE/downtime.yaml` files. Empty files are valid. Populated files must define only the top-level `downtimes` list. Each entry must use the expected fields and types:

- `id` must be an integer
- `id` must be unique in the `downtimes` list
- `enabled` must be `true` or `false`
- `disable_reason` must be a string
- `start` and `end` must use `yyyy mm dd hh:mm`
- `start` must be before `end`
- `services` must be `FE`, `Agent`, or `All`
- `hostname` must be set
- `downfor` must be a non-empty list

Run validation from the `rm-configs` repository:

```bash
python3 validate_config.py
```
