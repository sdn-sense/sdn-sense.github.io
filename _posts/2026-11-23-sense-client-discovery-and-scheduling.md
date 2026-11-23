---
layout: article
title: "SENSE client recipes: discovery, bandwidth, and scheduling"
date: 2026-11-23 09:00:00 -0600
summary: "Install the SENSE Python client, then use it to find sitenames, drivers, endpoint URNs, and address pools, ask for the maximum bandwidth between two endpoints, and schedule a service for a fixed window."
description: "Install the SENSE Python client and use sense_util.py to find sitenames, endpoint URNs, address pools, maximum bandwidth, and to schedule services."
author: SENSE team
category: guides
categories: [guides]
permalink: /blog/sense-client-discovery-and-scheduling/
image:
  path: /assets/images/social/sense-social-card.png
  width: 1200
  height: 630
  alt: SENSE end-to-end network orchestration for science workflows
cover: /assets/images/blog/sense-client-discovery-and-scheduling.svg
cover_alt: "Title card for SENSE client recipes: discovery, bandwidth, and scheduling"
cover_width: 1200
cover_height: 675
---
The [practical guide to SENSE network service requests]({{ '/blog/sense-network-service-examples/' | relative_url }}) showed the five request shapes and kept every endpoint, pool, and prefix as a placeholder. This follow-up covers how to fill those placeholders: install the client, look up what the orchestrator advertises, ask how much bandwidth a path can carry, and book a service for a fixed time window.

