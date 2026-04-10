---
title: "Node Exporter Update"
layout: single
classes: wide
permalink: "/main-update/node-exporter/"
author_profile: false
sidebar:
  nav: "docs"
---

## SiteRM Node Monitoring

SiteRM does not "reinvent" the wheel and reuses tools already available for monitoring. The node_exporter from Prometheus is designed to monitor the host system. There are several ways to enable host monitoring for SENSE system:

* If you already have node_exporter running on DTN you dont need to install another one. Open Node Exporter port for SENSE Monitoring services. See Firewall requirements [here](/install-quick-start/#firewall-requirements)
* If you already have node_exporter running, proceed to Configure Host Monitoring

## Bare metal installation

* To install node_exporter on bare metal, please follow official documentation [here](https://prometheus.io/docs/guides/node-exporter/)
  * Please make sure that it uses `--path.rootfs=/host` and `--collector.netdev.address-info` flags for node_exporter if it is bare metal installation.
* Once deployed, Proceed to Configure Host Monitoring

## Docker/Podman installation

* SENSE provides helper scripts to run node_exporter inside the container. Please refer to the following [script](https://github.com/sdn-sense/siterm-startup/tree/master/node-exporter/docker) to run node_exporter inside the container.
* Once deployed, Proceed to Configure Host Monitoring

## Kubernetes installation

* Refer to Kubernetes node_exporter installation documentation. There are many tutorials available online.
* Once deployed, proceed to Configure Host monitoring

## Configure Host Monitoring

Update your agent configuration `main.yaml` file Remote Github repo and specify config parameter `node_exporter` in `general` section.

## Security: Restrict Port 9100 and Enable Passthrough

By default, `node_exporter` listens on port 9100 and is accessible to any host that can reach the DTN. Many security scanners flag this because `node_exporter` (like all Go binaries) exposes a `/debug/pprof` endpoint — this is not a real vulnerability, but it is commonly raised as a finding.

The recommended approach is to:

1. **Restrict port 9100** on the agent/DTN so that only the SiteRM Frontend IP is allowed to connect.
2. **Enable the passthrough** (`node_exporter_passthrough: true` in `main.yaml`) so that external monitoring systems scrape metrics through the Frontend proxy instead of accessing the agent directly.

See the full guide: [Node Exporter Security](/optional-install/node-exporter-security/)
