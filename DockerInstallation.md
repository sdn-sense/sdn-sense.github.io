[[Home](index.md)]   
[[Installation](Installation.md) ▼](#)
<div class="dropdown-content">
    <a href="Docker.md">Docker</a>
    <a href="Kubernetes.md">Kubernetes</a>
</div>
[[Configuration Parameters](Configuration.md)]   
[[Network Control via Ansible](NetControlAnsible.md)]   
[[Operations](Operations.md)]

<style>
.dropdown-content {
    display: none;
    position: absolute;
    background-color: #f9f9f9;
    min-width: 160px;
    box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2);
    z-index: 1;
}

.dropdown-content a {
    color: black;
    padding: 12px 16px;
    text-decoration: none;
    display: block;
}

.dropdown-content a:hover {background-color: #f1f1f1}

[[Installation](Installation.md)]:hover .dropdown-content {
    display: block;
}
</style>
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

# DTNs Monitoring (to be run in parallel with SiteRM-Agent)
The node_exporter from Prometheus is designed to monitor the host system. If you start container for host monitoring, specify path.rootfs argument. This argument must match path in bind-mount of host root. The node_exporter will use path.rootfs as prefix to access host filesystem. There are several ways to allow SENSE team monitor DTNs:
* If you already have node_exporter running on DTN you dont need to install another one.
* To install node_exporter on bare metal, please follow official documentation here: [https://prometheus.io/docs/guides/node-exporter/](https://prometheus.io/docs/guides/node-exporter/)
* In case you dont want to install it on a bare metal machine, you can run node_exporter inside Docker:
  * **DOCKER** - example here: [https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/docker](https://github.com/sdn-sense/siterm-startup/tree/main/node-exporter/docker)
* **(Once deployed) - Please update your agent configuration on Config Git [here](https://github.com/sdn-sense/rm-configs) and specify config parameter `node_exporter` in `general` section.**