All commands use `sense_util.py` and the `sense` Python package from [sense-o-py-client](https://github.com/sdn-sense/sense-o-py-client). Endpoint URNs, pool names, addresses, and sample outputs below are fictional.

<!--more-->

<div class="example-note" markdown="1">

**Discovery is read-only; compute and create are not.** The `--discover` queries and the pool listing only read state. `--compute` creates a service instance on SENSE-O (without provisioning it), and `--create` provisions resources. Delete instances you only computed, and cancel and delete services when the work is done.

</div>

## Install the client

The client is published on PyPI as `sense-o-api` and needs Python 3. Install it into a virtual environment:

```bash
python3 -m venv ~/sense-venv
source ~/sense-venv/bin/activate
pip install --upgrade pip
pip install sense-o-api
```

This installs the `sense` package and puts `sense_util.py` on your `PATH`. To run unreleased changes, install from a checkout instead:

```bash
git clone https://github.com/sdn-sense/sense-o-py-client.git
pip install ./sense-o-py-client
```

### Log in with the device flow

SENSE-O's Keycloak gives tokens to the public `sense-cli` client through the OAuth 2.0 device authorization flow. You sign in through a browser, and no password or client secret is stored on your machine. The [`sense-login.sh`]({{ '/assets/tools/sense-login.sh' | relative_url }}) helper runs that flow, caches the tokens, and refreshes them. It needs `bash`, `curl`, and `jq`. Read it before you run it:

```bash
mkdir -p ~/.sense
curl -fsSL -o ~/.sense/sense-login.sh https://sdn-sense.dev/assets/tools/sense-login.sh
chmod 700 ~/.sense/sense-login.sh
~/.sense/sense-login.sh
```

The first run prints a link and a one-time code:

```text
Open in a browser:  https://sense-o.es.net:8543/realms/StackV/device?user_code=ABCD-EFGH
Or go to https://sense-o.es.net:8543/realms/StackV/device and enter: ABCD-EFGH
```

Open the link, sign in with your SENSE account, and approve the request. The script then saves the tokens in `~/.private/sense-tokens.json` with mode 600 (set `SENSE_TOKEN_FILE` to keep them elsewhere). Later runs reuse the cached access token, which lasts 40 minutes on the production orchestrator, then refresh it with the saved refresh token. The browser step comes back only when that login has expired or been revoked.

A few options cover the rest of a login's life:

| Command | What it does |
| --- | --- |
| `sense-login.sh --status` | Shows the cached login and its expiry, without contacting the server |
| `sense-login.sh --offline` | Asks for `offline_access`: the refresh token then has no fixed lifetime, only a 30-day idle timeout |
| `sense-login.sh --logout` | Revokes the session at Keycloak and deletes the cache |
| `KC=https://auth.example.org REALM=StackV sense-login.sh` | Logs in to another orchestrator's Keycloak; each login is cached separately |

To get a `sense-login` command in every terminal, add this line to `~/.bashrc` or `~/.zshrc`. It also keeps a `SENSE_ACCESS_TOKEN` variable fresh before each prompt, without ever opening a browser:

```bash
eval "$(~/.sense/sense-login.sh --shell-init)"
```

### Give the token to the client

The Python client reads its connection settings from a YAML file. It uses the first one it finds:

1. the path in the `SENSE_AUTH_OVERRIDE` environment variable (an error if that file is missing),
2. `/etc/sense-o-auth.yaml`,
3. `~/.sense-o-auth.yaml`.

The file can carry an `ACCESS_TOKEN` in place of a username and password. This shell function asks `sense-login.sh` for a current token, refreshing it if needed but never starting a browser login, writes it into a private config file, and points the client at that file:

```bash
sense-env() {
  local token conf="$HOME/.sense/sense-o-token.yaml"
  token=$(~/.sense/sense-login.sh --token --no-login --quiet) || {
    echo "No usable SENSE login; run ~/.sense/sense-login.sh" >&2
    return 1
  }
  (umask 077 && cat > "$conf" <<EOF
AUTH_ENDPOINT: https://sense-o.es.net:8543/realms/StackV/protocol/openid-connect/token
API_ENDPOINT: https://sense-o.es.net:8443/StackV-web/restapi
CLIENT_ID: sense-cli
ACCESS_TOKEN: $token
verify: True
EOF
  )
  export SENSE_AUTH_OVERRIDE="$conf"
}
```

Run `sense-env` once in a terminal, and both `sense_util.py` and your own Python scripts in that terminal use the token. The file deliberately holds only the access token, not the refresh token. When the 40 minutes run out, the client stops with `ACCESS_TOKEN invalid. No REFRESH_TOKEN available`; run `sense-env` again and it picks up a refreshed token. The file is a bearer credential while it is valid, so keep it out of Git and out of shared directories.

Service accounts that cannot use a browser can still put `USERNAME`, `PASSWORD`, and `SECRET` in the YAML file instead; the [client README](https://github.com/sdn-sense/sense-o-py-client#readme) has that template.

### Check that it works

Listing domains is a good first call. It exercises authentication and returns quickly:

```bash
sense-env && sense_util.py --discover domain_list
```

Every `--discover` query prints JSON, so the examples below pipe it through [`jq`](https://jqlang.org/) to pull out the fields that matter. In Python, the same queries are methods on `DiscoverApi`, and they return parsed JSON:

```python
from sense.client.discover_api import DiscoverApi

discover = DiscoverApi()
domains = discover.discover_domains_get()
```

## Find all sitenames and drivers

### Sitenames

`domain_list` returns one entry per topology domain known to the orchestrator, with a `domain_uri` and a `domain_name`:

```bash
sense_util.py --discover domain_list \
  | jq -r '.domains[] | [.domain_name, .domain_uri] | @tsv' \
  | sort
```

```text
n/a                    urn:ogf:network:a.example.net:2026
n/a                    urn:ogf:network:b.example.net:2026
transit-topo           urn:ogf:network:transit.example.net:2026
```

Research networks fill in `domain_name` with their topology name, but SiteRM domains report `n/a`. A SiteRM site publishes its sitename as a metadata record instead, so look it up there. One sitename:

```bash
sense_util.py --discover lookup_metadata=T2_SITE_A
```

```json
{
  "results": [
    {
      "resource": "urn:ogf:network:a.example.net:2026:service+metadata:sitename",
      "name/tag/value": "T2_SITE_A"
    }
  ]
}
```

The domain URN is the part of `resource` before `:service+metadata:sitename`. To list every sitename and its domain in one call, search the `/sitename` metadata with a regular expression:

```python
from sense.client.discover_api import DiscoverApi

discover = DiscoverApi()
found = discover.discover_lookup_name_get(".*", search="metadata", type="/sitename", regex=True)
for result in sorted(found.get("results", []), key=lambda r: r["name/tag/value"]):
    domain = result["resource"].split(":service+metadata:")[0]
    print(result["name/tag/value"], domain, sep="\t")
```

```text
T2_SITE_A    urn:ogf:network:a.example.net:2026
T2_SITE_B    urn:ogf:network:b.example.net:2026
```

### Drivers

"Driver" means two different things in SENSE.

The orchestrator talks to each domain through a driver instance: `SiteRMDriver` for SiteRM sites, `NSIDriver` for NSI networks, and others for AL2S, FABRIC, AtlanticWave-SDX, and the clouds. `sense_util.py` has no flag for the driver list, so call it through the client's request wrapper:

```python
from sense.client.requestwrapper import RequestWrapper

client = RequestWrapper()
for driver in client.request("GET", "/driver/"):
    print(driver["topologyUri"], driver["driverEjbPath"], driver["status"], driver["health"], sep="\t")
```

```text
urn:ogf:network:a.example.net:2026         java:module/SiteRMDriver   PLUGGED     HEALTHY
urn:ogf:network:old.example.net:2020       java:module/SiteRMDriver   UNPLUGGED   UNKNOWN
urn:ogf:network:transit.example.net:2026   java:module/NSIDriver      PLUGGED     HEALTHY
```

The list includes unplugged and disabled drivers. Only `PLUGGED` drivers feed the topology that requests are computed against; `client.request("GET", "/driver/active")` returns just their topology URIs.

Inside a site, SiteRM talks to network devices through a backend plugin set in the site's configuration in [rm-configs](https://github.com/sdn-sense/rm-configs). `plugin: ansible` pushes configuration through the SENSE Ansible collections (`sense.dellos10`, `sense.sonic`, `sense.junos`, and the others on the [supported network devices]({{ '/getting-started/install-supported-network-devices/' | relative_url }}) page). `plugin: raw` reads the switch description from YAML files and does not configure a device. A quick way to see which backend each site uses is to search a local checkout:

```bash
git clone https://github.com/sdn-sense/rm-configs.git
grep -rn "^  plugin:" rm-configs/*/FE/main.yaml
```

## Find endpoint URNs

A terminal `uri` in a request must be a port or host interface that the domain advertises right now. There are four ways to find one, from quickest to most complete.

### Look up a name you already know

If you know the host name, look it up. The lookup matches the resource's exact `nml:name` and returns the URI in `resource`. SiteRM prefixes host names with the sitename, so ask for `<sitename>:<hostname>`:

```bash
sense_util.py --discover lookup_name=T2_SITE_A:dtn-01.a.example.net \
  | jq -r '.results[] | [.resource, ."name/tag/value"] | @tsv'
```

```text
urn:ogf:network:a.example.net:2026:dtn-01.a.example.net    T2_SITE_A:dtn-01.a.example.net
```

A name with no exact match makes the server return an HTTP 500 error that mentions `no required reqsult for manifest query`, so the bare host name `dtn-01.a.example.net` fails. For a partial name, or to see every named resource of a site, use the Python API with `regex=True`:

```python
from sense.client.discover_api import DiscoverApi

discover = DiscoverApi()
found = discover.discover_lookup_name_get("^T2_SITE_A:dtn-", search="name", regex=True)
for result in found.get("results", []):
    print(result["resource"], result["name/tag/value"], sep="\t")
```

To confirm which domain a URI belongs to, ask for its root URI:

```bash
sense_util.py --discover lookup_rooturi=urn:ogf:network:a.example.net:2026:dtn-01.a.example.net
```

### Read the domain's peer points

`domain_info` lists `peer_points`: the ports where this domain connects to a neighbor. Each entry has the local `port_uri` and `port_name`, the free VLANs in `port_vlan_pool`, the advertised `port_capacity`, and the matching `peer_uri`, `peer_vlan_pool`, and `peer_capacity` on the other side. `--discover domain_peers=<domain>` returns the same list without the rest of the domain:

```bash
sense_util.py --discover domain_peers=urn:ogf:network:a.example.net:2026 \
  | jq -r '.peer_points[] | [.port_uri, .port_vlan_pool, .peer_uri] | @tsv'
```

`domain_info` can also return `edge_points`, but only for ports that advertise an IPv4 floating-IP pool. Those are mostly cloud attachments, so a SiteRM domain's response usually has no `edge_points` key at all.

### List every port in a domain

A SPARQL query sent through the manifest API lists every port the domain's nodes expose, both switch ports and host interfaces, without creating an instance. The angle brackets around the domain URI are XML-escaped because the client wraps the template in XML:

```python
import json
from sense.client.workflow_combined_api import WorkflowCombinedApi

domain = "urn:ogf:network:a.example.net:2026"
sparql = ("SELECT ?port WHERE { &lt;" + domain + "&gt; nml:hasNode ?node. "
          "?node nml:hasBidirectionalPort ?port. }")
template = {"Ports": [{"URI": "?port?", "sparql-ext": sparql, "required": "true"}]}

manifest = WorkflowCombinedApi().manifest_create(json.dumps(template))
ports = json.loads(manifest["jsonTemplate"]).get("Ports", [])
for port in ports:
    print(port["URI"])
```

```text
urn:ogf:network:a.example.net:2026:switch_s0:Ethernet_1-1-2
urn:ogf:network:a.example.net:2026:switch_s0:Port-channel_43
urn:ogf:network:a.example.net:2026:dtn-01.a.example.net:enp1s0np0
```

Like the name lookup, the query fails with an HTTP 500 error when it matches nothing, for example when the domain URN is mistyped.

### Use the portal

The [SENSE portal](https://sense.es.net/) shows the same model with names and VLAN ranges. It is the fastest way to browse when you do not know what to look for, and the SiteRM [topology view]({{ '/operational/topology-view/' | relative_url }}) shows the site's side of it.

## Find address pools

Two different things are called a pool, and they go in different parts of a request.

### Pools for `ip_address_pool`

The `ip_address_pool.name` field in a request names a pool in the SENSE-O address manager. List all pools with their type and range:

```python
from sense.client.requestwrapper import RequestWrapper

for pool in RequestWrapper().request("GET", "/address/pool"):
    print(pool["name"], pool["type"], pool["pool"])
```

```text
Example-IPv4-Test-Pool          IPv4   192.0.2.0/25,192.0.2.128/25
Example-IPv6-Pool               IPv6   2001:db8:100::/48
Example-Site_BGP_Subnet_Pool    IPv6   2001:db8:10::/64,2001:db8:11::/64
```

A pool can hold several ranges, separated by commas.

The list shows every pool, but allocating from one can still be restricted to some accounts. If a request fails on a pool you can see, ask the SENSE operators for access. A service profile may already fix the pool for you; `sense_util.py -p -u <PROFILE_UUID>` prints the profile, including any `ip_address_pool` it sets.

### A site's routed IPv6 prefixes

For Layer 3 requests, each terminal's `ipv6_prefix_list` must come from prefixes the site lets SENSE advertise. SiteRM publishes them on the site's routing service, and `domain_ipv6pool` returns them:

```bash
sense_util.py --discover domain_ipv6pool=urn:ogf:network:a.example.net:2026 \
  | jq -r '.routing[] | [.service_uri, .ipv6_subnet_pool] | @tsv'
```

These prefixes belong in `ipv6_prefix_list`, not in `ip_address_pool`. The BGP peering subnet still comes from an address-manager pool.

## Find the maximum bandwidth between two endpoints

`port_capacity` gives an upper bound for one port. The figure that matters is what SENSE-O can reserve along a whole computed path, after every existing reservation on it. Ask for it with a query attached to the intent. The client sends the query with a compute, SENSE-O computes the path, and the response reports the result.

Two queries do this:

- `maximum-bandwidth` returns the reservable bandwidth on the computed path now.
- `total-block-maximum-bandwidth` returns the most bandwidth that is free for the whole window from `start-after` to `end-before`. Leave out `start-after` to start the window now; when you set it, use the time formats from the scheduling section below (`"now"` is rejected).

For both, SENSE-O replaces the connection's `bandwidth` block with an `anyAvailable` placeholder while it computes, so the value in the file does not limit the answer. The query's `name` must match the connection's `name`.

```json
{
  "service": "dnc",
  "alias": "max-bw-query",
  "data": {
    "type": "Multi-Path P2P VLAN",
    "connections": [
      {
        "name": "Connection 1",
        "bandwidth": {
          "qos_class": "guaranteedCapped",
          "capacity": "1000"
        },
        "terminals": [
          {
            "uri": "urn:ogf:network:a.example.net:2026:dtn-01.a.example.net",
            "vlan_tag": "any"
          },
          {
            "uri": "urn:ogf:network:b.example.net:2026:dtn-02.b.example.net",
            "vlan_tag": "any"
          }
        ]
      }
    ]
  },
  "queries": [
    {
      "ask": "total-block-maximum-bandwidth",
      "options": [
        {
          "name": "Connection 1",
          "end-before": "+24h"
        }
      ]
    }
  ]
}
```

With no `start-after`, the window starts now, and `end-before` counts from that start, so the window is the next 24 hours. For an answer about the present only, replace the query with `{"ask": "maximum-bandwidth", "options": [{"name": "Connection 1"}]}`.

The query is answered during compute, which creates an instance. This script prints the result and then deletes the instance, so nothing is left behind:

```python
import json
from sense.client.workflow_combined_api import WorkflowCombinedApi

with open("max-bw-query.json", encoding="utf-8") as fd:
    intent = json.load(fd)

workflow = WorkflowCombinedApi()
workflow.instance_new()
try:
    response = workflow.instance_create(json.dumps(intent))
    for query in response.get("queries", []):
        for result in query.get("results", []):
            bps = int(result.get("bandwidth", 0))
            print(f'{query["asked"]}: {result["name"]} -> {bps // 1_000_000} Mbps')
finally:
    workflow.instance_delete()
```

```text
total-block-maximum-bandwidth: Connection 1 -> 99000 Mbps
```

The `bandwidth` result is in bits per second; the script converts it to Mbps. With `sense_util.py --compute -f max-bw-query.json` you get the same `queries` block inside the printed response, but you then have to delete the computed instance yourself with `sense_util.py -D -u <INSTANCE_UUID>`, which asks you to confirm with `Y`. The UUID is the `service_uuid` in the compute output.

Treat the answer as a snapshot. Another request can take part of that capacity a minute later, and the number describes only the path SENSE-O picked for this compute. Use it to choose the `capacity` for a new intent, with some headroom below the reported maximum.

## Schedule a service: tomorrow at 9 am for 24 hours

A connection takes a `schedule` block with a `start` and either an `end` or a `duration`. SENSE-O validates each field against a fixed pattern and rejects the whole request if one does not match:

| Field | Accepted forms | Examples |
| --- | --- | --- |
| `start`, `end` | Absolute UTC time with milliseconds, or an offset of days, hours, and minutes | `"2026-11-24T15:00:00.000Z"`, `"+2h"`, `"+1d:6h"`, `"+30m"` |
| `duration` | Days, hours, minutes, and seconds, with no `+` | `"24h"`, `"1d"`, `"2h:30m"` |

To start immediately, leave `start` out; the word `"now"` fails validation. A relative `start` counts from the moment you submit. A relative `end` counts from the start time, not from now, so `"start": "+2h", "end": "+1h"` is a one-hour window that opens in two hours.

"Tomorrow at 9 am" is a clock time, so a relative offset like `+1d` will not do: it means 24 hours from the moment you submit. Use an absolute start written in UTC with a trailing `Z`. The pattern has no room for an offset like `-06:00`, and a timestamp without the `Z` is read in the orchestrator's time zone, which may not be yours.

Scheduling only works with a bandwidth reservation. The connection's `qos_class` must be `guaranteedCapped`, `softCapped`, or `anyAvailable`, with a `capacity`; a `bestEffort` connection with a schedule fails to compute.

Start from a request file with a placeholder start time:

```json
{
  "service": "dnc",
  "alias": "scheduled-24h-transfer",
  "data": {
    "type": "Multi-Path P2P VLAN",
    "connections": [
      {
        "name": "Connection 1",
        "bandwidth": {
          "qos_class": "guaranteedCapped",
          "capacity": "10000"
        },
        "schedule": {
          "start": "<START_TIME>",
          "duration": "24h"
        },
        "terminals": [
          {
            "uri": "urn:ogf:network:a.example.net:2026:dtn-01.a.example.net",
            "vlan_tag": "any",
            "assign_ip": false
          },
          {
            "uri": "urn:ogf:network:b.example.net:2026:dtn-02.b.example.net",
            "vlan_tag": "any",
            "assign_ip": false
          }
        ]
      }
    ]
  }
}
```

Generate tomorrow's 9:00 in your local time zone and convert it to UTC. Python handles daylight saving changes and works the same on Linux and macOS:

```bash
START=$(python3 -c 'from datetime import datetime, timedelta, timezone; t = (datetime.now() + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0); print(t.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z"))')
echo "$START"
```

```text
2026-11-24T15:00:00.000Z
```

That is 9:00 in US Central time. Write it into the request and compute:

```bash
jq --arg start "$START" '.data.connections[0].schedule.start = $start' \
  scheduled.json > scheduled-ready.json
sense_util.py --compute -f scheduled-ready.json
```

```text
computed service instance: {"service_uuid": "<INSTANCE_UUID>", "intent_uuid": "<INTENT_UUID>", "queries": []}
```

Check the computed plan, then provision it with the `service_uuid`:

```bash
sense_util.py --provision -u <INSTANCE_UUID>
```

Provisioning now reserves the bandwidth for tomorrow's window; it does not light the path today. SiteRM checks each change's lifetime and leaves it inactive until the start time, then treats it as ended after the end time. You can combine a schedule with the bandwidth query above: put the `schedule` block in the intent and ask `total-block-maximum-bandwidth` with matching `start-after` and `end-before` to see what is free during that window before you pick a `capacity`.

When the window is over, cancel and delete the instance so its record and any held addresses are released:

```bash
sense_util.py -d -u <INSTANCE_UUID>
```

## Quick reference

| Question | Command or call | Field to read |
| --- | --- | --- |
| Which domains exist? | `sense_util.py --discover domain_list` | `domains[].domain_uri` |
| Which SiteRM sitenames exist? | metadata lookup with `type="/sitename"` | `results[]."name/tag/value"`, `resource` |
| Which drivers does SENSE-O run? | `GET /driver/` | `topologyUri`, `driverEjbPath`, `status` |
| Which device backend does a site use? | `plugin` in rm-configs `FE/main.yaml` | `ansible` or `raw` |
| What is the URI for this host? | `--discover lookup_name=<sitename>:<host>` | `results[].resource` |
| Where does a domain connect to its neighbors? | `--discover domain_peers=<domain>` | `peer_points[]` |
| Which pools can `ip_address_pool` name? | `GET /address/pool` | `name`, `type`, `pool` |
| Which IPv6 prefixes can a site route? | `--discover domain_ipv6pool=<domain>` | `routing[].ipv6_subnet_pool` |
| How much can this path carry? | `maximum-bandwidth` or `total-block-maximum-bandwidth` query | `queries[].results[].bandwidth` (bps) |
| How do I book a window? | `schedule` with an absolute `start` and a `duration` | computed plan |

With these lookups, every placeholder in the [request examples]({{ '/blog/sense-network-service-examples/' | relative_url }}) can be replaced with a value the orchestrator advertises today.
