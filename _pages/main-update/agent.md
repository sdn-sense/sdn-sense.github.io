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
  * **Configuration files are present in the [SiteRM Configuration repo](https://github.com/sdn-sense/rm-configs) for your Site (Take a note of SiteName and MD5 Hash defined in mapping.yaml). MD5 is optional - and if not specified, SiteRM will compute md5(hostname) by default. See [Configuration Layout](/customization/configuration-layout/) for details.**
  * **You have Certificate, Key generated.**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* **It is recomended to use stable tag version. master branch is used as a developement. Look at Readme file [here](https://github.com/sdn-sense/siterm/blob/master/README.MD) to identify stable version.** Use `git fetch --all --tags` and `git checkout <tag>`
* Modify Agent Contig File in cloned repo, path:`agent/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for Specific Agent/DTN.
* Copy Certificates to config location:
  * Certificate - copy to `agent/conf/etc/secret-mount/tls.crt`
  * Key - copy to `agent/conf/etc/secret-mount/tls.key`
* Start the service: `cd agent/docker/ && ./run.sh -i latest`

## SiteRM-Agent Upgrade (Docker/Podman)

Please check the [Release Notes](/docs/release-notes/) for any configuration changes required for the new version before upgrading.

### Upgrading from 1.6.0 or later

Pull the latest image and restart:

```bash
cd agent/docker/ && ./restart-new-image.sh -i latest
```

### Upgrading from 1.5.x or older

The siterm-startup directory structure changed in 1.6.0 (certificate paths, mount names). A simple `git pull` is not sufficient — re-clone the repo and migrate your configuration:

1. **Re-clone siterm-startup and migrate config:**

   ```bash
   mv siterm-startup siterm-startup-old
   git clone https://github.com/sdn-sense/siterm-startup

   cd siterm-startup/agent/conf/etc/
   cp ~/siterm-startup-old/agent/conf/etc/siterm.yaml siterm.yaml
   # Certificates are now under secret-mount/ with new filenames
   cp ~/siterm-startup-old/agent/conf/etc/grid-security/hostcert.pem secret-mount/tls.crt
   cp ~/siterm-startup-old/agent/conf/etc/grid-security/hostkey.pem secret-mount/tls.key
   ```

2. **Stop and remove old containers and volumes, then start fresh:**

   ```bash
   docker ps -a
   docker stop <old-container-ids>
   docker rm <old-container-ids>
   docker volume ls
   docker volume remove <old-volume-names>

   cd ../../docker/
   ./restart-new-image.sh -i latest
   ```

3. **Verify** the Agent re-registered to the Frontend by checking the Frontend Web UI under **Frontend Configuration** — the Agent's hostname should appear with an up-to-date status.

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

* Please look for any changes required to support new release: [Release Notes](/docs/release-notes/)
* Update to latest helm repo charts: `helm repo update`
* Modify the values.yaml file with new parameters or changes as per new release. (if needed)
* Upgrade the helm chart on your Kubernetes cluster: `helm upgrade siterm siterm/siterm-agent -f values.yaml`

## Check if services are running correctly

After an upgrade, confirm the Agent is healthy:

```bash
# Docker/Podman — enter the Agent container
docker exec -it siterm-agent bash

# Run health checks
siterm-readiness
siterm-liveness

# Kubernetes
kubectl exec -n sense <siterm-agent-pod> -- siterm-readiness
kubectl exec -n sense <siterm-agent-pod> -- siterm-liveness
```

**Verify the Agent re-registered** to the Frontend by checking the Frontend Web UI under **Frontend Configuration** — the Agent's hostname should appear with an up-to-date status.

**Check the release notes** for any configuration changes required: [Release Notes](/docs/release-notes/).

See [SiteRM Operations](/operational/siterm-operations/) for full details.
