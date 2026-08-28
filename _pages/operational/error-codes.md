---
title: "Error Code Reference (exccode)"
layout: single
classes: wide
permalink: "/operational/error-codes/"
author_profile: false
sidebar:
  nav: "docs"
---

<!-- markdownlint-disable MD036 -->

## Overview

Every service state SiteRM Frontend reports (`OK`, `WARNING`, `FAILED`) now carries a stable, machine-readable numeric error code alongside the human-readable message. This lets dashboards, alerts, and scripts key off a fixed number instead of parsing free-text log lines, which can change wording over time.

**Codes are permanent** — once a number is assigned, it is never reused or reassigned to a different error.

Where you'll see these:

- **Database:** `servicestates.exccode` (single int, the *primary* code for that report) and `servicestates.exccodes` (JSON list — a `WARNING` report can legitimately batch more than one distinct cause into the same cycle, e.g. an SNMP timeout and a stale VLAN both tripping in the same run).
- **REST API:** `GET /api/{sitename}/servicestates` returns both fields for every row.
- **Prometheus:** the `siterm_error_events` gauge (labels: `servicename`, `hostname`) reports the *primary* code only — `0` when the service state is `OK`, the negative code otherwise. It intentionally does not enumerate every code from `exccodes` as separate label combinations, to avoid unbounded metric cardinality.
- **Frontend logs:** the human-readable message that generated the code is always still logged in full; the code is metadata alongside it, not a replacement for it.

### Code ranges

