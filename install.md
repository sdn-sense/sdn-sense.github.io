[[Home](index.md)]   [[Installation](install.md)]

# Install considerations

Site resource manager has several applications (Frontend and Agent) and depending on your endhost installation, you will need both or only one, depending on how big your deployment is. 
* *Frontend* is required if you plan to use switches control. Usually it is one Frontend installation for controlled domain, but in case you just need DTN control, Frontend is not needed. Currently in development and beta testing is ODL L2 Switch. If you need other controllers to be supported, please create an issue here: https://github.com/sdn-sense/siterm
* *Agent* installation - Is to be installed on DTN. Depending on use case, installation can be done in docker container (Currently only CentOS 7 is supported) or installed in bare metal.

Please consult individual cases with SENSE team before deploying: sense-all@googlegroups.com or create an issue at https://github.com/sdn-sense/rm-configs with title "[NEW Site] ..."

# Prerequisites

* *Configuration* - All Resource managers keep configuration in Git Repo (https://github.com/sdn-sense/rm-configs). In case this is new deployment, please create ticket at https://github.com/sdn-sense/rm-configs with title "[NEW Site] ...". SENSE Team will follow with you to set-up and prepare configuration files.
Some questions we will ask are: Termination endpoint (isAlias to Network Provider), Maximum capacity available, DTN IP(s), Hostnames, vlan ranges allowed, Private network namespace allowed (Not to have clash if you use one of private network namespaces already on your network). As en example, please look at one of the another configured site and their parameters.
* *Certificates* - You will need to have Certificates for the services (CA, Chain, Cert, Key). In case you use OpenSSL or Lets Encrypt - There are scripts ready to prepare and check certificates in `siterm/installers/config-preparation/generate-certs.sh`. In case you use your Custom CA or your Site's CA - CA will need to be uploaded to this configuration (`https://github.com/sdn-sense/rm-configs`) Github repo.

# Installation documentation

In most cases each site has Site-RM Resource manager and also minimum 1 DTN configured. Currently Site RM supports only:
* Manual modification on the network switches. e.g. - to push all VLANs on the switches directly to the DTN-RM from the endpoint facing SENSE Network resource manager;
* ODL L2 control. For this, please follow the default ODL Installation and SiteRM Requires the odl-l2-switch installed. Documentation and packacing is not  ready for this. Please refer to the SiteRM configuration manual how to configure it.

There are helper scripts in this repository: https://github.com/sdn-sense/siterm-installers

Site-RM consists of Two Services:
* SiteRM-FE
* SiteRM-Agent

Installation types, please see documentation below:
* Bare Metal installation
* Docker installation


# SiteRM-FE Installation (Bare-metal only CentOS 7)
```
yum install git -y
git clone https://github.com/sdn-sense/siterm
cd siterm/installers/
sudo sh ./fresh-siterm-fe-install.sh -R /opt/
# Before starting any service, please look at SiteRM-FE configuration section.
```


# SiteRM-FE Installation (Docker container)
```
# Make sure you have docker installed and docker service up and running;
# Install git;
yum install git -y
git clone https://github.com/sdn-sense/siterm
cd siterm/installers/fe-docker/
./build.sh
# Before executing to start docker container, please look at SiteRM-FE configuration section.
# If you have all configs and certs in place. execute ./run.sh command.
```

# SiteRM-FE configuration (Docker and Bare metal)

* SiteRM-FE Configuration is kept on github repo. To pull configuration parameters, you need to know the SiteName and MD5 Hash created at *Prerequisites* section. With this information, create file /etc/dtnrm.conf (In case of bare metal install) or $GIT_REPO_DIR/installers/fe-docker/conf/etc/dtnrm.yaml (In case of Docker install):
```
---
GIT_REPO: "sdn-sense/rm-configs"
BRANCH: master
MD5: <MD5> # This you received from GIT Configuration Repo
SITENAME: <SITENAME> # This you received from GIT Configuration Repo
```

* Copy httpd configuration file
```
cp $GITDIR/packaging/dtnrm-site-fe/sitefe-httpd.conf $GITDIR/installers/fe-docker/conf/etc/httpd/conf.d/sitefe-httpd.conf
```

* Don't forget that SiteRM requires valid certificates to function properly (Please refer to this documentation for more details: https://github.com/sdn-sense/siterm-fe/wiki/HTTPS-and-Security)

# SiteRM-Agent Installation (Bare-metal only CentOS 7)
```
yum install git -y
git clone https://github.com/sdn-sense/siterm
cd siterm/installers/
sudo sh ./fresh-siterm-agent-install.sh -R /opt/
```
In case having issues, please create ticket here: https://github.com/sdn-sense/siterm-general-issues 

# SiteRM-Agent Installation (Docker)
```
# Make sure you have docker installed and docker service up and running;
yum install git -y
git clone https://github.com/sdn-sense/siterm-installers
cd siterm-installers/agent-docker/
sh build.sh # If build process successful
# Before executing to start docker container, please look at SiteRM-Agent configuration section.
sh run.sh
```
In case having issues, please create ticket here: https://github.com/sdn-sense/siterm-general-issues 

# SiteRM-Agent configuration (Docker and Bare metal)
* SiteRM-Agent Configuration is kept on github repo. To pull configuration parameters, you need to know the SiteName and MD5 Hash created at *Prerequisites* section. With this information, create file /etc/dtnrm.conf (In case of bare metal install) or $GIT_REPO_DIR/installers/agent-docker/conf/etc/dtnrm.yaml (In case of Docker install):
```
---
GIT_REPO: "sdn-sense/rm-configs"
BRANCH: master
MD5: <MD5> # This you received from GIT Configuration Repo
SITENAME: <SITENAME> # This you received from GIT Configuration Repo
```

* Don't forget that SiteRM Agent requires valid certificates to function properly (Please refer to this documentation for more details: https://github.com/sdn-sense/siterm-fe/wiki/HTTPS-and-Security)



