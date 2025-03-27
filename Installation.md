[[Home](index.md)] [[Installation Information](Installation.md)] [[Docker Install](DockerInstallation.md)] [[Kubernetes Install](KubernetesInstallation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)] [[Debuggging](Debuging.md)]

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

Supported installations:
* [Kubernetes (via HELM)](KubernetesInstallation.md)
* [Docker](DockerInstallation.md)
