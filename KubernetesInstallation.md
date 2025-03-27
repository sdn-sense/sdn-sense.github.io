[[Home](index.md)] [[Installation Information](Installation.md)] [[Docker Install](DockerInstallation.md)] [[Kubernetes Install](KubernetesInstallation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)] [[Debuggging](Debuging.md)]

# General information
Site resource manager require several Services (Frontend and Agent). 
* **Frontend** is responsible for: communication with Orchestrator(s), Accept deltas, Prepare Model, Control switches on LAN, Get all configuration from all DTNs/Agents. Minimum one Frontend is needed for a single domain.
* **Agent** is responsible for: gathering DTN Information, creating vlan interfaces, applying QOS.  

Please consult individual cases with the SENSE team before deploying: sense-all@googlegroups.com or create an issue at [here](https://github.com/sdn-sense/ops/issues/new) with the title **"[NEW Site] ..."**

In case have issues with any SENSE SiteRM Software, please create a ticket [here](https://github.com/sdn-sense/ops) or send an email to [sense-all@googlegroups.com](sense-all@googlegroups.com)

# Before start
**Supported architectures**: amd64/x86_64 and ppc64le (beta).

**Frontend**: Each site requires 1 Frontend.
* **Installation type supported**: **Docker** or **Kubernetes**
* **Certificates**: Frontend requires cert, key certificates for its services. (Let's encrypt/Incommon)
* **Networking**: Frontend requires some ports open (Can be limited to a specific list of nodes, the list below): 
  * **sense-o.es.net** - Production Orchestrator. (Port 8080, 8443)
  * **sense-o-dev.es.net** - Development Orchestrator. (Port 8080, 8443)
  * **k8s-igrok-0[12345678].calit2.optiputer.net (67.58.53.139, 67.58.53.14[0123456])** - SENSE Monitoring and Alarming service. (Port 8080, 8443, 9100)
  * **Local Agents** - Any Agent you deploy will need access Frontend.

**Agent**: Runs on each DTN you want SENSE to control, monitor. It will register and communicate with Frontend for control, monitoring.
* **Installation type supported**: **Docker** or **Kubernetes** 
* **Certificate**: The agent requires a host certificate and key pair. (Let's encrypt/Incommon)
* **Networking**: No ports open needed (see exception below for monitoring)
* **Monitoring**: SENSE Uses Prometheus and node_exporter to monitor all DTN deployments. If you want your DTN to be monitored and alerted - please ensure you have node_exporter installed and the port open. 

# SiteRM-Frontend and SiteRM-Agent configuration
SiteRM-FE and SiteRM-Agent Configuration files are kept on GitHub repo [here](https://github.com/sdn-sense/rm-configs). Each SiteRM Service (Frontend/Agent) pull from Github repo configuration files once an hour and use the latest configuration. Please refer to this [link](https://github.com/sdn-sense/rm-configs) for Frontend and Agent configuration and it's parameters, examples. 

# SiteRM-FE Installation First time (Kubernetes cluster with Helm)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and know namespace you want to use for deployment.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key available and valid (or you can use HELM Chart Certificate section if have cert-manager available).**

* Get the following override values file: `https://raw.githubusercontent.com/sdn-sense/helm-siterm-fe/main/values.yaml`
* Modify the downloaded file and specify the SiteName and MD5 parameters for that Specific Frontend and or any other parameters needed, e.g. Certificate Issuer details.
* If done first time, install helm repo: `helm repo add siterm-fe https://sdn-sense.github.io/helm-siterm-fe`
* Update to latest helm repo charts: `helm repo update`
* Install the helm chart on your Kubernetes cluster: `helm install siterm-fe siterm-fe/siterm-fe -f values.yaml`

# SiteRM-FE Upgrade (Using Kubernetes with Helm)

* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/releases](https://github.com/sdn-sense/siterm/releases)
* Update to latest helm repo charts: `helm repo update`
* Modify the values.yaml file with new parameters or changes as per new release. (if needed)
* Upgrade the helm chart on your Kubernetes cluster: `helm install siterm-fe siterm-fe/siterm-fe -f values.yaml`

# SiteRM-Agent Installation (Kubernetes cluster with Helm)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and namespace you want to use.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key generated or if you have Issuer/ClusterIssuer on your Kubernetes cluster, you can use HELM to generate new certificates**

* Get the following override values file: `https://raw.githubusercontent.com/sdn-sense/helm-siterm-agent/main/values.yaml`
* Modify the downloaded file and specify the SiteName and MD5 parameters for that Specific Agent/DTN and or any other parameters needed, e.g. Certificate Issuer details.
* If done first time, install helm repo: `helm repo add siterm-agent https://sdn-sense.github.io/helm-siterm-agent`
* Update to latest helm repo charts: `helm repo update`
* Install the helm chart on your Kubernetes cluster: `helm install siterm-agent siterm-agent/siterm-agent -f values.yaml`

# SiteRM-Agent Upgrade (Using Kubernetes cluster with Helm)

* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/releases](https://github.com/sdn-sense/siterm/releases)
* Update to latest helm repo charts: `helm repo update`
* Modify the values.yaml file with new parameters or changes as per new release. (if needed)
* Upgrade the helm chart on your Kubernetes cluster: `helm install siterm-agent siterm-agent/siterm-agent -f values.yaml`

# DTNs Monitoring (to be run in parallel with SiteRM-Agent)
The node_exporter from Prometheus is designed to monitor the host system. If you start container for host monitoring, specify path.rootfs argument. This argument must match path in bind-mount of host root. The node_exporter will use path.rootfs as prefix to access host filesystem. There are several ways to allow SENSE team monitor DTNs:
* If you already have node_exporter running on DTN you dont need to install another one.
* To install node_exporter on bare metal, please follow official documentation here: [https://prometheus.io/docs/guides/node-exporter/](https://prometheus.io/docs/guides/node-exporter/)
* In case you dont want to install it on a bare metal machine, you can run node_exporter inside Kubernetes:
  * **Kubernetes** - example here: [https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/kubernetes](https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/kubernetes)
* **(Once deployed) - Please update your agent configuration on Config Git [here](https://github.com/sdn-sense/rm-configs) and specify config parameter `node_exporter` in `general` section.**
