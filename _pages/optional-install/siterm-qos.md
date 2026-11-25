---
title: "QoS Only Service (siterm-qos)"
description: "Install siterm-qos, the standalone SENSE QoS service for XRootD containers on Multus and in private network namespaces."
layout: single
classes: wide
permalink: "/optional-install/siterm-qos/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

`siterm-qos` shapes SENSE Layer 3 traffic inside one network namespace, for example in an XRootD pod on Multus. It is one Python file that does only QoS. A site can add it to its own container image and point it at the SiteRM Frontend of the site. The container does not need a SiteRM Agent.

The SiteRM Agent finds Layer 3 requests by the addresses of the host. A container with its own network namespace has addresses that the Agent cannot see, so the Agent does not shape its traffic. `siterm-qos` runs in the namespace of the container and does it there. The blog post [SENSE QoS on Layer 3 paths](/blog/sense-qos-layer-3/) explains the background.

| Where the storage service runs | Use |
| --- | --- |
| Bare metal, or a container with `hostNetwork` | SiteRM Agent |
| Kubernetes pod with a Multus interface (macvlan, ipvlan, VLAN) | `siterm-qos` |
| Kubernetes pod with an SR-IOV interface | `siterm-qos`, with the interface named in the configuration |
| Docker or Podman container on a macvlan or ipvlan network | `siterm-qos` |
| Named network namespace on a host (`ip netns`) | `siterm-qos` |

![siterm-qos next to XRootD]({{ site.url }}{{ site.baseurl }}/images/qos-examples/l3-pod-service.svg "siterm-qos runs in the same network namespace as XRootD")

## Requirements

- Python 3.9 or newer, and the commands `ip`, `tc` and `openssl`. On EL they are in `iproute`, `iproute-tc` and `openssl`.
- Root inside the container and the `NET_ADMIN` capability. No other privileges are needed.
- The kernel modules `sch_htb` and `cls_u32` on the worker or host. A container cannot always load them:

  ```bash
  modprobe sch_htb cls_u32
  ```

