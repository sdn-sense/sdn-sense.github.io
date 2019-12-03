[[Home](index.md)]   [[Installation](install.md)]

# Install considerations

Site resource manager has several applications (Frontend and Agent) and depending on your endhost installation, you will need both or only one, depending on how big your deployment is. 
* *Frontend* is required if you plan to use switches control. Usually it is one Frontend installation for controlled domain, but in case you just need DTN control, Frontend is not needed. Currently in development and beta testing is ODL L2 Switch. If you need other controllers to be supported, please create an issue here: https://github.com/sdn-sense/siterm-general-issues
* *Agent* installation - Is to be installed on DTN. Depending on use case, installation can be done in docker container (Currently only CentOS 7 is supported) or installed in bare metal.
* *Backend* installtion - For keeping historical monitoring information in one of the InfluxDB databases. Please contact SENSE team to know the backend endpoint. You also can install on your own and configure own backend, but this will be unique for your domain and not overall SENSE Infrastructure. 

Please consult individual cases with SENSE team before deploying: sense-all@googlegroups.com

# Installation documentation

In most cases each site has Site-RM Resource manager and also minimum 1 DTN configured. Currently Site RM supports only:
* Manual modification on the network switches. e.g. - to push all VLANs on the switches directly to the DTN-RM from the endpoint facing SENSE Network resource manager;
* ODL L2 control. For this, please follow the default ODL Installation and SiteRM Requires the odl-l2-switch installed. Documentation and packacing is not yet ready for this. Please refer to the SiteRM configuration manual how to configure it.

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
git clone https://github.com/sdn-sense/siterm-installers
cd siterm-installers
sudo sh ./fresh-siterm-fe-install.sh -R /opt/
# Before starting any service, please look at SiteRM-FE configuration section.
```
In case having issues, please create ticket here: https://github.com/sdn-sense/siterm-general-issues and also consult the known issues wiki: https://github.com/sdn-sense/siterm-fe/wiki/Known-Issues

# SiteRM-FE Installation (Docker)
```
yum install docker
service docker start
git clone https://github.com/sdn-sense/siterm-installers
cd siterm-installers/fe-docker/
sh build.sh # If build process successful
# Before executing to start docker container, please look at SiteRM-FE configuration section.
sh run.sh
```

# SiteRM-FE configuration (Docker and Bare metal)
After the first installation, please update the configuration files with correct parameters:
* /etc/dtnrm-site-fe.conf (Docker config files are under `conf` directory) and referring documentation here: https://github.com/sdn-sense/siterm-fe/wiki/Frontend-Configuration
* Modify /etc/httpd/conf.d/sitefe-httpd.conf (Docker config files are under `conf` directory) and add Frontends it supports. Site-FE can support multiple domains at once. 
```
# Line to be added per each site:
WSGIScriptAlias /T2_US_UMD/sitefe /var/www/wsgi-scripts/sitefe.wsgi
```
* Don't forget that SiteRM requires valid certificates to function properly (Please refer to this documentation for more details: https://github.com/sdn-sense/siterm-fe/wiki/HTTPS-and-Security)

# SiteRM-Agent Installation (Bare-metal only CentOS 7)
```
yum install git -y
git clone https://github.com/sdn-sense/siterm-installers
cd siterm-installers
sudo sh ./fresh-siterm-agent-install.sh -R /opt/
```
In case having issues, please create ticket here: https://github.com/sdn-sense/siterm-general-issues 

# SiteRM-Agent Installation (Docker)
```
yum install docker
service docker start
git clone https://github.com/sdn-sense/siterm-installers
cd siterm-installers/agent-docker/
sh build.sh # If build process successful
# Before executing to start docker container, please look at SiteRM-Agent configuration section.
sh run.sh
```
In case having issues, please create ticket here: https://github.com/sdn-sense/siterm-general-issues 

# SiteRM-Agent configuration (Docker and Bare metal)
After the first installation, please update the configuration files with correct parameters:
* /etc/dtnrm/main.conf (Docker config files are under `conf` directory) and referring documentation here: https://github.com/sdn-sense/siterm-agent/wiki/SiteRM-Agent-Configuration-parameters
* Don't forget that SiteRM requires valid certificates to function properly (Please refer to this documentation for more details: https://github.com/sdn-sense/siterm-fe/wiki/HTTPS-and-Security)
* You can assign specific interface to docker using pipework: https://github.com/jpetazzo/pipework (Please refer to readme file on pipework repo.). For example on Caltech `pipework --direct-phys ens1 $CONTAINERID` and interface can be physically controlled from container.

# Backend Installation (Bare-metal only CentOS 7)

Backend for storing historical information from DTNs and Frontends
This is not part of the SENSE developed system, so please refer to InfluxDB and Grafana installation documentations. Small part is covered here below

Repository install
```
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/6/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF
cat <<EOF | sudo tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packagecloud.io/grafana/stable/el/6/$basearch
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packagecloud.io/gpg.key https://grafanarel.s3.amazonaws.com/RPM-GPG-KEY-grafana
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
```
```
sudo yum install influxdb
mkdir -p /data/influxdb/data
chown -R influxdb:influxdb /data/influxdb/
sudo service influxdb start
yum install grafana
vi /etc/grafana/grafana.ini # Modify the grafana configuration
sudo service grafana-server start
```
Create new influx user and password.
```
influx
> CREATE USER jbalcas WITH PASSWORD 'NEWPASS' WITH ALL PRIVILEGES
> CREATE DATABASE senseservers
> CREATE DATABASE sensedtns
> exit
```
After this configure each Server's netdata configuration file and make sure backend is specified. For more information about netdata, please see: https://www.netdata.cloud
```
[backend]
	  enabled = yes
	  type = opentsdb
	  destination = 10.3.10.15:12347
	  data source = average
	  update every = 10
	  buffer on failures = 10
	  timeout ms = 20000
	  send charts matching = !ipv4.icmpmsg* !netdata.* *
	  send names instead of ids = no
	  host tags = hostname=<%= @fqdn %> nodetype=<%= @SERVERTYPE %> sitename=T2_US_Caltech
```



