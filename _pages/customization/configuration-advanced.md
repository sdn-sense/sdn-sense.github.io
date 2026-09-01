---
title: "Advanced Frontend Configuration"
layout: single
classes: wide
permalink: "/customization/configuration-advanced/"
author_profile: false
sidebar:
  nav: "docs"
---

## Intro

The [Frontend Configuration](/customization/configuration-frontend/) page documents the parameters most sites need to set. This page documents the remaining **advanced** sections of the Frontend `main.yaml`.

All of the sections below live at the top level of the Frontend `main.yaml`, as siblings of `MAIN.general`:

```yaml
MAIN:
  general:
    ...
  ansible:
    ...
  daemoncontrols:
    ...
  debuggers:
    ...
  prefixes:
    ...
  servicedefinitions:
    ...
  snmp:
    ...
```

> **All of these sections are optional.** SiteRM presets every value at runtime with the defaults shown below; the defaults are *not* written back into Git. Only add a section (or an individual key) when you need to override a default. Most sites never touch any of these.
>
> `prefixes` and `servicedefinitions` are protocol-level constants (RDF/MRML namespaces and OGF/NSI service-definition URIs). Do **not** change them unless the SENSE team explicitly asks you to — a mismatch breaks topology publication and orchestrator negotiation.

---

## `MAIN.ansible`