| Range | Meaning |
|---|---|
| `-1` … `-99` | A specific Python exception class was caught (see [Exception codes](#exception-codes)) |
| `-100` | Unknown / unclassified — the exception or condition has no code mapping yet |
| `-101` … `-199` | A named condition that isn't a Python exception — an SNMP failure, a free-text `Warnings.addWarning()` category, etc. (see [Warning / sentinel codes](#warning--sentinel-codes)) |

Source of truth: `exceptionCode()` in [`SiteRMLibs/CustomExceptions.py`](https://github.com/sdn-sense/siterm/blob/master/src/python/SiteRMLibs/CustomExceptions.py).

---

## Warning / sentinel codes

These are the codes you're most likely to see day-to-day — they come from `Warnings.addWarning()` call sites across the Frontend and report through `servicestates` as a `WARNING` state. Each one already existed as a warning message before it had a code; several are also covered informally on the [Common Issues](/operational/common-issues/) page.

### -101 — SNMP_TIMEOUT

```text
[{host}]: Got SNMP Timeout Exception: {details}
```

**Cause:** SNMPMonitoring could not reach the switch's SNMP agent in time.

**Resolution:** Check the switch is reachable and SNMP is enabled and responsive (`community`/`version` in `snmp_monitoring` config). Transient on a loaded switch; persistent if the switch or network path is down.

---

### -102 — SNMP_UNKNOWN_OID

```text
[{host}]: Got SNMP UnknownObjectID Exception for key {key}: {details}
```

**Cause:** The switch does not support the requested OID (vendor/firmware difference, or misconfigured MIB path).

**Resolution:** Verify the OID/MIB used for this device family and firmware version; adjust the SNMP monitoring config if the device genuinely doesn't expose it.

---

### -103 — ANSIBLE_UNREACHABLE

Reserved for a future Ansible-unreachable-host condition. Not yet emitted by any code path.

---

### -104 — ANSIBLE_PLAYBOOK_FAILED

Reserved for a future Ansible-playbook-failure condition. Not yet emitted by any code path.

---

### -105 — SERVICE_DEAD

Reserved for a future "service hasn't reported in `SERVICE_DEAD_TIMEOUT`" condition. Not yet emitted by any code path — the `UNKNOWN` state computed in `SNMPMonitoring.__getServiceStates()` doesn't carry this code today.

---

### -106 — SERVICE_DOWN

Reserved for a future "service down beyond `SERVICE_DOWN_TIMEOUT`" condition. Not yet emitted by any code path.

---

### -107 — VALIDATOR_SWITCH_NO_ANSIBLE_OUTPUT

```text
Switch {switch} defined in configuration, but no output received from Ansible call.
```

**Cause:** The switch is listed under `switch` in the site config, but the Ansible run never returned data for it.

**Resolution:** Check Ansible connectivity/credentials for that switch, and confirm the switch name matches what Ansible reports.

---

### -108 — VALIDATOR_PORT_NO_ANSIBLE_OUTPUT

```text
Switch {switch} port {port} defined in configuration, but no output received from Ansible call.
```

**Cause:** The port is defined under that switch's `ports` config, but Ansible didn't return data for it specifically (the switch itself did respond).

**Resolution:** Confirm the port name/format matches what Ansible reports for this device family; see the relevant [Network Device](/getting-started/install-supported-network-devices/) page.

---

### -109 — VALIDATOR_HOST_LLDP_MISMATCH

```text
Host {hostname} does not match lldp information. Host Info: {...}, Switch LLDP Info: {...}
```

**Cause:** The host's reported MAC address doesn't match what LLDP sees on the switch port it's supposed to be connected to.

**Resolution:** Confirm the host is physically connected to the port SiteRM expects, and that the host's `agent` interface/MAC config is correct.

---

### -110 — LIVENESS_READINESS_DISABLED

```text
Liveness check is disabled on Frontend. Please enable it to ensure proper operation.
Readiness check is disabled on Frontend. Please enable it to ensure proper operation.
```

**Cause:** The liveness or readiness check has been manually disabled on this Frontend (a `siterm-liveness-disable` / `siterm-readiness-disable` file exists under the temp dir).

**Resolution:** Remove the disable file once whatever required disabling the check is resolved — leaving it disabled long-term hides real failures from Kubernetes/monitoring.

---

### -111 — DELTA_STATE_TRANSITION_ERROR

Message varies — it's whatever error the delta state machine returned for the failing transition (`committing`, `committed`, `activating`, `activated`, `remove`, `removed`).

**Cause:** A delta failed to move to the expected next state.

**Resolution:** Check the Frontend's `DBWorker`/`PolicyService` logs for the specific transition and underlying error; often a downstream provisioning or validation failure for that delta.

---

### -112 — SWITCH_VLAN_RANGE_EXHAUSTED

```text
VLAN Range for {switch}:{port} is not available or remaining vlans is empty.
```

**Cause:** All VLANs in the configured range for this switch port are currently allocated.

**Resolution:** This is a warning, not fatal — no new requests can be provisioned on this port until a VLAN frees up. See [No Remaining VLANs](/operational/common-issues/#no-remaining-vlans) on the Common Issues page.

---

### -113 — NODE_VLAN_RANGE_EXHAUSTED

```text
VLAN Range for {hostname}:{interface} is not available or remaining vlans is empty.
```

**Cause:** Same as -112, but for a host/agent interface rather than a switch port.

**Resolution:** Same as -112 — warning only; no new requests accepted on that interface until capacity frees up.

---

### -114 — VLAN_MANUAL_CONFIG_MISMATCH

```text
Vlan {vlan} is configured manually on {host}. It comes not from delta. Either deletion did not happen or was manually configured.
```

**Cause:** A VLAN inside the SENSE-managed range exists on the device/host but isn't tracked by any active delta.

**Resolution:** See [VLAN Manually Configured](/operational/common-issues/#vlan-manually-configured) on the Common Issues page — usually a leftover from a failed deletion, or someone configured it by hand.

---

### -115 — MODEL_UPDATE_LOOP_SUSPECTED

```text
Model has updated more than 60 times. Please check LookupService/PolicyService for possible issues.
```

**Cause:** The topology model has been rebuilt far more often than expected, usually meaning something is flapping (a switch, an interface, or a delta) and causing LookUpService to recompute the model on every cycle.

**Resolution:** Check LookUpService/PolicyService logs around the time this fired for what keeps changing; a flapping link or a delta stuck retrying are the usual causes.

---

### -116 — SWITCH_CHANNEL_MEMBER_DOWN

```text
Channel member {member} of port {switch}{port} is not up. Line protocol: {...}, Oper status: {...}
```

**Cause:** One member link of a port channel/LAG is down while the channel itself is still being modeled.

**Resolution:** Investigate the specific member link — this doesn't necessarily mean the whole channel is down, but a degraded member reduces available capacity.

---

### -117 — SWITCH_PORT_NOT_SWITCHPORT

```text
Port {switch}{port} not added into model. Its status not switchport. Ansible runner returned: {...}.
```

**Cause:** Ansible reports this port isn't operating as a switchport, so it was excluded from the model. Common right after a device reboot or a config change that temporarily drops switchport mode.

**Resolution:** If the port should be a switchport, check its running config on the device. If this is expected (e.g. a routed port), no action needed — set `allports` for the switch to suppress this warning for ports intentionally excluded.

---

### -118 — AGENT_HOST_PUBLISH_FAILED

Message combines whatever host-update/insert publish errors occurred, e.g.:

```text
... Could not publish to SiteFE Frontend. Update to FE: Error: ... HTTP Code: ... Add tp FE: Error: ... HTTP Code: ...
```

**Cause:** The SiteRM Agent on a DTN could not publish its host info to the Frontend's `/api/{sitename}/hosts` endpoint.

**Resolution:** Check network connectivity and certificate/auth validity between the Agent and the Frontend, and the Frontend's REST logs for the corresponding request.

---

## Exception codes

These come from a specific Python exception class being caught somewhere in the Frontend or Agent (`policyService.getError()`, `Daemonizer.reporter(..., excType=...)`). They're lower-level than the warning codes above and generally indicate a request/processing failure rather than an operational/infrastructure condition.

| Code | Exception | Meaning |
|---|---|---|
| -1 | `IOError` | Filesystem or I/O operation failed |
| -2 | `KeyError` | Expected dictionary key was missing |
| -3 | `AttributeError` | Code accessed a missing attribute — usually an unexpected `None` or malformed object |
| -4 | `IndentationError` | Malformed Python source was executed/parsed (rare; usually a bad plugin/config file) |
| -5 | `ValueError` | A value was the wrong type or out of the expected range |
| -6 | `PluginException` | A switch/device plugin raised a general error |
| -7 | `NameError` | Code referenced an undefined name |
| -8 | `PluginFatalException` | A switch/device plugin raised an unrecoverable error |
| -9 | `OverlapException` | A requested resource (e.g. VLAN, IP) overlaps with an existing allocation |
| -10 | `NotFoundError` | A requested item was not found |
| -11 | `BackgroundException` | A background task failed |
| -12 | `ServiceWarning` | Generic/uncategorized warning — see [Warning / sentinel codes](#warning--sentinel-codes) for the specific categories this now normally resolves to instead |
| -13 | `ConfigException` | Site or Frontend configuration is invalid or incomplete |
| -14 | `WrongInputError` | Caller supplied invalid input |
| -15 | `FailedToParseError` | Failed to parse an expected format (e.g. topology, request payload) |
| -16 | `BadRequestError` | REST API request was malformed |
| -17 | `ValidityFailure` | A value failed validation |
| -18 | `NoOptionError` | Expected configuration option was missing |
| -19 | `NoSectionError` | Expected configuration section was missing |
| -20 | `WrongDeltaStatusTransition` | Delta state machine transition isn't allowed from the current state |
| -21 | `DeltaNotFound` | Referenced delta ID does not exist |
| -22 | `ModelNotFound` | Referenced model ID does not exist |
| -23 | `HostNotFound` | Referenced host is not known to the system |
| -24 | `ExceededCapacity` | Requested capacity exceeds what the node can provide |
| -25 | `ExceededLinkCapacity` | Requested capacity exceeds what the link can provide |
| -26 | `ExceededSwitchCapacity` | Requested capacity exceeds what the switch can provide |
| -27 | `DeltaKeyMissing` | A required key was missing from a delta |
| -28 | `UnrecognizedDeltaOption` | A delta contained an option SiteRM doesn't recognize |
| -29 | `FailedInterfaceCommand` | A device interface command failed to execute |
| -30 | `FailedRoutingCommand` | A device routing command failed to execute |
| -31 | `TooManyArgumentalValues` | Too many values were supplied for an argument |
| -32 | `NotSupportedArgument` | An unsupported argument value was supplied |
| -33 | `ServiceNotReady` | A dependent service was not ready to handle the request |
| -34 | `HTTPServerNotReady` | The HTTP server was not ready to accept requests |
| -35 | `HTTPException` | Generic HTTP-layer exception |
| -36 | `WrongIPAddress` | An IP address was invalid or malformed |
| -37 | `OverSubscribeException` | A resource was oversubscribed beyond its allowed limit |
| -38 | `FailedGetDataFromFE` | An Agent failed to retrieve expected data from the Frontend |
| -39 | `SwitchException` | A switch communication error occurred |
| -40 | `RequestWithoutCert` | A request arrived without a required client certificate |
| -41 | `IssuesWithAuth` | Authentication or authorization failed |
| -42 | `BadSyntax` (rdflib) | The RDF/Turtle/N3 topology could not be parsed |

**-100 — Unknown:** the exception or condition doesn't have a code mapping yet. If you see this often for the same underlying cause, it's worth [opening an issue](https://github.com/sdn-sense/siterm/issues) so it can get a proper code.

---

*This page documents the codes assigned as of siterm `exceptionCode()`. Codes are additive and permanent — if you're debugging against an older SiteRM version, some codes above may not exist yet, but existing codes never change meaning.*
