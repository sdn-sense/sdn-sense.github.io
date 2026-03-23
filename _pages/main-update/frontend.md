---
title: "Frontend Update"
layout: single
classes: wide
permalink: "/main-update/frontend/"
author_profile: false
sidebar:
  nav: "docs"
---

## Information

* **Frontend** is responsible for: communication with Orchestrator(s), Accept deltas, Prepare Model, Control switches on LAN, Get all configuration from all DTNs/Agents. Minimum one Frontend is required for a single domain.

* **Installation type supported**: **Docker**, **Podman**, **Kubernetes**
* **Certificates**: Frontend requires cert, key certificates for its services. (Let's Encrypt/InCommon)
* **Networking**: Frontend requires some ports open (Can be limited to a specific list of nodes. See list [here](/install-quick-start/#firewall-requirements)

## SiteRM-FE Installation First time (Docker/Podman)

* Prerequisites:
  * **Make sure you have docker/podman installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash for Frontend Service). MD5 is optional - and if not specified, SiteRM will compute md5(hostname) by default**
  * **You have Certificate, Key generated.**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* **It is recomended to use stable tag version. master branch is used as a developement. Look at Readme file [here](https://github.com/sdn-sense/siterm/blob/master/README.MD) to identify stable version.** Use `git fetch --all --tags` and `git checkout <tag>`
* Modify FE Contig File in cloned repo, path:`fe/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for Frontend (based on your `mapping.yalm` file).
* Modify Environment file in cloned repo, path:`fe/conf/environment` and change `MARIA_DB_PASSWORD`. This can be anything secure and should not change between redeployments.
* Prepare ansible configuration file at `fe/conf/etc/ansible-conf.yaml`. For more details, see [Supported network devices](/getting-started/install-supported-network-devices/) page
* Copy Certificates to correct location:
  * Certificate - copy to `fe/conf/etc/httpd/certs/cert.pem` and `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/httpd/certs/privkey.pem` and `fe/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd fe/docker/ && ./run.sh -i latest`
* **NOTE** -i (image) is `latest` (most stable image).
* **NOTE** If your network device use only IPv6 for access, add `-n host` parameter to Start the service command. Full command will be: `cd fe/docker/ && ./run.sh -i latest -n host`

## SiteRM-FE Upgrade (Docker/Podman)

* Please look for any changes required to support new release in release notes: [https://github.com/sdn-sense/siterm/tags](https://github.com/sdn-sense/siterm/tags)
* Pull latest runtime version by issuing: `git pull` inside siterm-startup repo directory;
* **It is recomended to use stable tag version. master branch is used as a developement. Look at Readme file [here](https://github.com/sdn-sense/siterm/blob/master/README.MD) to identify stable version.** Use `git fetch --all --tags` and `git checkout <tag>`
* Once all changes are done as noted in a new release description, proceed to restart the service: `cd fe/docker/ && ./restart-new-image.sh -i latest`. p.s. if you used `-n host` - dont forget to add it too.

## SiteRM-FE Installation First time (Kubernetes cluster with Helm)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and know namespace you want to use for deployment.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will compute md5(hostname) by default**
  * **You have Certificate, Key available and valid (or you can use HELM Chart Certificate section if have cert-manager available).**

* Get the following override values file: [values.yaml](https://raw.githubusercontent.com/sdn-sense/helm-charts/refs/heads/main/siterm-fe/values.yaml)
* Modify the downloaded file and specify the SiteName and MD5 parameters for that Specific Frontend and or any other parameters needed, e.g. Certificate Issuer details.
* If done first time, install helm repo: `helm repo add siterm https://sdn-sense.github.io/helm-charts`
* Update to latest helm repo charts: `helm repo update`
* Install the helm chart on your Kubernetes cluster: `helm install siterm siterm/siterm-fe -f values.yaml`

## SiteRM-FE Upgrade (Using Kubernetes with Helm)

* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/releases](https://github.com/sdn-sense/siterm/releases)
* Update to latest helm repo charts: `helm repo update`
* Modify the values.yaml file with new parameters or changes as per new release. (if needed)
* Upgrade the helm chart on your Kubernetes cluster: `helm install siterm siterm/siterm-fe -f values.yaml`

## Check if services are running correctly

After an upgrade, confirm the Frontend is healthy before informing the SENSE team:

```bash
# Docker/Podman — enter the container
docker exec -it siterm-fe bash

# Run health checks
siterm-readiness
siterm-liveness

# Kubernetes
kubectl exec -n sense <siterm-fe-pod> -- siterm-readiness
kubectl exec -n sense <siterm-fe-pod> -- siterm-liveness
```

**Verify the Web UI** is accessible at `https://<your-frontend-fqdn>:<port>` and the topology and model sections load correctly.

**Check the release notes** for any configuration changes required for the new version: [Release Notes](/docs/release-notes/).

See [SiteRM Operations](/operational/siterm-operations/) for full details on CLI commands and monitoring.