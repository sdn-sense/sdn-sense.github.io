[[Home](index.md)]   [[Installation](install.md)]
# Install considerations
Site resource manager has several applications (Frontend and Agent) and depending on your end-host installation, you will need both or only one, depending on how big your deployment is. 
* *Frontend* is required if you plan to use switches control. Usually, it is one Frontend installation for a controlled domain, but in case you just need DTN control, Frontend is not needed. Currently in development and beta testing is ODL L2 Switch. If you need other controllers to be supported, please create an issue here: https://github.com/sdn-sense/siterm
* *Agent* installation - Is to be installed on DTN. Depending on the use case, installation can be done in a docker container (Currently only CentOS 7 is supported) or installed in bare metal.

Please consult individual cases with the SENSE team before deploying: sense-all@googlegroups.com or create an issue at https://github.com/sdn-sense/rm-configs with the title "[NEW Site] ..."

# Prerequisites

* *Configuration* - All Resource managers keep configuration in Git Repo (https://github.com/sdn-sense/rm-configs). In case this is a new deployment, please create a ticket at https://github.com/sdn-sense/rm-configs with the title "[NEW Site] ...". SENSE Team will follow with you to set-up and prepare configuration files. Some questions we will ask are Termination endpoint (isAlias to Network Provider), Maximum capacity available, DTN IP(s), Hostnames, VLAN ranges allowed, Private network namespace allowed (Not to have clash if you use one of the private network namespaces already on your network). As an example, please look at one of the other configured sites and their parameters.
* *Certificates* - You will need to have Certificates for the services (CA, Chain, Cert, Key). In case you use OpenSSL or Lets Encrypt - There are scripts ready to prepare and check certificates in `siterm/installers/config-preparation/generate-certs.sh`. In case you use your Custom CA or your Site's CA - CA will need to be uploaded to this configuration (`https://github.com/sdn-sense/rm-configs`) Github repo.
# Installation documentation
In most cases, each site has a Site-RM Resource manager and also a minimum of 1 DTN (Site Agent) configured. Currently, Site RM supports only:
* Manual modification on the network switches. e.g. - to push all VLANs on the switches directly to the DTN-RM from the endpoint facing SENSE Network resource manager;
* ODL L2 control. For this, please follow the default ODL Installation and SiteRM Requires the odl-l2-switch installed. Documentation and packaging is not ready yet. Please refer to the SiteRM configuration manual on how to configure it.

There are helper scripts in this repository: https://github.com/sdn-sense/siterm-installers

Site-RM consists of Two Services:
* SiteRM-FE
* SiteRM-Agent

Installation types, please see the documentation below:
* Bare Metal installation
* Docker installation
* Kubernetes installation

# SiteRM-FE Installation (Bare-metal CentOS 7/Ubuntu 18.04)
```
# Ubuntu - use apt, CentOS - use yum
yum install git -y
git clone https://github.com/sdn-sense/siterm
cd siterm/installers/
sh ./fresh-siterm-fe-install.sh -R /opt/
# Before starting any service, please look at SiteRM-FE configuration section.
```

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

# SiteRM-Agent Installation (Bare-metal only CentOS 7/Ubuntu 18.04)
```
# Ubuntu - use apt, CentOS - use yum
yum install git -y
git clone https://github.com/sdn-sense/siterm
cd siterm/installers/
sh ./fresh-siterm-agent-install.sh -R /opt/
```
In case having issues, please create a ticket here: https://github.com/sdn-sense/ops

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
