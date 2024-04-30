[[Home](index.md)]   [[Installation](Installation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)]
# Information

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

# Installation documentation

There are helper scripts in this repository: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
Supported installations:
* Docker
* Kubernetes (via HELM)

# SiteRM-FE Installation First time (Using Docker)
* Prerequisites:
  * **Make sure you have docker installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash for Frontend Service). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key available and valid.**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* Modify FE Contig File in cloned repo, path:`fe/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for Frontend.
* Modify Environment file in cloned repo, path:`fe/conf/environment` and change `MARIA_DB_PASSWORD`
* Prepare ansible configuration file at `fe/conf/etc/ansible-conf.yaml`. For more details, see here: [[Network Control via Ansible](NetControlAnsible.md)]
* Copy Certificates to correct location:
  * Certificate - copy to `fe/conf/etc/httpd/certs/cert.pem` and `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/httpd/certs/privkey.pem` and `fe/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd fe/docker/ && ./run.sh -i latest`
* **NOTE** -i (image) is `latest` (most stable image). Some sites might be asked to run a specific development/tagged version.
* **NOTE** If your network device use only IPv6 for access, add `-n host` parameter to Start the service command. Full command will be: `cd fe/docker/ && ./run.sh -i latest -n host`

# SiteRM-FE Upgrade (Using Docker)
* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/tags](https://github.com/sdn-sense/siterm/tags)
* Pull latest runtime version by issuing: `git pull` inside siterm-startup repo directory;
* Once all changes are done as noted in a new release description, proceed to restart the service: `cd fe/docker/ && ./restart-new-image.sh -i latest`. p.s. if you used `-n host` - dont forget to add it too.

# SiteRM-FE Installation First time (Using Kubernetes)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and know namespace you want to use for deployment.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key available and valid.**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* Modify FE Contig File in cloned repo, path:`fe/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for Frontend.
* Modify Environment file in cloned repo, path:`fe/conf/environment` and change `MARIA_DB_PASSWORD`
* Prepare ansible configuration file at `fe/conf/etc/ansible-conf.yaml`. For more details, see here: [[Network Control via Ansible](NetControlAnsible.md)]
* Copy Certificates to correct location:
  * Certificate - copy to `fe/conf/etc/httpd/certs/cert.pem` and `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/httpd/certs/privkey.pem` and `fe/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd fe/kubernetes/ && ./k8s-run.sh`. This Script will request some parameters and will auto generate k8s yaml file which will be submitted to your Kubernetes cluster.

# SiteRM-FE Upgrade (Using Kubernetes)
* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/tags](https://github.com/sdn-sense/siterm/tags)
* Pull latest runtime version by issuing: `git pull` inside siterm-startup repo directory;
* Once all changes are done as noted in a new release description, proceed to upgrade. (assuming you have saved your yaml file). Execute `kubectl apply -f <old-yaml-file>`. In case there was no required changes in yaml file - you can kill the container and Kubernetes will take care to start a new container (with latest image)

# SiteRM-Agent Installation First time (Docker)
* Prerequisites:
  * **Make sure you have docker installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key generated or received it from SENSE Team.**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* Modify Agent Contig File in cloned repo, path:`agent/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for that Specific Agent/DTN.
* Copy Certificates to config location:
  * Certificate - copy to `agent/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `agent/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd agent/docker/ && ./run.sh -i latest`

# SiteRM-Agent Upgrade (Using Docker)
* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/tags](https://github.com/sdn-sense/siterm/tags)
* Pull latest runtime version by issuing: `git pull` inside siterm-startup repo directory;
* Once all changes are done as noted in a new release description, proceed to restart the service: `cd agent/docker/ && ./restart-new-image.sh -i latest`.

# SiteRM-Agent Installation First time (Kubernetes cluster)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and namespace you want to use.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key generated or received it from SENSE Team.**

* Clone the following repo: [https://github.com/sdn-sense/siterm-startup](https://github.com/sdn-sense/siterm-startup)
* Modify Agent Contig File in cloned repo, path:`agent/conf/etc/siterm.yaml` and specify the SiteName and MD5 parameters for that Specific Agent/DTN.
* Copy Certificates to config location:
  * Certificate - copy to `agent/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `agent/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd agent/kubernetes/ && ./k8s-run.sh`. This Script will request some parameters and will auto generate k8s yaml file which will be submitted to your Kubernetes cluster.

# SiteRM-Agent Upgrade (Using Kubernetes)
* Please look for any changes required to support new release here: [https://github.com/sdn-sense/siterm/tags](https://github.com/sdn-sense/siterm/tags)
* Pull latest runtime version by issuing: `git pull` inside siterm-startup repo directory;
* Once all changes are done as noted in a new release description, proceed to upgrade. (assuming you have saved your yaml file). Execute `kubectl apply -f <old-yaml-file>`. In case there was no required changes in yaml file - you can kill the container and Kubernetes will take care to start a new container (with latest image)

# SiteRM-Agent Installation (Kubernetes cluster with Helm)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and namespace you want to use.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key generated or if you have Issuer/ClusterIssuer on your Kubernetes cluster, you can use HELM to generate new certificates**

* Get the following override values file: https://github.com/sdn-sense/helm-siterm-agent/blob/main/values.yaml
* Modify the downloaded file and specify the SiteName and MD5 parameters for that Specific Agent/DTN and or any other parameters needed, e.g. Certificate Issuer details.
* If done first time, install helm repo: `helm repo add siterm-agent https://sdn-sense.github.io/helm-siterm-agent`
* Update to latest helm repo charts: `helm repo update`
* Install the helm chart on your Kubernetes cluster: `helm install siterm-agent siterm-agent/siterm-agent -f values.yaml`

# DTNs Monitoring
The node_exporter from Prometheus is designed to monitor the host system. If you start container for host monitoring, specify path.rootfs argument. This argument must match path in bind-mount of host root. The node_exporter will use path.rootfs as prefix to access host filesystem. There are several ways to allow SENSE team monitor DTNs:
* If you already have node_exporter running on DTN you dont need to install another one.
* To install node_exporter on bare metal, please follow official documentation here: [https://prometheus.io/docs/guides/node-exporter/](https://prometheus.io/docs/guides/node-exporter/)
* In case you dont want to install it on a bare metal machine, you can run node_exporter inside Docker or Kubernetes:
  * **DOCKER** - example here: [https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/docker](https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/docker)
  * **Kubernetes** - example here: [https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/kubernetes](https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/kubernetes)
* **(Once deployed) - Please update your agent configuration on Config Git [here](https://github.com/sdn-sense/rm-configs) and specify config parameter `node_exporter` in `general` section.**
