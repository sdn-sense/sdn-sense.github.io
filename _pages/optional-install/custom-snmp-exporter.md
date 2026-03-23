---
title: "Custom SNMP Exporter"
layout: single
classes: wide
permalink: "/optional-install/custom-snmp-exporter/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

SiteRM Frontend has **built-in SNMP monitoring** that collects topology information, interface stats, and MAC tables from your network switches. This is configured via the `snmp_params` section of your `ansible-conf.yaml` file (see [Enable Switch Control](/customization/enable-switch-control/)).

A **Custom SNMP Exporter** is an additional optional component — the [Prometheus SNMP Exporter](https://github.com/prometheus/snmp_exporter) — that exposes per-interface counters, optics, CPU/memory, and other OID-based metrics from your network devices in Prometheus format. These metrics can then be visualized in Grafana dashboards alongside other site monitoring data.

**When do you need a Custom SNMP Exporter?**
- You want per-interface byte/packet counters from switches in Prometheus/Grafana
- You want optical signal metrics (DWDM, SFP/QSFP power levels)
- You want CPU and memory utilization from switches in Prometheus format
- Your site monitoring infrastructure already uses Prometheus

---

## Architecture

```
Network Switches (SNMPv1/v2c/v3)
         │
         │ SNMP queries (UDP 161)
         ▼
Prometheus SNMP Exporter  ← scrape config
  (HTTP :9116)
         │
         │ /metrics
         ▼
   Prometheus Server
         │
         ▼
     Grafana
```

This complements (not replaces) the built-in SiteRM SNMP monitoring. SiteRM uses SNMP for topology discovery; the exporter provides time-series metrics for dashboards and alerting.

---

## Prerequisites

- A Linux host with network access to all managed switches on UDP port 161
- Docker or a native Go environment (for running the exporter)
- SNMP credentials for your switches (community string for v1/v2c, or user credentials for v3)
- A Prometheus server to scrape the exporter

---

## Step 1 — Install the Prometheus SNMP Exporter

### Option A — Docker (Recommended)

```bash
docker run -d \
  --name snmp-exporter \
  --restart always \
  -p 9116:9116 \
  -v /etc/snmp_exporter:/etc/snmp_exporter:ro \
  prom/snmp-exporter:latest
```

### Option B — Native Binary

Download the latest release from [https://github.com/prometheus/snmp_exporter/releases](https://github.com/prometheus/snmp_exporter/releases):

```bash
wget https://github.com/prometheus/snmp_exporter/releases/download/v0.26.0/snmp_exporter-0.26.0.linux-amd64.tar.gz
tar xzf snmp_exporter-0.26.0.linux-amd64.tar.gz
cp snmp_exporter-0.26.0.linux-amd64/snmp_exporter /usr/local/bin/

# Create systemd unit
cat > /etc/systemd/system/snmp-exporter.service <<'EOF'
[Unit]
Description=Prometheus SNMP Exporter
After=network.target

[Service]
User=snmp-exporter
ExecStart=/usr/local/bin/snmp_exporter --config.file=/etc/snmp_exporter/snmp.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now snmp-exporter
```

---

## Step 2 — Configure SNMP Module

The SNMP Exporter uses a `snmp.yml` configuration file that defines which OIDs to collect. You can generate it with the [snmp_exporter generator](https://github.com/prometheus/snmp_exporter/tree/main/generator) or use the pre-built modules provided in the container.

Create `/etc/snmp_exporter/snmp.yml` with modules for your switch vendor. Below are examples for the most common vendors:

### SNMPv2c Configuration (Dell OS9/OS10, Arista EOS, Cisco NX-OS)

```yaml
# /etc/snmp_exporter/snmp.yml
modules:
  if_mib:                           # Module name (referenced in Prometheus scrape config)
    walk:
      - 1.3.6.1.2.1.2.2            # ifTable
      - 1.3.6.1.2.1.31.1.1         # ifXTable (64-bit counters)
      - 1.3.6.1.2.1.1              # sysDescr, sysName, etc.
    auth:
      community: public             # Replace with your SNMP community string
    version: 2
    timeout: 10s
    retries: 3
```

### SNMPv3 Configuration (Juniper Junos)

```yaml
modules:
  junos_if:
    walk:
      - 1.3.6.1.2.1.2.2            # ifTable
      - 1.3.6.1.2.1.31.1.1         # ifXTable
      - 1.3.6.1.4.1.2636.3.1       # Juniper enterprise MIB
    auth:
      security_level: authPriv
      username: snmpv3user           # Replace with your SNMPv3 username
      password: authpassword         # Replace with auth password
      auth_protocol: SHA             # SHA or MD5
      priv_protocol: AES             # AES or DES
      priv_password: privpassword    # Replace with privacy password
    version: 3
    timeout: 15s
    retries: 3
```

**Supported `auth_protocol` values:** `SHA`, `MD5`
**Supported `priv_protocol` values:** `AES`, `DES`

---

## Step 3 — Configure Prometheus Scrape

In your Prometheus configuration (`prometheus.yml`), add a scrape job for each switch:

```yaml
scrape_configs:
  - job_name: 'snmp_switches'
    static_configs:
      - targets:
          - 192.168.1.10    # Dell switch 1
          - 192.168.1.11    # Dell switch 2
          - 192.168.1.20    # Arista switch
    metrics_path: /snmp
    params:
      module: [if_mib]      # Must match the module name in snmp.yml
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter-host:9116   # IP/hostname of the SNMP exporter

  - job_name: 'snmp_juniper'
    static_configs:
      - targets:
          - 192.168.1.30    # Juniper switch
    metrics_path: /snmp
    params:
      module: [junos_if]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter-host:9116
```

---

## Step 4 — Verify the Exporter

Test manually that the exporter can reach your switches:

```bash
# Query the exporter for a specific switch
curl "http://localhost:9116/snmp?target=192.168.1.10&module=if_mib"

# You should see Prometheus-format metrics like:
# ifInOctets{ifAlias="uplink",ifDescr="GigabitEthernet1/0/1",...} 1234567890
# ifOutOctets{...} 9876543210
```

Check that the exporter is running:
```bash
curl http://localhost:9116/metrics
```

---

## SNMP Configuration Reference

The SNMP exporter parameters map directly to the `easysnmp` session parameters used internally by SiteRM. The table below maps between the two:

| SNMP Version | SiteRM `ansible-conf.yaml` (`session_vars`) | SNMP Exporter `snmp.yml` (`auth`) |
|---|---|---|
| v1 | `version: 1`, `community: public` | `version: 1`, `community: public` |
| v2c | `version: 2`, `community: public` | `version: 2`, `community: public` |
| v3 | `version: 3`, `security_level: authNoPriv` | `version: 3`, `security_level: authNoPriv` |
| v3 | `version: 3`, `security_level: authPriv` | `version: 3`, `security_level: authPriv` |

For a full list of SNMPv3 session parameters supported by SiteRM's built-in SNMP client, see [easysnmp session documentation](https://easysnmp.readthedocs.io/en/latest/session_api.html).

---

## Useful OID References by Vendor

| Vendor | Key MIBs | OID Prefix |
|---|---|---|
| All (IF-MIB) | ifTable, ifXTable (interface counters) | `1.3.6.1.2.1.2.2`, `1.3.6.1.2.1.31` |
| Dell OS9/OS10 | Dell EMC OS MIBs | `1.3.6.1.4.1.674` |
| Arista EOS | Arista enterprise MIBs | `1.3.6.1.4.1.30065` |
| Juniper Junos | Junos enterprise MIBs | `1.3.6.1.4.1.2636` |
| Cisco NX-OS | Cisco enterprise MIBs | `1.3.6.1.4.1.9` |
| Azure SONiC | Standard IF-MIB + enterprise | `1.3.6.1.2.1.2.2` |

---

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| `Error scraping target` in Prometheus | SNMP community wrong or UDP 161 blocked | Verify community string; check firewall rules |
| Exporter returns empty metrics | No matching OIDs walked | Use a more general module or add the correct OID walk entries |
| SNMPv3 authentication errors | Wrong auth/priv protocol or password | Double-check `auth_protocol`, `priv_protocol`, and passwords |
| Timeout errors | Switch unreachable or overloaded | Increase `timeout` in snmp.yml; verify network path |
| Missing interface labels | `ifAlias` not configured on switch | Configure interface descriptions on the switch |

---

## Additional Resources

- [Prometheus SNMP Exporter GitHub](https://github.com/prometheus/snmp_exporter)
- [SNMP Exporter Generator](https://github.com/prometheus/snmp_exporter/tree/main/generator) — for building custom MIB-based modules
- [easysnmp Documentation](https://easysnmp.readthedocs.io/en/latest/) — used by SiteRM's built-in SNMP client
- [SiteRM Enable Switch Control](/customization/enable-switch-control/) — for built-in SiteRM SNMP configuration