- A host certificate that may read from the Frontend, see [Frontend access](#frontend-access).
- HTTPS access from the container to the SiteRM Frontend.

`siterm-qos` is in the [SiteRM repository](https://github.com/sdn-sense/siterm/tree/master/packaging/siterm-qos). SiteRM 1.6.5 and older images do not contain it.

## Install in your own container image

```dockerfile
FROM <XROOTD_IMAGE>

RUN dnf install -y python3 iproute iproute-tc openssl curl && dnf clean all
RUN curl -fsSL -o /usr/local/bin/siterm-qos \
      https://raw.githubusercontent.com/sdn-sense/siterm/master/packaging/siterm-qos/siterm-qos && \
    chmod 755 /usr/local/bin/siterm-qos

COPY siterm-qos.conf /etc/siterm-qos.conf
COPY 60-siterm-qos.conf /etc/supervisord.d/60-siterm-qos.conf
```

On Debian and Ubuntu images the packages are `python3 iproute2 openssl curl`. Replace `master` with a release tag to keep the version fixed.

Point it at your Frontend in `siterm-qos.conf`:

```ini
SITERM_FRONTEND=https://sense-fe.t2.example.org:443
SITERM_SITENAME=T2_US_Example
SITERM_QOS_INTERFACES=net1
SITERM_QOS_CAPACITY=50000
SITERM_QOS_TOTAL=200000
```

`SITERM_FRONTEND` must use the host name that the Frontend has as `webdomain`, and `SITERM_SITENAME` is the directory name of your site in `rm-configs`.

Images that use supervisord, such as the OSG images, start it from `/etc/supervisord.d/60-siterm-qos.conf`:

```ini
[program:siterm-qos]
command=/usr/local/bin/siterm-qos
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
redirect_stderr=true
```

In an image without supervisord, start it in the entrypoint before the storage service:

```bash
/usr/local/bin/siterm-qos &
```

The container needs the capability and the certificate. In Kubernetes:

```yaml
securityContext:
  capabilities:
    add: ["NET_ADMIN"]
volumeMounts:
  - {name: certs, mountPath: /etc/grid-security/hostcert.pem, subPath: hostcert.pem}
  - {name: certs, mountPath: /etc/grid-security/hostkey.pem, subPath: hostcert.key.pem}
```

## Install as a second container in the pod

Containers in a pod share the network namespace. A second container needs no change to the XRootD image, and XRootD itself runs without `NET_ADMIN`. The SiteRM Agent image has all required commands, and the script comes from a ConfigMap:

```bash
kubectl create configmap siterm-qos --from-file=siterm-qos --from-file=siterm-qos.conf
```

```yaml
metadata:
  annotations:
    k8s.v1.cni.cncf.io/networks: '[{"name": "<NETWORK_ATTACHMENT>", "interface": "net1", "ips": ["2001:db8:10::100/64"]}]'
spec:
  containers:
    - name: xrootd
      image: <XROOTD_IMAGE>
      # ... unchanged ...
    - name: siterm-qos
      image: <SITERM_AGENT_IMAGE>
      command: ["python3", "/opt/siterm-qos/siterm-qos", "--config", "/opt/siterm-qos/siterm-qos.conf"]
      securityContext:
        capabilities:
          add: ["NET_ADMIN"]
      volumeMounts:
        - {name: siterm-qos, mountPath: /opt/siterm-qos}
        - {name: certs, mountPath: /etc/grid-security/hostcert.pem, subPath: hostcert.pem}
        - {name: certs, mountPath: /etc/grid-security/hostkey.pem, subPath: hostcert.key.pem}
  volumes:
    - name: siterm-qos
      configMap: {name: siterm-qos}
    - name: certs
      secret: {secretName: <HOST_CERT_SECRET>}
```

## Install with Docker or Podman

The container has to be on a network that gives it an address from the SENSE range, such as macvlan. Its interface is usually `eth0`, so set `SITERM_QOS_INTERFACES=eth0`.

With `siterm-qos` in the XRootD image:

```bash
docker run -d --name xrootd --network <MACVLAN_NETWORK> --ip6 2001:db8:10::100 \
  --cap-add NET_ADMIN -v /etc/siterm-qos.conf:/etc/siterm-qos.conf:ro \
  -v /etc/grid-security:/etc/grid-security:ro <XROOTD_IMAGE>
```

Or in a second container that joins the network namespace of the first one:

```bash
docker run -d --name siterm-qos --network container:xrootd --cap-add NET_ADMIN \
  -v /usr/local/bin/siterm-qos:/usr/local/bin/siterm-qos:ro \
  -v /etc/siterm-qos.conf:/etc/siterm-qos.conf:ro \
  -v /etc/grid-security:/etc/grid-security:ro \
  --entrypoint /usr/local/bin/siterm-qos <SITERM_AGENT_IMAGE>
```

## Install for a named network namespace

On a host where the storage service runs in a named network namespace, run one instance per namespace. `/etc/systemd/system/siterm-qos@.service`:

```ini
[Unit]
Description=SENSE QoS for network namespace %i
After=network-online.target
Wants=network-online.target

[Service]
Environment=SITERM_QOS_CONFIG=/etc/siterm-qos-%i.conf
ExecStart=/sbin/ip netns exec %i /usr/local/bin/siterm-qos
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable --now siterm-qos@xrd1
```

Use `ip netns exec` and not `NetworkNamespacePath`. With the second one the service sees the `/sys` of the host and can read the speed of the wrong interface.

## Configuration

Settings come from the command line, the environment, or a file. The command line wins over the environment, and the environment wins over the file. The file is `/etc/siterm-qos.conf`; `--config` or `SITERM_QOS_CONFIG` selects another one. It contains `KEY=VALUE` lines and accepts only the variables below. The repository has a commented [example](https://github.com/sdn-sense/siterm/blob/master/packaging/siterm-qos/siterm-qos.conf).

| Variable | Option | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `SITERM_FRONTEND` | `--frontend` | Yes | - | Frontend URL, `https://` only |
| `SITERM_SITENAME` | `--sitename` | Yes | - | SiteRM site name |
| `SITERM_QOS_INTERFACES` | `--interface` | No | Every virtual interface | Interfaces to manage, comma separated. `--interface` can be repeated. SR-IOV and other hardware interfaces have to be named |
| `SITERM_QOS_CAPACITY` | `--capacity` | No | Interface speed | Capacity of this container in Mbps |
| `SITERM_QOS_TOTAL` | `--total` | No | Reported by the Frontend | Capacity of all senders in the range in Mbps |
| `SITERM_QOS_RESERVE` | `--reserve` | No | `1000` | Rate kept for all other traffic in Mbps |
| `SITERM_QOS_INTERVAL` | `--interval` | No | `60` | Seconds between checks |
| `X509_HOST_CERT` | `--cert` | No | `/etc/grid-security/hostcert.pem` | Certificate for the Frontend |
| `X509_HOST_KEY` | `--key` | No | `/etc/grid-security/hostkey.pem` | Key of the certificate |
| `X509_CERT_DIR` | `--capath` | No | `/etc/grid-security/certificates` | Extra CA directory, used in addition to the system CAs |

### Capacity and share

The share of a container is the request multiplied by its part of the total capacity:

```text
share = request x SITERM_QOS_CAPACITY / SITERM_QOS_TOTAL
```

![Shares on two workers]({{ site.url }}{{ site.baseurl }}/images/qos-examples/l3-worker.svg "Shares of a 40 Gbps request on two workers with two pods each")

Containers on one worker share its NIC, and their shapers do not know about each other. Divide the NIC between them with `SITERM_QOS_CAPACITY`, and set `SITERM_QOS_TOTAL` to the sum over all containers in the range.

| Setup | `SITERM_QOS_CAPACITY` | `SITERM_QOS_TOTAL` | Share of a 40 Gbps request |
| --- | ---: | ---: | ---: |
| 2 workers with 100 Gbps, 1 pod each | 100000 | 200000 | 20 Gbps |
| 2 workers with 100 Gbps, 2 pods each | 50000 | 200000 | 10 Gbps |
| 4 workers with 25 Gbps, 1 pod each | 25000 | 100000 | 10 Gbps |

Without `SITERM_QOS_TOTAL` the service uses the total that the Frontend reports for the range. The Frontend only counts ranges that an Agent lists under `qos.interfaces`. If there is no total at all, every container uses the full requested rate, and the log says so.

If a SiteRM Agent runs on the same worker, leave the container ranges out of its `qos.interfaces`. Otherwise the Agent may write a second limit on the parent interface.

### Frontend access

The certificate needs read permission in `FE/auth.yaml` of the site:

```yaml
xrootd-pod-01:
  full_dn: "/C=US/O=Example CA/CN=Example CA 1/CN=dtn-01.t2.example.org"
  permissions: r
```

`full_dn` is the issuer followed by the subject of the certificate:

```bash
openssl x509 -in /etc/grid-security/hostcert.pem -noout -issuer -subject -nameopt compat
```

Leave out `allowed_ips`, or list every address from which the container can reach the Frontend. The default route of a Multus pod often goes through `net1`, so the Frontend may see the SENSE address of the pod.

## What it does

Every 60 seconds the service logs in with the certificate, reads the active requests, and keeps the running ones whose source prefix contains an address of a managed interface. On that interface it writes one HTB class per remote prefix and one default class for all other traffic.

| Class | Rate | Ceiling |
| --- | --- | --- |
| `guaranteedCapped` | Share of the request | The same rate |
| `softCapped` | Share of the request | Capacity of the container |
| `bestEffort` | Share of 100 Mbps | Capacity of the container, after the other classes |
| All other traffic | `SITERM_QOS_RESERVE` | Capacity of the container |

- If all requests together need more than the capacity minus the reserve, all of them are scaled down.
- When a request ends, its class is removed. Without requests the interface has no rules.
- If the Frontend does not answer, the last known requests stay in place and still end on time.
- A queue discipline that another tool has set on the interface is left alone, and the service logs an error.
- The service accepts only `https` and talks only to the host in `SITERM_FRONTEND`.

## Check the installation

`--dry-run` logs in, prints the commands, and changes nothing:

```bash
kubectl exec <POD> -c <CONTAINER> -- siterm-qos --dry-run
```

With a 40 Gbps `guaranteedCapped` request and 50 Gbps of 200 Gbps it prints:

```text
# net1: 1 path(s)
qdisc add dev net1 root handle 5e5e: htb default ffff
class add dev net1 parent 5e5e: classid 5e5e:1 htb rate 50000mbit ceil 50000mbit quantum 200000 burst 300000 cburst 300000
class add dev net1 parent 5e5e:1 classid 5e5e:ffff htb rate 1000mbit ceil 50000mbit prio 2 quantum 200000 burst 300000 cburst 300000
class add dev net1 parent 5e5e:1 classid 5e5e:10 htb rate 10000mbit ceil 10000mbit prio 0 quantum 200000 burst 300000 cburst 300000
filter add dev net1 parent 5e5e: protocol ipv6 prio 1 u32 match ip6 dst 2001:db8:20::/64 flowid 5e5e:10
```

While data moves, the counters show which class the traffic uses:

```bash
kubectl exec <POD> -c <CONTAINER> -- tc -s class show dev net1
```

`siterm-qos --once` runs one cycle and exits. `siterm-qos --cleanup` removes the rules. Stopping the service leaves the rules in place until the container ends.

## Troubleshooting

| Message | What to do |
| --- | --- |
| `missing commands: tc` | Install `iproute-tc` (EL) or `iproute2` (Debian, Ubuntu) in the image |
| `Cycle failed ... HTTP Error 401` | Check `full_dn` and `allowed_ips` in `FE/auth.yaml`, and that the Frontend trusts the CA of the certificate |
| `Cycle failed ... HTTP Error 404` | `SITERM_SITENAME` is not a site of this Frontend |
| `Cycle failed ... CERTIFICATE_VERIFY_FAILED` | The CA of the Frontend is missing. Install it or set `X509_CERT_DIR` |
| `Refusing to call ...: not the configured Frontend` | Set `SITERM_FRONTEND` to the host name in the `webdomain` of the Frontend |
| `Operation not permitted` | Add `NET_ADMIN` and run as root |
| `Specified qdisc kind is unknown` | Load `sch_htb` and `cls_u32` on the worker |
| `already has a root qdisc ... not ours` | Another tool shapes this interface. Remove its rules or do not run both |
| `Speed of ... is unknown, using 10000 mbps` | Set `SITERM_QOS_CAPACITY` |
| `No Agent lists ... Using the full requested rate` | Set `SITERM_QOS_TOTAL` |
| `0 path(s)` in the dry run | No request is running, or no address of the container is in its source prefix |

## Limits

- It shapes outgoing traffic. The other site shapes its own direction.
- It covers Layer 3 requests only. Layer 2 requests are on the host and belong to the Agent.
- It does not set DSCP marks, see [DSCP Marking](/optional-install/dscp-marking/).
- A change of a request rewrites all rules of the interface, so packets in the queue are dropped once.
- HTB uses one lock per interface. Test the throughput at the rate you need.

## Related

- [Quality of Service (QoS)](/operational/quality-of-service/)
- [Agent Configuration](/customization/configuration-agent/)
- [Example Deployment: L3 Priority Paths](/getting-started/l3-deployment-example/)
