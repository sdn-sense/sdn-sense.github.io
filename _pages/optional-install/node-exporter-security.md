---
title: "Node Exporter Security"
layout: single
classes: wide
permalink: "/optional-install/node-exporter-security/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

`node_exporter` exposes host-level metrics on port **9100** (default). While this is normal Prometheus behavior, security scanners frequently flag this port due to the presence of the `/debug/pprof` endpoint — a Go runtime profiling interface that is compiled into most Go binaries, including `node_exporter`.

**This is not a vulnerability**, but many compliance validators and vulnerability scanners treat any exposed `pprof` endpoint as a finding. The recommended approach is to restrict port 9100 to only the SiteRM Frontend (FE) host and enable the [passthrough mechanism](#node-exporter-passthrough-via-frontend) so that external monitoring systems never reach the agent directly.

---

## Architecture: Passthrough via Frontend

SiteRM's Frontend acts as a transparent proxy for node_exporter metrics. External monitoring systems (e.g., AutoGOLE Prometheus) scrape the Frontend endpoint, which forwards the request to the agent's `node_exporter` and returns the response. The agent never needs to expose port 9100 to the public internet or monitoring networks.

```
AutoGOLE Prometheus
        │
        ▼
SiteRM Frontend (HTTPS :8443)
  GET /api/{sitename}/monitoring/prometheus/passthrough/{hostname}
        │
        │  (internal HTTP, port 9100, restricted by firewall)
        ▼
Agent node_exporter  http://{hostname}:9100/metrics
```

The Frontend looks up the agent's `node_exporter` URL from the host database (populated by the agent's `main.yaml` config). If `node_exporter_passthrough` is not enabled for a host, the endpoint returns HTTP 404.

---

## Step 1: Find the Frontend's IP Address

Log into the **SiteRM Frontend** host/pod/container and run the following to determine its outbound IP addresses. These are the IPs that the agent's firewall must allow on port 9100. Find all Frontend IPs.

```bash
# IPv4 address of the Frontend
curl -4 ifconfig.me

# IPv6 address of the Frontend
curl -6 ifconfig.me
```

Record both addresses. You will use them in the firewall rules on each agent/DTN host.

---

## Step 2: Restrict Port 9100 on the Agent

Run the following commands on each **agent/DTN host** where `node_exporter` is running. Replace `<FE_IPV4>` and `<FE_IPV6>` with the addresses found in Step 1.

### Option A: iptables

```bash
# Allow node_exporter from Frontend IPv4 only
iptables -A INPUT -p tcp --dport 9100 -s <FE_IPV4> -j ACCEPT

# Allow node_exporter from Frontend IPv6 only (if applicable)
ip6tables -A INPUT -p tcp --dport 9100 -s <FE_IPV6> -j ACCEPT

# Drop all other connections to port 9100
iptables -A INPUT -p tcp --dport 9100 -j DROP
ip6tables -A INPUT -p tcp --dport 9100 -j DROP
```

To make these rules persistent across reboots, save them:

```bash
# On RHEL/CentOS/Rocky
iptables-save > /etc/sysconfig/iptables
ip6tables-save > /etc/sysconfig/ip6tables

# On Debian/Ubuntu
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```

### Option B: nftables

```bash
# Create or add to your nftables ruleset
nft add table inet filter
nft add chain inet filter input '{ type filter hook input priority 0; }'

# Allow Frontend IPv4
nft add rule inet filter input ip saddr <FE_IPV4> tcp dport 9100 accept

# Allow Frontend IPv6 (if applicable)
nft add rule inet filter input ip6 saddr <FE_IPV6> tcp dport 9100 accept

# Drop all other connections to port 9100
nft add rule inet filter input tcp dport 9100 drop
```

To persist nftables rules:

```bash
nft list ruleset > /etc/nftables.conf
systemctl enable nftables
```
---

## Step 3: Configure the Agent for Passthrough

Edit your agent's `main.yaml` in the remote Git config repository. Under the `general` section, add or update:

```yaml
general:
  sitename: <SITENAME>
  # ... other config ...

  # Hostname or URL of the local node_exporter.
  # The Frontend will prepend 'http://' and append '/metrics' if missing.
  # Examples:
  #   node_exporter: "localhost:9100"
  #   node_exporter: "http://127.0.0.1:9100"
  #   node_exporter: "http://127.0.0.1:9100/metrics"
  node_exporter: "localhost:9100"

  # Enable passthrough. When true, the Frontend proxies requests to
  # this node_exporter endpoint. External systems must NOT access
  # port 9100 directly — they use the Frontend passthrough endpoint instead.
  node_exporter_passthrough: true
```

**Config key details:**

| Key | Type | Description |
|-----|------|-------------|
| `node_exporter` | string | Hostname/URL of the node_exporter endpoint reachable from the Frontend. The Frontend normalizes this: adds `http://` prefix if no scheme is present, adds `/metrics` suffix if missing. |
| `node_exporter_passthrough` | boolean | Must be `true` to enable the Frontend passthrough. If `false` or absent, the passthrough endpoint returns HTTP 404. |

After updating the config, the agent will pick up the new settings on its next config-refresh cycle. The Frontend will then be able to serve metrics via the passthrough endpoint.

---

## Step 4: Verify the Passthrough

From any host that can reach the SiteRM Frontend, verify that metrics are accessible through the passthrough endpoint (requires authentication and token):

```bash
curl -k https://<FE_HOST>:8443/api/<SITENAME>/monitoring/prometheus/passthrough/<AGENT_HOSTNAME>
```

You should see Prometheus text-format output beginning with lines like:

```
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
...
```

If you get HTTP 404, check:
- The `hostname` in the URL matches the hostname the agent registered with (check the `hosts` table or the FE API).
- `node_exporter_passthrough: true` is set in the agent's `main.yaml`.
- The agent has synced its config (restart the agent if needed).

If you get HTTP 502, check:
- The Frontend can reach port 9100 on the agent host (firewall rule for the FE IP is in place).
- `node_exporter` is running on the agent.
- The `node_exporter` value in `main.yaml` uses a hostname/IP reachable from the Frontend, not `localhost` (unless the FE and agent are on the same host).

---

## Summary

| What to do | Where |
|---|---|
| Find Frontend IP | On the Frontend host: `curl -4 ifconfig.me` / `curl -6 ifconfig.me` |
| Restrict port 9100 | On each agent/DTN: iptables or nftables, allow only Frontend IP |
| Configure passthrough | Agent `main.yaml`: set `node_exporter` and `node_exporter_passthrough: true` |
| Verify | `curl -k https://<FE>:8443/api/<SITE>/monitoring/prometheus/passthrough/<HOST>` |

