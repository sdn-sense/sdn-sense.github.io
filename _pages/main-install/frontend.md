---
title: "Frontend Installation"
layout: single
classes: wide
permalink: "/main-install/frontend/"
author_profile: false
sidebar:
  nav: "docs"
---

## Information and Requirements

* **Frontend** is responsible for: communication with Orchestrator(s), Accept deltas, Prepare Model, Control switches on LAN, Get all configuration from all DTNs/Agents. Minimum one Frontend is required for a single domain.

* **Installation type supported**: **Docker**, **Podman**, **Kubernetes**
* **Certificates**: Frontend requires cert, key certificates for its services. (Make sure you have tls.crt and tls.key files in PEM format)
* **Networking**: Frontend requires some ports open (Can be limited to a specific list of nodes. See list [here](/install-quick-start/#firewall-requirements)

Choose the installation type, based on your Site's functionalities. In case you are not using Docker/Podman/Kubernetes at your site, easiest "path forward" is to use either Docker or Podman.

## SiteRM-FE Installation First time (Docker/Podman)

* Prerequisites:
  * **Make sure you have docker/podman installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash for Frontend Service). MD5 is optional - and if not specified, SiteRM will compute md5(hostname -f) by default**
  * **You have Certificate, Key ready.**

* Clone the following repo on the machine, where Frontend will be installed: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)

```bash
git clone https://github.com/sdn-sense/siterm-startup
```

* **It is recomended to use stable tag version. master branch is used for developement. Stable version is shown at the sidebar on the left** Use `git fetch --all --tags` and `git checkout <tag>`
* Modify FE Contig File in cloned repo, path:`fe/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for Frontend (based on your `mapping.yaml` file).
* Modify Environment file in cloned repo, path:`fe/conf/environment` and change `MARIA_DB_PASSWORD`. This can be anything secure and should not change between redeployments.
* Prepare ansible configuration file at `fe/conf/etc/ansible-conf.yaml`. For more details, see [Supported network devices](/getting-started/install-supported-network-devices/) page
* Copy Certificates to correct location:
  * Certificate - copy to `fe/conf/etc/httpd/certs/cert.pem` and `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/httpd/certs/privkey.pem` and `fe/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd fe/docker/ && ./run.sh -i latest`
* **NOTE** -i (image) is `latest` (most stable image).
* **NOTE** If your network device use only IPv6 for access, add `-n host` parameter to Start the service command. Full command will be: `cd fe/docker/ && ./run.sh -i latest -n host`

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

## Check if services are running correctly

**Docker/Podman:** Run these commands from inside the SiteRM Frontend container:

```bash
# Enter the Frontend container
docker exec -it siterm-fe bash

# Run the readiness check — confirms all internal services are ready
siterm-readiness

# Run the liveness check — confirms the service is alive
siterm-liveness

# If running on Kubernetes, you can trigger checks manually:
kubectl exec -n sense <siterm-fe-pod> -- siterm-readiness
kubectl exec -n sense <siterm-fe-pod> -- siterm-liveness
```

**Web UI:** Once the Frontend is running, open `https://<your-frontend-fqdn>:<port>` in your browser. You should see the SiteRM topology dashboard. If the page loads correctly, the service is operational.

**Verify Ansible connectivity to switches:**

```bash
# From inside the Frontend container, test Ansible can reach a configured switch
siterm-ansible-runner --printports

# For full debug output
siterm-ansible-runner --fulldebug
```

**Monitoring:** All SiteRM deployments are monitored by the Autogole Grafana dashboard. If your site is not yet registered, contact the SENSE team at sense-info@es.net. See [SiteRM Operations](/operational/siterm-operations/) for full details.