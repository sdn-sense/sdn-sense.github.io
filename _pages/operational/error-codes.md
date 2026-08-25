---
title: "Service Error Codes"
layout: single
classes: wide
permalink: "/operational/error-codes/"
author_profile: false
sidebar:
  nav: "docs"
---

<!-- markdownlint-disable MD036 -->

## Overview

SiteRM assigns a stable, machine-readable integer **error code** (`exccode`) to every service state update. When a service reports `WARNING` or `FAILED`, the code identifies the specific class of failure without requiring log parsing.

The code is exposed in three places:

- **Database** — `servicestates.exccode` column (integer, default `-100`)
- **REST API** — `exccode` field in each `ServiceStateItem` returned by `GET /{sitename}/servicestates`
- **Prometheus** — `siterm_error_events` gauge with label `exccode` (see [Prometheus](#prometheus-siterm_error_events) section below)

---

## Code Ranges

| Range | Meaning |
|---|---|
| `0` | No error — service state is `OK` (used only as the Prometheus gauge value; never stored in the DB) |
| `-1` to `-99` | Python exception classes raised by SiteRM services |
| `-100` | **Unknown / unclassified** — default for all DB rows; also returned when no matching code exists |
| `-101` to `-199` | Named infrastructure sentinels (SNMP, Ansible, systemd events) |

---

## Stability Guarantee

Error codes are **permanent**. Once a code is assigned to an exception class or sentinel string it is never reused, renumbered, or removed. New codes are always added to the next free slot in the appropriate range. This makes them safe to use in Prometheus alert rules, Grafana dashboards, automated runbooks, and long-term time-series data.

---

## Exception-Class Codes (`-1` to `-99`)

These codes are set when a Python exception is caught in a SiteRM service daemon. The source of truth is [`CustomExceptions.py`](https://github.com/sdn-sense/siterm/blob/master/src/python/SiteRMLibs/CustomExceptions.py).

| Code | Python Class | Description |
|---|---|---|
| `-1` | `IOError` | I/O operation failed |
| `-2` | `KeyError` | Missing dictionary key |
| `-3` | `AttributeError` | Missing object attribute |
| `-4` | `IndentationError` | Indentation error in parsed content |
| `-5` | `ValueError` | Unexpected or invalid value |
| `-6` | `PluginException` | Device plugin error (non-fatal) |
| `-7` | `NameError` | Name not defined |
| `-8` | `PluginFatalException` | Device plugin fatal error |
| `-9` | `OverlapException` | Resource overlap detected |
| `-10` | `NotFoundError` | Requested resource not found |
| `-11` | `BackgroundException` | Background thread error |
| `-12` | `ServiceWarning` | Non-fatal service warning |
| `-13` | `ConfigException` | Configuration error |
| `-14` | `WrongInputError` | Invalid input provided |
| `-15` | `FailedToParseError` | Failed to parse content |
| `-16` | `BadRequestError` | Bad HTTP request |
| `-17` | `ValidityFailure` | Validation failure |
| `-18` | `NoOptionError` | Configuration option not found |
| `-19` | `NoSectionError` | Configuration section not found |
| `-20` | `WrongDeltaStatusTransition` | Invalid delta state transition requested |
| `-21` | `DeltaNotFound` | Delta ID not found in the system |
| `-22` | `ModelNotFound` | Model ID not found in the system |
| `-23` | `HostNotFound` | Host not found in the system |
| `-24` | `ExceededCapacity` | Node capacity exceeded |
| `-25` | `ExceededLinkCapacity` | Link capacity exceeded |
| `-26` | `ExceededSwitchCapacity` | Switch capacity exceeded |
| `-27` | `DeltaKeyMissing` | Mandatory delta key is missing |
| `-28` | `UnrecognizedDeltaOption` | Unrecognized delta option |
| `-29` | `FailedInterfaceCommand` | Interface command execution failed |
| `-30` | `FailedRoutingCommand` | Routing command execution failed |
| `-31` | `TooManyArgumentalValues` | Too many argument values provided |
| `-32` | `NotSupportedArgument` | Argument value is not supported |
| `-33` | `ServiceNotReady` | Service is not yet ready |
| `-34` | `HTTPServerNotReady` | HTTP server is not yet ready |
| `-35` | `HTTPException` | HTTP-level exception |
| `-36` | `WrongIPAddress` | Invalid IP address |
| `-37` | `OverSubscribeException` | Resource over-subscribed |
| `-38` | `FailedGetDataFromFE` | Failed to retrieve data from the Frontend |
| `-39` | `SwitchException` | Switch communication error |
| `-40` | `RequestWithoutCert` | Request is missing a client certificate |
| `-41` | `IssuesWithAuth` | Authentication error |
| `-42` to `-99` | *(reserved)* | Reserved for future exception classes |

---

## Infrastructure Sentinel Codes (`-101` to `-199`)

These codes cover infrastructure events that do not map to a Python exception — for example, SNMP poll failures or Ansible unreachability. They are passed to `exceptionCode()` as plain strings (e.g. `"SNMP_TIMEOUT"`).

| Code | Sentinel String | Description |
|---|---|---|
| `-101` | `SNMP_TIMEOUT` | SNMP poll to a device timed out |
| `-102` | `SNMP_UNKNOWN_OID` | SNMP OID not found on the target device |
| `-103` | `ANSIBLE_UNREACHABLE` | Ansible could not reach the target host |
| `-104` | `ANSIBLE_PLAYBOOK_FAILED` | Ansible playbook execution failed |
| `-105` | `SERVICE_DEAD` | Service process is not running (dead in supervisor/systemd) |
| `-106` | `SERVICE_DOWN` | Service process is running but not responding to health checks |
| `-107` to `-199` | *(reserved)* | Reserved for future infrastructure sentinel events |

---

## Prometheus: `siterm_error_events`

The `siterm_error_events` gauge is scraped from the SiteRM Frontend's Prometheus endpoint and published for every known service. It uses the following labels:

| Label | Description |
|---|---|
| `servicename` | Name of the SiteRM service (e.g. `LookUpService`, `ProvisioningService`) |
| `hostname` | FQDN of the host running the service |
| `exccode` | String representation of the error code (e.g. `"-101"`, `"0"`) |

**Gauge value convention:**

- `0` when the service state is `OK` (no error)
- The `exccode` integer (as a float) when the state is `WARNING` or `FAILED`

This dual representation allows both label-based filtering (select by code) and value-based alerting (threshold rules).

### Example PromQL Queries

**Alert on any service not in OK state:**

```promql
siterm_error_events > 0
```

**Find all services currently hitting an SNMP timeout (`-101`):**

```promql
siterm_error_events{exccode="-101"}
```

**Alert on Ansible unreachable (`-103`) for a specific host:**

```promql
siterm_error_events{exccode="-103", hostname="sense-fe.example.edu"} > 0
```

**Alert on any authentication error (`-41`):**

```promql
siterm_error_events{exccode="-41"} > 0
```

**Count distinct services in a non-OK state right now:**

```promql
count(siterm_error_events > 0)
```

---

## REST API: `ServiceStateItem.exccode`

The `exccode` field is returned in every item from the service states endpoint:

```
GET /{sitename}/servicestates
```

Example response fragment:

```json
{
  "hostname": "sense-fe.example.edu",
  "servicename": "LookUpService",
  "servicestate": "FAILED",
  "runtime": 42,
  "version": "1.6.3",
  "exc": "SNMP request to 192.0.2.10 timed out after 30s",
  "exccode": -101
}
```

When `servicestate` is `"OK"`, the stored `exccode` is `-100` (unknown/default). The value `0` is used only in the Prometheus gauge, never stored in the database or returned by the API.

---

## Adding New Codes (Developer Reference)

To add a new code:

1. Open [`src/python/SiteRMLibs/CustomExceptions.py`](https://github.com/sdn-sense/siterm/blob/master/src/python/SiteRMLibs/CustomExceptions.py) in the `siterm` repository.
2. Add the new exception class or sentinel string to the appropriate dict inside `exceptionCode()`:
   - Exception classes → `exCodes` dict (use the next free slot between `-42` and `-99`)
   - Infrastructure strings → `sentinelCodes` dict (use the next free slot between `-107` and `-199`)
3. Codes are **permanent** — never reuse or renumber an existing code.
4. Update this page to document the new code.
