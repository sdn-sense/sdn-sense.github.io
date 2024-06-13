[[Home](index.md)]   [[Installation](Installation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)]
# Configuration

SENSE SiteRM keeps most configuration on GitHub (Frontend and Agent).  

**IMPORTANT: DO NOT UPLOAD ANSIBLE CONFIGURATION WITH PASSWORD/SSH KEY**. For more details about Ansible configuration, see here: [[Network Control via Ansible](NetControlAnsible.md)]

Please consult individual cases with the SENSE team before deploying: sense-all@googlegroups.com or create an issue at [here](https://github.com/sdn-sense/ops/issues/new) with the title **"[NEW Site] ..."**

In case have issues with any SENSE SiteRM Software, please create a ticket [here](https://github.com/sdn-sense/ops) or send an email to [sense-all@googlegroups.com](sense-all@googlegroups.com)

Notes for configuration files:
* All configuration files must be valid yaml format.
* Default values are not required to be set in the configuration file. (unless you want to override the default value)
* Configuration file must be stored in github repository under <SITENAME> directory.
* \<SITENAME\> directory must contain a `mapping.yaml` file with the following format:
```angular2html
---
8feb35ed655904aa30d466658756a87f: # This is md5(fqdn)
  config: FE/ # This is the directory where configuration files are stored for that hostname. Later in documentation it is refered as FE_DIRNAME
  maintainer: "Justas Balcas" # Name of the person responsible for the Site
  status: production # Status of the Site. Can be production, development, testing
  type: FE # Type of the deployment. Can be FE, Agent
8e27a5535404f39045af089421c38e78:
  config: Agent01/ # This is the directory where configuration files are stored for that hostname. Later in documentation it is refered as AGENT_DIRNAME
  maintainer: "Justas Balcas"
  status: production
  type: Agent
```

# Frontend configuration
For examples, please see [here](https://github.com/sdn-sense/rm-configs)

Notes:
* Authentication with Frontend is possible only with valid certificate. Authorized DNs are stored in github repository: \<SITENAME>/<FE_DIRNAME>/auth.yaml. It must list all Agent DNs and SENSE Orchestrator/Team required DNs. Minimal required DN list is [here](TODO_ADD_LINK). Below is an example of file:
```angular2html
---
jbalcas:
  full_dn: "/DC=ch/DC=cern/CN=CERN Grid Certification Authority/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=jbalcas/CN=751133/CN=Justas Balcas"
  permissions: w
fe:
  full_dn: "/C=US/O=Let's Encrypt/CN=R3/CN=sense-caltech-fe.sdn-lb.ultralight.org"
  permissions: w
daemonset:
  full_dn: "/C=US/ST=California/L=Pasadena/O=Caltech/CN=sdn-sense.dev/C=US/ST=California/L=Pasadena/O=Caltech/CN=sense-caltech-fe.ultralight.org"
  permissions: w
sense-mon:
  full_dn: "/C=US/O=Internet2/CN=InCommon RSA Server CA 2/C=US/ST=California/O=Energy Sciences Network/CN=sense-mon.es.net"
  permissions: r
```
* In case of wildcard support, Regex can be used. For example: `/C=US/ST=California/L=Pasadena/O=Caltech/CN=.*\.ultralight\.org` will match all CNs ending with .ultralight.org. Authorized DNs for Wildcard are stored in github repository: \<SITENAME>/<FE_DIRNAME>/auth-re.yaml. Below is an example of file:
```angular2html
---
daemonset:
  full_dn: "/C=US/ST=California/L=Pasadena/O=Caltech/CN=.*\.ultralight\.org"
  permissions: w
```

* Default values are not required to be set in the configuration file. (unless you want to override the default value)
* Configuration file must be stored in github repository: \<SITENAME>/<FE_DIRNAME>/main.yaml
* Configuration file must contain the following structure:

General section:
* logLevel: Logging Level. Optional. Default: INFO, Available options: DEBUG, INFO, WARNING, ERROR, CRITICAL
* sites: List of sites which are managed by this Frontend. Name of the site. Must match the name in the directory it is.
* webdomain: "https://FRONTEND_URL:443" Mandatory. URL of the Frontend. If frontend is behind a load balancer, it must be the URL of the load balancer.
* probes: Probes used by Prometheus monitoring and alerting to check status of Frontend. Optional. Default: ['https_v4_siterm_2xx', 'icmp_v4'], Available options: ['https_v4_siterm_2xx', 'icmp_v4', 'https_v6_siterm_2xx', 'icmp_v6']

Sitenames section (**NOTE:** For each site, there must be a section with the name of the site. The name must be defined in general->sites list.):
* domain: domain of the site. Mandatory.
* latitude: Latitude of the site. Mandatory.
* longitude: Longitude of the site. Mandatory.
* plugin: Plugin used by the site. Mandatory. Available options: ansible, raw. See more details about plugin configuration here: [[Network Control via Ansible](NetControlAnsible.md)]
* privatedir: Directory where the configuration files are stored for the site. Optional. Default to: /opt/siterm/config/<SITENAME>/
* metadata: Metadata for the site. Optional. Can be used to store additional information about the site inside model. For example, xrootd redirectors and IPv6 Range they belong.
* ipv4-subnet-pool: List of IPv4 subnets allocated by the site for SENSE Control (for BGP Control to advertize as route-maps). Optional.
* ipv6-subnet-pool: List of IPv6 subnets allocated by the site for SENSE Control (for BGP Control to advertize as route-maps). Optional.
* ipv4-address-pool: List of IPv4 addresses allocated by the site for SENSE Control (for setting IPs on Host and or Network Devices). Mandatory.
* ipv6-address-pool: List of IPv6 addresses allocated by the site for SENSE Control (for setting IPs on Host and or Network Devices). Mandatory.
* year: Used in modeling. Year when the site was first time deployed. Mandatory. 
* switch: List of switches used by the site. Mandatory. Each switch must have a section with the name of the switch. The name must be defined in the switch list.
  * vsw: Virtual Switching - to allow vlan creation (same as switch name);
  * rst: Routing Service - to allow configure BGP (private_asn number is mandatory to define if rst is defined). **NOTE: There can be only 1 rst defined per site**.
  * rsts_enabled: List of enabled routing services. Mandatory. Available options: ['ipv4', 'ipv6']
  * private_asn: Private ASN number. Mandatory if rst is defined. **NOTE: private_asn must be unique for all SENSE. To find next available private_asn, see here: TODO**.
  * external_snmp: External SNMP server URL exposing information in Prometheus format. Optional. Default: None
  * vrf: VRF name if all vlans/interfaces need to be in vrf. Optional.
  * vlan_mtu: VLAN MTU. Optional. Default: None (based on device)
  * allports: If allports flag set to True - it will include all Ports in the model, except the ones listed inside the ports_ignore list. Optional. Default: false
  * allvlans: If allvlans flag set to True - it will include all VLANs in the model, otherwise only SENSE vlans defined in vlan_range. Optional. Default: false
  * vlan_range: Global list of VLANs used by the site on this device. Mandatory.
  * ports: Dictionary of ports used by the site on this device. Mandatory if allports flag is not set or set to False. Each port must have a section with the name of the port. To get an example config, please see here: TODO...
    * vlan_range: List of VLANs used on this port. Optional. If specified, it will override the global vlan_range for that specific port.
    * capacity: Capacity of the port. If not specified, SiteRM will try to get this via ansible. Optional for ansible, Mandatory for RAW.
    * isAlias: Alias to another port on WAN or Local if lldp not enabled. Optional for all ports except for Port's facing WAN.
    * wanlink: If the link is a WAN link. Optional. Default: False
    * rate_limit: If the link should apply rate limit (beta feature, not available on all devices). Optional. Default: False

# Agent configuration
For examples, please see [here](https://github.com/sdn-sense/rm-configs)

Notes:
* Default values are not required to be set in the configuration file. (unless you want to override the default value)
* Configuration file must be stored in github repository: \<SITENAME>/<AGENT_DIRNAME>/main.yaml
* Configuration file must contain the following structure:

General section:
* logLevel: Logging Level. Optional. Default: INFO, Available options: DEBUG, INFO, WARNING, ERROR, CRITICAL
* ip: IP of the Agent. Mandatory.
* sitename: Name of the site Agent belongs to. Mandatory. 
* webdomain: "https://AGENT_URL:443" Mandatory. URL of the FE.
* node_exporter: Node Exporter URL with port. Optional. Default: None

Agent section:
* interfaces: List of interfaces used by the Agent and allowed to be controlled by SENSE. Mandatory. Each interface must have a section with the name of the interface. The name must be defined in the interfaces list.
* hostname: Hostname of the Agent. Mandatory.

Interface (based on interface name) section:
* port: Remote port name it is connected to. Remote port must be enabled in FE. Mandatory.
* switch: Switch name it is connected to. Switch name must match one configured in FE. Mandatory.
* vlan_range: List of VLANs used on this interface. Mandatory.
* ipv4-address-pool: List of IPv4 addresses allocated by the site for SENSE Control (for setting IPs on Host and or Network Devices). Mandatory.
* ipv6-address-pool: List of IPv6 addresses allocated by the site for SENSE Control (for setting IPs on Host and or Network Devices). Mandatory.
* intf_reserve: Reserved bandwidth for the interface. Optional. Default: 1000 mbps
* intf_max: Maximum bandwidth for the interface. Optional. Default: 10000 mbps **NOTE: intf_max must be set if diff than 10gbps**
* l3enabled: Allow to configure L3 (Routing) on that interface. Default: True
* bwParams: Bandwidth parameters. Mandatory. 
  * unit: Unit of the bandwidth. Mandatory. Available options: mbps, gbps
  * type: Type of the bandwidth. Mandatory. Available options: guaranteedCapped, bestEffort
  * priority: Priority of the bandwidth. Mandatory. Available options: 0, 1, 2, 3, 4, 5, 6, 7
  * minReservableCapacity: Minimum reservable capacity. Mandatory.
  * maximumCapacity: Maximum capacity allowed for provisioning. Mandatory.
  * granularity: Granularity to use for bandwidth requests. Mandatory.
* qos: QoS parameters. For a more detailed explanation about QoS, see here: TODO. Mandatory if L3 QOS Used.
  * policy: Policy name. Available options: privatens, hostlevel. In case of privatens - QoS will be added under subinterface; In case of hostlevel - QoS will be added on master interface. Mandatory.
  * qos_params: QoS parameters for TC. Default `mtu 9000 mpu 9000 quantum 200000 burst 300000 cburst 300000 qdisc sfq balanced`.
  * class_max: If Interface is capable 100Gbps, and SENSE requests 1Gbps, QoS rules will ensure 1Gbps for that traffic, but will allow to steal throughput up to 100Gbps, if no other traffic is using it. Optional. Default: False
  * interfaces: List of QoS interfaces for L3 QoS Control (in conjunction with BGP Control.).
    * <MAIN_INTF|SUBINTERFACE> - Interface name, in case policy is hostlevel, it must be MAIN_INTF, in case policy is privatens, it must be SUBINTERFACE.
    * master_intf: Master interface name. in case policy is hostlevel, it must be MAIN_INTF, in case policy is privatens, it must be MAIN_INTF also.
    * ipv6_range: IPv6 range for the interface L3 QoS. It can be a single item as string or list of strings.
