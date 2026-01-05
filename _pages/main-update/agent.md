---
title: "Agent Update"
layout: single
classes: wide
permalink: "/main-update/agent/"
author_profile: false
sidebar:
  nav: "docs"
---

## Information

* **IMPORTANT To proceed with Agent installation, you must already have SiteRM Frontend installed and operational. Please refer to this documentation for Frontend installation.**

**SiteRM-Agent** runs on each DTN you want SENSE to control, monitor. It will register and communicate with Frontend for control and monitoring.

* **Installation type supported**: **Docker**, **Podman**, **Kubernetes**
* **Certificate**: The agent requires a host certificate and key pair. (Let's Encrypt/InCommon)
* **Networking**: No ports open needed (see exception below for monitoring)
* **Monitoring**: SENSE Uses Prometheus and node_exporter to monitor all DTN deployments. If you want your DTN to be monitored and alerted - please ensure you have node_exporter installed and the port open.

## SiteRM-Agent Installation First time (Docker/Podman)

* Prerequisites:
  * **Make sure you have docker/podman installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash defined in mapping.yaml). MD5 is optional - and if not specified, SiteRM will compute md5(hostname) by default**
  * **You have Certificate, Key generated.**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* **It is recomended to use stable tag version. master branch is used as a developement. Look at Readme file [here](https://github.com/sdn-sense/siterm/blob/master/README.MD) to identify stable version.** Use `git fetch --all --tags` and `git checkout <tag>`
* Modify Agent Contig File in cloned repo, path:`agent/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for Specific Agent/DTN.
* Copy Certificates to config location:
  * Certificate - copy to `agent/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `agent/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd agent/docker/ && ./run.sh -i latest`

## SiteRM-Agent Upgrade (Docker/Podman)

* Please look for any changes required to support new release.
* **It is recomended to use stable tag version. master branch is used as a developement. Look at Readme file [here](https://github.com/sdn-sense/siterm/blob/master/README.MD) to identify stable version.** Use `git fetch --all --tags` and `git checkout <tag>`
* Pull latest runtime version by issuing: `git pull` inside siterm-startup repo directory;
* Once all changes are done as noted in a new release description, proceed to restart the service: `cd agent/docker/ && ./restart-new-image.sh -i latest`.

## SiteRM-Agent Installation (Kubernetes cluster with Helm)

* Prerequisites:
  * **Make sure you have Kubernetes cluster up and running. You will need to have Kubernetes config and namespace you want to use.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will compute md5(hostname) by default**
  * **You have Certificate, Key generated or if you have Issuer/ClusterIssuer on your Kubernetes cluster, youcre can use HELM to create new certificates automatically**

* Download the following override values file: [values.yaml](https://raw.githubusercontent.com/sdn-sense/helm-siterm-agent/main/values.yaml)
* Modify the downloaded file and specify the SiteName and MD5 parameters for that Specific Agent/DTN and or any other parameters needed, e.g. Certificate Issuer details.
* If done first time, install helm repo: `helm repo add siterm https://sdn-sense.github.io/helm-charts`
* Update to latest helm repo charts: `helm repo update`
* Install the helm chart on your Kubernetes cluster: `helm install siterm siterm/siterm-agent -f values.yaml`

## SiteRM-Agent Upgrade (Using Kubernetes cluster with Helm)

* Please look for any changes required to support new release.
* Update to latest helm repo charts: `helm repo update`
* Modify the values.yaml file with new parameters or changes as per new release. (if needed)
* Upgrade the helm chart on your Kubernetes cluster: `helm install siterm siterm/siterm-agent -f values.yaml`

## Check if services are running correctly

siterm-readiness, siterm-liveness, webui-frontend TODO
