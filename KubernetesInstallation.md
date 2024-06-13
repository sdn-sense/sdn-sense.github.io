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
# SiteRM-FE Installation First time (Kubernetes cluster with Helm)

* Prerequisites:
  * **Make sure you have Kubernetes cluster installed. You will need to have Kubernetes config and know namespace you want to use for deployment.**
  * **Configuration files are present in Git Repo for your Site (Take a note of SiteName and MD5 Hash). MD5 is optional - and if not specified, SiteRM will use md5(hostname) by default**
  * **You have Certificate, Key available and valid (or you can use HELM Chart Certificate section if have cert-manager available).**

* Get the following override values file: https://raw.githubusercontent.com/sdn-sense/helm-siterm-fe/main/values.yaml
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

* Get the following override values file: https://github.com/sdn-sense/helm-siterm-agent/blob/main/values.yaml
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
