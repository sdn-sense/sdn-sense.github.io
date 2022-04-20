[[Home](index.md)]   [[Installation](install.md)]
# Information

Site resource manager has several containers (Frontend and Agent). 
* *Frontend* is responsible for: communication with Orchestrator, Accept deltas, Prepare Model, Control switches on LAN, Get all configuration from all registered DTNs. Minimum one Frontend is needed for a single domain. Currently, Dell OS 9, Arista EOS, Azure SONIC are only supported switches. If you need other switch support, please see #.... 
* *Agent* installation - is responsible for gathering data transfer node information, creating vlan interfaces, applying QOS. 

Please consult individual cases with the SENSE team before deploying: sense-all@googlegroups.com or create an issue at https://github.com/sdn-sense/ops with the title "[NEW Site] ..."

# Prerequisites

* *Configuration* - All Resource managers keep configuration in Git Repo (https://github.com/sdn-sense/rm-configs). In case this is a new deployment, please create a ticket at https://github.com/sdn-sense/ops with the title "[NEW Site] ...". SENSE Team will follow with you to set-up and prepare configuration files. Some questions we will ask are Termination endpoint (isAlias to Network Provider), Maximum capacity available, DTN IP(s), Hostnames, VLAN ranges allowed, Private network namespace allowed. As an example, please look at one of the other configured sites and their parameters.
* *Certificates* - You will need to have Certificates for the services (CA, Chain, Cert, Key). SENSE Team can genearate certificates for your service on own CA. Otherwise - Please follow your institution policies to get Certificate, Key, Full Chain.

# Installation documentation

There are helper scripts in this repository: https://github.com/sdn-sense/siterm-startup

Installation types, please see the documentation below:
* Docker installation
* Kubernetes installation

# SiteRM-FE Installation (Docker container)
```
# Make sure you have docker installed and docker service up and running;
# Install git;
# Ubuntu - use apt, CentOS - use yum
yum install git -y
# In case of 
git clone https://github.com/sdn-sense/siterm
cd siterm/installers/fe-docker/
sh ./build.sh
# Before executing to start a docker container, please look at the SiteRM-FE configuration section.
# If you have all configs and certs in place. execute ./run.sh command.
```

# SiteRM-FE Installation (Kubernetes cluster)

* Don't forget that SiteRM requires valid certificates to function properly 
* Please also configure dtnrm.conf file described in **SiteRM-FE configuration (Docker, Kubernetes and Bare metal)** section

* Once you have the following configuration file and certificates, execute the commands below:
```
kubectl create secret generic sense-httpdprivkey --from-file=httpdprivkey=/full/path/to/privkey.pem
kubectl create secret generic sense-httpdcert --from-file=httpdcert=/full/path/to/cert.pem
kubectl create secret generic sense-hostcert --from-file=hostcert=/full/path/to/hostcert.pem
kubectl create secret generic sense-hostkey --from-file=hostkey=/full/path/to/hostkey.pem
kubectl create secret generic sense-httpdfullchain --from-file=httpdfullchain=/full/path/to/fullchain.pem
kubectl create configmap sense-siterm-fe-yaml --from-file=sense-siterm-fe=/full/path/to/dtnrm.yaml
```

```
# Make sure you have kubernetes cluster up and running up and running;
# Install git;
# Ubuntu - use apt, CentOS - use yum
yum install git -y
git clone https://github.com/sdn-sense/siterm
cd siterm/installers/fe-docker/
kubectl apply -f sitefe-k8s.yaml
```

# SiteRM-FE configuration (Docker, Kubernetes and Bare metal)
* SiteRM-FE Configuration is kept on GitHub repo. To pull configuration parameters, you need to know the SiteName and MD5 Hash created at *Prerequisites* section. With this information, create file `/etc/dtnrm.conf` (In case of bare metal install) or `$GIT_REPO_DIR/installers/fe-docker/conf/etc/dtnrm.yaml` (In case of Docker install):
```
---
GIT_REPO: "sdn-sense/rm-configs"
BRANCH: master
MD5: <MD5> # This you received from GIT Configuration Repo
SITENAME: <SITENAME> # This you received from GIT Configuration Repo
```

* Don't forget that SiteRM requires valid certificates to function properly

# SiteRM-Agent Installation (Docker)
```
# Make sure you have docker installed and docker service up and running;
# Ubuntu - use apt, CentOS - use yum
yum install git -y
git clone https://github.com/sdn-sense/siterm-installers
cd siterm-installers/agent-docker/
sh build.sh 
# If build process successful
# Before executing to start docker container, please look at the SiteRM-Agent configuration section.sh run.sh
```

# SiteRM-Agent Installation (Kubernetes cluster)

* Don't forget that SiteRM requires valid certificates to function properly
* Please also configure dtnrm.conf file described in **SiteRM-Agent configuration (Docker, Kubernetes and Bare metal)** section

* Once you have the following configuration file and certificates, execute the commands below:
```
kubectl create configmap sense-siterm-agent-yaml --from-file=sense-siterm-agent=/full/path/to.dtnrm.yaml
kubectl create secret generic sense-agent-hostcert --from-file=agent-hostcert=/full/path/to/hostcert.pem
kubectl create secret generic sense-agent-hostkey --from-file=agent-hostkey=full/path/to/hostkey.pem
```

```
# Make sure you have kubernetes cluster up and running up and running;
# Install git;
# Ubuntu - use apt, CentOS - use yum
yum install git -y
git clone https://github.com/sdn-sense/siterm
cd siterm-installers/agent-docker/
kubectl apply -f siterm-agent-k8s.yaml
```

In case having issues, please create a ticket here: https://github.com/sdn-sense/ops

# SiteRM-Agent configuration (Docker, Kubernetes and Bare metal)
* SiteRM-Agent Configuration is kept on GitHub repo. To pull configuration parameters, you need to know the SiteName and MD5 Hash created at *Prerequisites* section. With this information, create file /etc/dtnrm.conf (In case of bare metal install) or $GIT_REPO_DIR/installers/agent-docker/conf/etc/dtnrm.yaml (In case of Docker install):
```
---
GIT_REPO: "sdn-sense/rm-configs"
BRANCH: master
MD5: <MD5> # This you received from GIT Configuration Repo
SITENAME: <SITENAME> # This you received from GIT Configuration Repo
```

* Don't forget that SiteRM Agent requires valid certificates to function properly


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
