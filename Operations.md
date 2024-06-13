[[Home](index.md)]   [[Installation](Installation.md)] [[Configuration Parameters](Configuration.md)] [[Network Control via Ansible](NetControlAnsible.md)] [[Operations](Operations.md)]
# Information

SiteRM Frontend runs an httpd server and servers html website. You can access it via https://<hostname_of_fe>:<port_of_fe>. It is the same url as defined inside SiteRM configuration general->webdomain.

Frontend allows you to view and interact with SiteRM, e.g.:
* View topology;
* View Frontend and Agent Configurations;
* Reload Configuration for frontend or Agent
* Delete host from SiteRM Frontend;
* View state of all Services running (on FE and Agents)
* View latest models and deltas;
* Request and view debug action's, like rapid ping, tcpdump, arptable, iperf.

Additionally, all SiteRMs are monitored by Prometheus and Grafana under AUTOGOLE. It can alert you once services are failing or if there are any issues with your SiteRM. It can be accessed here: https://autogole-grafana.nrp-nautilus.io (Requires github authentication - please contact SENSE team to add your git username). Slack Alerts are also sent by Grafana once failure, fix occurs.
Please join Slack Workspace "Autogole Alarms" https://autogolealarms.slack.com Please join at least the channel for your domain, and address problems identified in the alerts as soon as possible. This is a free version of Slack, so messages only visible for last 90 days

Channel Organizations:
* one channel for each Sit-RM Domain
* one channel for each NSI Domain
* channel for all_nsi_endpoints
* channel for all_siterm_endpoints


# Configuration reload

SiteRM by default reloads configuration **every hour** if there is a configuration change.
SiteRM Frontend and Agent can be reloade manually via Frontend. This is useful when you want to apply new configuration to Frontend or Agent faster than the cycle of automated refresh.
This can be done under **Frontend Configuration** section on the WEB UI.

# Delete host from SiteRM Frontend

SiteRM Frontend allows you to delete host from SiteRM Frontend. This is useful when you want to remove host from SiteRM Frontend, but keep it in the network. This can be done under **Frontend Configuration** section on the WEB UI.

# Network devices debugging

In case you want to debug and see all actions performed on your network devices, you can use the following commands:
* Enter your FE docker/Kubernetes pod container and go to this directory `cd /opt/siterm/config/ansible/sense`
* Run `python3 test-runner.py` to see all actions performed on your network devices (this runs in a full debug mode, and can be very verbose)

# In case of issue with a Service
* Look at the logs of the service. You can access logs via `/var/log/siterm-site-fe/<Service>/api.log` or `/var/log/siterm-site-agent/<Service>/api.log`
* In case of unknown issue, please create a ticket [here](https://github.com/sdn-sense/siterm)

# Debug actions

SiteRM Frontend allows you to request debug actions, like rapid ping, tcpdump, arptable, iperf. This can be done under **Debug Actions** section on the WEB UI. Description of each action is provided below.
## Rapid Ping
Rapid ping - very similar to Flood ping implemented in FreeBSD. where a minimum of 100 packets are sent in one second or as soon as a reply to the request has come.
It will execute the following command on selected hostname: `ping -i <interval> -w <runtime> <ip> -s <packetsize> -I <Interface>`

## TCPDump
This call will use PyShark, Python wrapper for tshark, allowing python packet parsing using wireshark dissectors. It will capture all packets going via interface for max 30seconds or first 100 packets (whichever comes first).

## ARP Table
The ip neigh command manipulates neighbour objects that establish bindings between protocol addresses and link layer addresses for hosts sharing the same link. Neighbour entries are organized into tables. The IPv4 neighbour table is also known by another name - the ARP table.
The corresponding commands display neighbour bindings and their properties.

## Iperf Client
iPerf3 is a tool for active measurements of the maximum achievable bandwidth on IP networks. It supports tuning of various parameters related to timing, buffers and protocols (TCP, UDP, SCTP with IPv4 and IPv6). For each test it reports the bandwidth, loss, and other parameters.
It will execute the following command: `iperf3 -c <ip> -p <port> -B <interface> -t <time>`

## Iperf Server
iPerf3 is a tool for active measurements of the maximum achievable bandwidth on IP networks. It supports tuning of various parameters related to timing, buffers and protocols (TCP, UDP, SCTP with IPv4 and IPv6). For each test it reports the bandwidth, loss, and other parameters.
It will execute the following command: `timeout <seconds> iperf3 --server -p <port> -B <ip> <one-off>`