Controls how the Frontend invokes [`ansible-runner`](https://ansible.readthedocs.io/projects/runner/) when the site `plugin` is `ansible`. In normal operation you only ever tune the **runtime** keys (timeouts, retries, verbosity). The path keys must match the on-disk layout created by the SENSE Ansible collection — changing them without moving the files will stop all device configuration.

SiteRM runs Ansible in three independent contexts, each with its own set of keys distinguished by a suffix:

| Suffix | Context | When it runs |
| --- | --- | --- |
| *(none)* | Main apply loop | Regular fact gathering and config push for all switches. |
| `_singleapply` | Single-switch apply | ProvisioningService re-applies the config for one switch (e.g. after a failed delta) without touching the shared inventory. |
| `_debug` | Debug / diagnostics | Debug actions that need a separate inventory and artifact tree. |

### Per-context keys

Replace `<suffix>` with nothing, `_singleapply`, or `_debug`.

| Key | Default | Description |
| --- | --- | --- |
| `private_data_dir<suffix>` | `/opt/siterm/config/ansible/sense/` | `ansible-runner` private data directory (holds `project/`, `env/`, `inventory/`, artifacts). |
| `inventory<suffix>` | `/opt/siterm/config/ansible/sense/inventory/inventory.yaml` (`_singleapply` -> `inventory_singleapply/…`, `_debug` -> `inventory_debug/…`) | Path to the generated inventory file. |
| `inventory_host_vars_dir<suffix>` | `…/inventory/host_vars/` (with the same `_singleapply` / `_debug` variants) | Directory holding one `<switch>.yaml` `host_vars` file per device. |
| `rotate_artifacts<suffix>` | `100` | Number of `ansible-runner` artifact directories to keep before rotation. SiteRM internally offsets this per playbook so only the fact-gathering playbook performs cleanup. |
| `ignore_logging<suffix>` | `False` | Passed straight to `ansible-runner`. When `True`, `ansible-runner` does not capture stdout/stderr into its Python logger. |
| `verbosity<suffix>` | `0` | Ansible verbosity, `0`-`7` (values above `7` are clamped). `4`+ is equivalent to `-vvvv`. |
| `debug<suffix>` | `False` | Passed to `ansible-runner` as its `debug` flag (very verbose runner-level tracing). |

### Global runtime keys (no suffix)

| Key | Default | Description |
| --- | --- | --- |
| `ansible_runtime_job_timeout` | `300` | Seconds. Exported as `ANSIBLE_RUNNER_TIMEOUT` — hard cap on a single playbook run. |
| `ansible_runtime_idle_timeout` | `300` | Seconds. Exported as `ANSIBLE_RUNNER_IDLE_TIMEOUT` — abort a run that produces no output for this long. |
| `ansible_runtime_retry` | `3` | How many times to retry a playbook that fails with a transient error (e.g. an artifact file disappearing during concurrent cleanup). |
| `ansible_runtime_retry_delay` | `5` | Seconds to wait between retries. |

Example — a large fabric that needs longer playbook runs and more verbose logs while debugging:

```yaml
MAIN:
  ansible:
    ansible_runtime_job_timeout: 900
    ansible_runtime_idle_timeout: 600
    ansible_runtime_retry: 5
    verbosity: 2
```

---

## `MAIN.daemoncontrols`

Per-daemon behaviour tuning. Currently only the **ProvisioningService** is configurable — it controls whether a delta whose device apply failed is retried automatically.

### `MAIN.daemoncontrols.ProvisioningService`

| Key | Default | Description |
| --- | --- | --- |
| `failedretry` | `True` | Enable automatic retry of deltas that failed to apply to the device. When `False`, a failed delta is left in its failed state until an operator intervenes. |
| `failedretrycount` | `10` | Maximum retry attempts per delta UUID. Once reached, the UUID is dropped from the retry list and only a ProvisioningService restart resets the counter. |
| `failedretrytimeout` | `60` | Base back-off in seconds. The next retry for a UUID is scheduled at `last_failure_time + failedretrytimeout * current_retry_count`, i.e. the delay grows on every attempt. |

Example — be less aggressive about retries:

```yaml
MAIN:
  daemoncontrols:
    ProvisioningService:
      failedretry: true
      failedretrycount: 5
      failedretrytimeout: 120
```

---

## `MAIN.debuggers`

Defines which [debug actions](/customization/configuration-debugger/) the Frontend accepts and the server-side limits enforced on each request. Every debug type is a key under `debuggers`; removing a type disables it entirely, and a request for an unknown type is rejected.

### Common keys (most types)

| Key | Default | Description |
| --- | --- | --- |
| `deftime` | `600` | Default value for the request `time` parameter (test duration in seconds) when the caller does not supply one. Must be lower than `runtime`. |
| `maxruntime` | `86400` | Seconds. Used to compute each request's absolute deadline (`runtime = now + maxruntime`); the action is force-stopped at that point regardless of `time`. |
| `defaults` | varies per type | Map of request parameters injected into every request of this type when the caller omits them (e.g. `onetime`, `streams`, `count`, `timeout`, `packetsize`, `port`). |

### Server (listener) types — `iperf-server`, `fdt-server`, `ethr-server`

| Key | Default | Description |
| --- | --- | --- |
| `minport` | `40000` (iperf), `42000` (fdt), `44000` (ethr) | Lowest listening port SiteRM will assign. |
| `maxports` | `2000` | Size of the port window. The assigned port is `minport + (db_id % maxports)`, so ports cycle within `[minport, minport + maxports)`. |

### Client (stream) types — `iperf-client`, `fdt-client`, `ethr-client`

| Key | Default | Description |
| --- | --- | --- |
| `minstreams` | `1` | Minimum accepted value for the `streams` parameter. |
| `maxstreams` | `16` | Maximum accepted value for the `streams` parameter. Requests outside `[minstreams, maxstreams]` are rejected. |

### `rapid-ping`

| Key | Default | Description |
| --- | --- | --- |
| `maxmtu` | `9000` | Maximum accepted `packetsize`. Larger requests are rejected as abusive. |
| `mininterval` | `0.2` | Minimum accepted `interval` between packets in seconds. Smaller values are rejected as a DoS risk. |
| `maxtimeout` | `3600` | Maximum accepted `time` (total run duration) in seconds. |

### `rapid-pingnet`

| Key | Default | Description |
| --- | --- | --- |
| `maxcount` | `100` | Maximum number of pings (`count`) per request. |
| `maxtimeout` | `600` | Maximum accepted per-ping `timeout` in seconds. |

### Types with only the common keys

`arp-table`, `tcpdump`, `traceroute`, `traceroutenet` — each accepts only `deftime`, `maxruntime`, and `defaults` (`{"onetime": true}`).

Example — allow longer iperf3 tests and more parallel streams:

```yaml
MAIN:
  debuggers:
    iperf-client:
      deftime: 1200
      maxruntime: 172800
      minstreams: 1
      maxstreams: 32
      defaults:
        onetime: true
        streams: 4
```

---

## `MAIN.prefixes`

RDF / MRML namespace prefixes used when the Frontend builds the topology model that it publishes to SENSE-O. This is a map of `prefix -> namespace URI`.

| Prefix | Default URI |
| --- | --- |
| `mrs` | `http://schemas.ogf.org/mrs/2013/12/topology#` |
| `nml` | `http://schemas.ogf.org/nml/2013/03/base#` |
| `owl` | `http://www.w3.org/2002/07/owl#` |
| `rdf` | `http://www.w3.org/1999/02/22-rdf-syntax-ns#` |
| `rdfs` | `http://www.w3.org/2000/01/rdf-schema#` |
| `schema` | `http://schemas.ogf.org/nml/2012/10/ethernet` |
| `sd` | `http://schemas.ogf.org/nsi/2013/12/services/definition#` |
| `site` | `urn:ogf:network` |
| `xml` | `http://www.w3.org/XML/1998/namespace#` |
| `xsd` | `http://www.w3.org/2001/XMLSchema#` |

`site` is special: at runtime the Frontend rewrites it to `<site>:<domain>:<year>` using the site's `domain` and `year`, producing the base URN for every resource this site owns (e.g. `urn:ogf:network:example.edu:2025`).

**Do not override these** unless the OGF/NML/MRS schema URIs themselves change and the SENSE team instructs you to. A mismatch between sites (or between a site and SENSE-O) makes the topology unparseable.

---

## `MAIN.servicedefinitions`

URIs identifying the OGF/NSI **service definition** types the Frontend advertises in the topology. Map of `name -> URI`.

| Key | Default URI | Meaning |
| --- | --- | --- |
| `debugip` | `http://services.ogf.org/nsi/2019/08/descriptions/config-debug-ip` | Debug-IP configuration service. |
| `globalvlan` | `http://services.ogf.org/nsi/2019/08/descriptions/global-vlan-exclusion` | Global VLAN exclusion service. |
| `multipoint` | `http://services.ogf.org/nsi/2018/06/descriptions/l2-mp-es` | Layer-2 multipoint Ethernet service. |
| `l3bgpmp` | `http://services.ogf.org/nsi/2019/08/descriptions/l3-bgp-mp` | Layer-3 BGP multipath service. |

As with `prefixes`, these are protocol constants shared with the orchestrator. Change them only when directed by the SENSE team.

---

## `MAIN.snmp`

Controls SNMP monitoring collection and the metrics exported to Prometheus (see [Custom SNMP Exporter](/optional-install/custom-snmp-exporter/)).

### `MAIN.snmp.mibs`

List of SNMP interface object names to poll per monitored interface and export as the `interface_statistics` gauge (labelled by `Key`). Add or remove entries to control which counters are collected. Only numeric values are exported; non-numeric objects (e.g. `ifDescr`) are still collected and used as metric labels.

Default list:

```yaml
MAIN:
  snmp:
    mibs:
      - ifDescr
      - ifType
      - ifMtu
      - ifAdminStatus
      - ifOperStatus
      - ifHighSpeed
      - ifAlias
      - ifHCInOctets
      - ifHCOutOctets
      - ifInDiscards
      - ifOutDiscards
      - ifInErrors
      - ifOutErrors
      - ifHCInUcastPkts
      - ifHCOutUcastPkts
      - ifHCInMulticastPkts
      - ifHCOutMulticastPkts
      - ifHCInBroadcastPkts
      - ifHCOutBroadcastPkts
```

Each name must be resolvable by the SNMP implementation on the target device. Adding an object that a device does not implement simply yields no data for that device.
