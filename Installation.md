[[Home](index.md)]   [[Installation](install.md)]
# Information

Site resource manager require several containers (Frontend and Agent). 
* **Frontend** is responsible for: communication with Orchestrator, Accept deltas, Prepare Model, Control switches on LAN, Get all configuration from all registered DTNs. Minimum one Frontend is needed for a single domain.
* **Agent** installation - is responsible for gathering data transfer node information, creating vlan interfaces, applying QOS. 

Please consult individual cases with the SENSE team before deploying: sense-all@googlegroups.com or create an issue at https://github.com/sdn-sense/ops with the title "[NEW Site] ..."

In case have issues with any SENSE SiteRM Software, please create a ticket here: https://github.com/sdn-sense/ops


# Before start
**Frontend**: Each site requires 1 Frontend.
* **Installation type: **Docker** or **Kubernetes**
* **Certificates**: Frontend requires cert, key, fullchain certificates for its services.
* **Networking**: Frontend requires ports 8080 and 8443 open (Can be limited to a specific list of nodes, the list below): 
  * **Sense-o.es.net** - Production Orchestrator;
  * **Sense-o-dev.es.net** - Development Orchestrator
  * **Influx.sdn-sense.dev** - SENSE Monitoring and Alarming service.

**Agent**: Must run on each DTN you want SENSE to control, monitor.
* **Installation type**: **Docker** or **Kubernetes** 
* **Certificate**: The agent requires a host certificate and key pair.
* **Networking**: No ports open needed (see exception below)
* **Monitoring**: SENSE Uses Prometheus and node exporter to monitor all DTN deployments. If you want your DTN to be monitored and altered - please ensure you have node_exporter installed and the port open. 


# SiteRM-Frontend and SiteRM-Agent configuration
SiteRM-FE and SiteRM-Agent Configuration files are kept on GitHub repo. SiteRM Services pull from Github repo once an hour and use the latest configuration. Please refer to this link for Frontend and Agent configuration and it's parameters, examples here. 


For deployment you will need to know the SiteName and MD5 Hash. With this information, `$GIT_REPO_DIR/installers/fe-docker/conf/etc/dtnrm.yaml` (In case of Docker install):
```
---
GIT_REPO: "sdn-sense/rm-configs"
BRANCH: master
MD5: <MD5> # This you received from GIT Configuration Repo
SITENAME: <SITENAME> # This you received from GIT Configuration Repo
```

# Installation documentation

There are helper scripts in this repository: https://github.com/sdn-sense/siterm-startup
Supported installations:
* Docker installation
* Kubernetes installation

# SiteRM-FE Installation First time (Using Docker)
* Prerequisites:
  * **Make sure you have docker installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash).**
  * **You have Certificate, Key, Fullchain generated.**

* Clone the following repo: https://github.com/sdn-sense/siterm-startup
* Modify FE Contig File `fe/conf/etc/dtnrm.yaml` and specify the SiteName and MD5 parameters for that Specific Frontend.
* Modify Environment file `fe/conf/environment` and change `MARIA_DB_PASSWORD`
* Copy Certificates to config location:
  * Certificate - copy to `fe/conf/etc/httpd/certs/cert.pem` and `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/httpd/certs/privkey.pem` and `fe/conf/etc/grid-security/hostkey.pem`
  * Fullchain - copy to `fe/conf/etc/httpd/certs/fullchain.pem`
* Start the service: `cd fe/docker/ && ./run.sh`


# SiteRM-FE Installation (Using Kubernetes)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and namespace you want to use.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash).**
  * **You have Certificate, Key, Fullchain generated.**

* Clone the following repo: https://github.com/sdn-sense/siterm-startup
* Modify FE Contig File `fe/conf/etc/dtnrm.yaml` and specify the SiteName and MD5 parameters for that Specific Frontend.
* Modify Environment file `fe/conf/environment` and change `MARIA_DB_PASSWORD`
* Copy Certificates to config location:
  * Certificate - copy to `fe/conf/etc/httpd/certs/cert.pem` and `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/httpd/certs/privkey.pem` and `fe/conf/etc/grid-security/hostkey.pem`
  * Fullchain - copy to `fe/conf/etc/httpd/certs/fullchain.pem`
* Start the service: `cd fe/kubernetes/ && ./k8s-run.sh`. This Script will request some parameters and will auto generate k8s yaml file which will be submitted to your Kubernetes cluster.

# SiteRM-Agent Installation (Docker)
* Prerequisites:
  * **Make sure you have docker installed and service is up and running.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash).**
  * **You have Certificate, Key generated.**

* Clone the following repo: https://github.com/sdn-sense/siterm-startup
* Modify Agent Contig File `agent/conf/etc/dtnrm.yaml` and specify the SiteName and MD5 parameters for that Specific Agent/DTN.
* Copy Certificates to config location:
  * Certificate - copy to `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd agent/docker/ && ./run.sh`

# SiteRM-Agent Installation (Kubernetes cluster)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and namespace you want to use.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash).**
  * **You have Certificate, Key generated.**

* Clone the following repo: https://github.com/sdn-sense/siterm-startup
* Modify Agent Contig File `fe/conf/etc/dtnrm.yaml` and specify the SiteName and MD5 parameters for that Specific Agent/DTN.
* Copy Certificates to config location:
  * Certificate - copy to `fe/conf/etc/grid-security/hostcert.pem`
  * Key - copy to `fe/conf/etc/grid-security/hostkey.pem`
* Start the service: `cd agent/kubernetes/ && ./k8s-run.sh`. This Script will request some parameters and will auto generate k8s yaml file which will be submitted to your Kubernetes cluster.


# DTNs Monitoring
* The node_exporter from Prometheus is designed to monitor the host system. It's not recommended to deploy it as a Docker container because it requires access to the host system. Be aware that any non-root mount points you want to monitor will need to be bind-mounted into the container. If you start container for host monitoring, specify path.rootfs argument. This argument must match path in bind-mount of host root. The node_exporter will use path.rootfs as prefix to access host filesystem. There are several ways to allow SENSE team monitor DTNs (Let SENSE team know the node_exporter FQDN and Port.)

  * If you already have node_exporter running on DTN you dont need to install another one. Let SENSE team know FQDN and Port.
  * To install node_exporter on bare metal, you can follow documentation here: https://prometheus.io/docs/guides/node-exporter/
  * In case you dont want to install it on bare metal machine, you can run node_exporter inside docker container, commands below.
```
docker run -d -p 9100:9100 \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter \
  --path.rootfs=/host

firewall-cmd --add-port=9100/tcp
firewall-cmd --reload
```
