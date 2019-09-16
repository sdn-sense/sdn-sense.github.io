[[Home](index.md)]   [[Installation](install.md)]

# Installation documentation

Each site has to install the Site-RM Resource manager and also minimum 1 DTN. Currently Site RM supports only:
* Manual modification on the network switches. e.g. - to push all VLANs on the switches directly to the DTN-RM from the endpoint facing SENSE Network resource manager;
* ODL L2 control. For this, please follow the default ODL Installation and SiteRM Requires the odl-l2-switch installed. Please refer to the SiteRM configuration manual how to configure it.

There are helper scripts in this repository: https://github.com/sdn-sense/siterm-installers

Site-RM consists of Two Services:
* SiteRM-FE
* SiteRM-Agent

# SiteRM-FE Installation
```
sudo sh ./fresh-siterm-fe-install.sh -R /opt/
```
In case having issues, please create ticket here: https://github.com/sdn-sense/siterm-general-issues 
Optional. Configure HTTPs and make certificates your way. The easiest way is to use Let's Encrypt certificates.

On some systems Memory for monitoring (netdata) can be decreased by setting these parameters:
```
echo 1 >/sys/kernel/mm/ksm/run
sudo echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs
```
In case there are ownership issues (using selinux), these commands below will help (More details: http://sysadminsjourney.com/content/2010/02/01/apache-modproxy-error-13permission-denied-error-rhel/):
```
# Ownership
rootdir=/opt/siterm/config/
sudo chown apache:apache -R $rootdir
cd $rootdir
 
# File permissions, recursive
sudo find . -type f -exec chmod 0644 {} \;
 
# Dir permissions, recursive
sudo find . -type d -exec chmod 0755 {} \;
 
# SELinux serve files off Apache, resursive
sudo chcon -t httpd_sys_content_t $rootdir -R
 
# Allow write only to specific dirs
sudo chcon -t httpd_sys_rw_content_t /data/config -R

# Make it temporary
/usr/sbin/setsebool httpd_can_network_connect 1
# To make it permanent:
/usr/sbin/setsebool -P httpd_can_network_connect 1
```

After the first installation, please update the configuration files with correct parameters:
* /etc/dtnrm-site-fe.conf and referring documentation here: https://github.com/sdn-sense/siterm-fe/wiki/Frontend-Configuration
* /etc/dtnrm-site-fe-switches.conf referring documentation here: https://github.com/sdn-sense/siterm-fe/wiki/Switches-configuration


# SiteRM-Agent Installation
```
sudo sh ./fresh-siterm-agent-install.sh -R /opt/
```
In case having issues, please create ticket here: https://github.com/sdn-sense/siterm-general-issues 

# Backend Installation


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



