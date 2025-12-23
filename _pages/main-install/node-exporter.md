---
title: "Node Exporter Installation"
layout: single
classes: wide
permalink: "/main-install/node-exporter/"
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
