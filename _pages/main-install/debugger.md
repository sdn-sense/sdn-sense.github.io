---
title: "Debugger Installation"
layout: single
classes: wide
permalink: "/main-install/debugger/"
author_profile: false
sidebar:
  nav: "docs"
---

## Information

* **IMPORTANT To proceed with Debugger installation, you must already have SiteRM Frontend installed and operational. Please refer to this documentation for Frontend installation.**

* **Debugger** is responsible for issuing iPerf, FDT, Ping, Traceroute tests. This service is optional to run at the Sites. If it is deployed, it helps SENSE team and Network administrators to identify network problems quicker. It needs to run on each DTN along to an Agent container. In case of Kubernetes and Multus deployments, it is expected to run Debugger also in each of the Multus Network Namespaces (to allow issue L3 probes).

* **Installation type supported**: **Docker**, **Podman**, **Kubernetes**
* **Certificate**: The debugger requires a host certificate and key pair. (Let's Encrypt/InCommon). Can re-use same cert/key pair as Agent.
* **Networking**: No ports open needed

## SiteRM-Debugger Installation First time (Docker/Podman)

* Prerequisites:
  * **Make sure you have docker/podman installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will compute md5(hostname) by default**
  * **You have Certificate, Key generated**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* **It is recomended to use stable tag version. master branch is used as a developement. Look at Readme file [here](https://github.com/sdn-sense/siterm/blob/master/README.MD) to identify stable version.** Use `git fetch --all --tags` and `git checkout <tag>`
* Modify Debugger Contig File in cloned repo, path:`debugger/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for that Specific Agent/DTN.
* Copy Certificates to config location:
  * Certificate - copy to `debugger/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `debugger/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd agent/docker/ && ./run.sh -i latest`

## SiteRM-Debugger Upgrade (Docker/Podman)

* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/tags](https://github.com/sdn-sense/siterm/tags)
* **It is recomended to use stable tag version. master branch is used as a developement. Look at Readme file [here](https://github.com/sdn-sense/siterm/blob/master/README.MD) to identify stable version.** Use `git fetch --all --tags` and `git checkout <tag>`
* Pull latest runtime version by issuing: `git pull` inside siterm-startup repo directory;
* Once all changes are done as noted in a new release description, proceed to restart the service: `cd agent/docker/ && ./restart-new-image.sh -i latest`.

## SiteRM-Debugger Installation (Kubernetes cluster with Helm)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and namespace you want to use.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). Debugger does not require individual config file and can re-use same agent MD5**
  * **You have Certificate, Key generated or if you have Issuer/ClusterIssuer on your Kubernetes cluster, you can use HELM to generate new certificates**

* Download the following override values file: [values.yaml](https://github.com/sdn-sense/helm-charts/blob/main/siterm-debugger/values.yaml)
* Modify the downloaded file and specify the SiteName and MD5 parameters for that Specific Agent/DTN and or any other parameters needed, e.g. Certificate Issuer details.
* **IMPORTANT: In case deploying multiple debuggers and re-use same configuration file, make sure to specify `customPodName`. See details inside values.yaml file.**
* If done first time, install helm repo: `helm repo add siterm https://sdn-sense.github.io/helm-charts`
* Update to latest helm repo charts: `helm repo update`
* Install the helm chart on your Kubernetes cluster: `helm install siterm siterm/siterm-debugger -f values.yaml`

## SiteRM-Debugger Upgrade (Using Kubernetes cluster with Helm)

* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/releases](https://github.com/sdn-sense/siterm/releases)
* Update to latest helm repo charts: `helm repo update`
* Modify the values.yaml file with new parameters or changes as per new release. (if needed)
* Upgrade the helm chart on your Kubernetes cluster: `helm install siterm siterm-agent/siterm-debugger -f values.yaml`

## Check if services are running correctly

**Docker/Podman:** Run these from inside the Debugger container:

```bash
# Enter the Debugger container
docker exec -it siterm-debugger bash

# Run the readiness check
siterm-readiness

# Run the liveness check
siterm-liveness

# If running on Kubernetes:
kubectl exec -n sense <siterm-debugger-pod> -- siterm-readiness
kubectl exec -n sense <siterm-debugger-pod> -- siterm-liveness
```

**Verify Debugger registered to Frontend:** Open the SiteRM Frontend Web UI at `https://<frontend-fqdn>:<port>` and go to the **Debug** section. The Debugger for this DTN should be listed and available for ping, traceroute, and iperf3 tests.

**Test a debug action from the Web UI:**
1. Navigate to the Frontend Web UI
2. Go to **Debug** → **Ping**
3. Select the source DTN (the host running the Debugger)
4. Enter a destination IP address
5. Submit — the Debugger will execute the ping and return results

**Monitoring:** The Debugger is monitored alongside the Agent via Autogole. See [SiteRM Operations](/operational/siterm-operations/) for details.