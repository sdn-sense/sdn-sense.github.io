---
title: "Frontend Configuration"
layout: single
classes: wide
permalink: "/customization/configuration-frontend/"
author_profile: false
sidebar:
  nav: "docs"
---

## Intro

As higlighted in [Directory layour](/customization/configuration-layout/) page, Frontend support few configuration files inside the configuration directory:

* main.yaml - Main configuration file for Frontend;
* auth.yaml - Authentication file (allowed users/machines) to communicate with the Frontend;
* auth-re.yaml - Authentication file (allowed users/machines) to communicate with the Frontend (Regex match supported);

All 3 files must exist in FE type directory. Directory layout will be:

```bash
└── T3_US_SITENAME
    ├── Agent01 (directory)
    ├── FE (directory)
    │   ├── auth-re.yaml (file)
    │   ├── auth.yaml (file)
    │   └── main.yaml (file)
    └── mapping.yaml (file)
```

Below you will find details for configuration parameters and available options.

## Frontend configuration (auth.yaml and auth-re.yaml)


* Authentication with Frontend is possible only with valid certificate. Authorized DNs are stored in your sites directory authentication file: `/<SITENAME>/<FE_DIRNAME>/auth.yaml`. Based on the example above, it will be `/T3_US_SITENAME/FE/auth.yaml`. Authentication file lists which Certificate Authority and Distinguished Name is allowed to communicate with the Frontend. In addition to the required DNs below, `auth.yaml` or `auth-re.yaml` should include the DTNs/Hosts certificate Distinguised Name. Below is an example of minimal required DN List for full SENSE Support.

```yaml
senseoprod: # This is username. Must be unique between auth.yaml and auth-re.yaml file
  full_dn: "/C=US/O=Internet2/CN=InCommon RSA Server CA 2/C=US/ST=California/O=Energy Sciences Network/CN=sense-o.es.net"
  permissions: w # Permissions - r is for read; w is for write. SENSE Requires full write permissions. Read permissions for users/operators, that do not require any modification capabilities.
  allowed_ips: # Optional. If omitted, this credential is allowed from any client IP.
    - 198.51.100.10/32
    - 2001:db8:1234::/64
senseodev:
  full_dn: "/C=US/O=Internet2/CN=InCommon RSA Server CA 2/C=US/ST=California/O=Energy Sciences Network/CN=sense-o-dev.es.net"
  permissions: w
senseoeast:
  full_dn: "/C=US/O=Internet2/CN=InCommon RSA Server CA 2/C=US/ST=California/O=Energy Sciences Network/CN=sense-o-east.es.net"
  permissions: w
```

* In case of wildcard, `auth-re.yaml` file can be used for Regex matching. For example, to allow all hosts to communicate with SiteRM Frontend, that have IGTF Server Certificate and `<subdomain>.unl.edu` certificate CN, the following information needs to be added in `auth-re.yaml` file. In case there is no need to configure any Regex matching, create an empty file `auth-re.yaml`.

```yaml
unlallhosts:
  full_dn: "/C=US/O=Internet2/CN=InCommon RSA IGTF Server CA 3/O=University of Nebraska-Lincoln/CN=[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?.unl.edu"
  permissions: w
```

### Entry format

```yaml
username:
  full_dn: "<X.509 Distinguished Name or regex>"
  permissions: r | w
  allowed_ips:
    - "<IPv4 or IPv6 CIDR>"
```

### Fields

| Field | Required | Description |
|---|---|---|
| `full_dn` | **Yes** | Full X.509 Distinguished Name. Regex allowed only in `auth-re.yaml`. |
| `permissions` | **Yes** | `r` = read-only, `w` = read/write. SENSE requires write access. |
| `allowed_ips` | No | Optional list of IPv4 or IPv6 CIDR ranges allowed to use this credential. If this field is not specified, requests for that credential are allowed from any client IP. If specified, it must be a non-empty list, for example `198.51.100.10/32` or `2001:db8:1234::/64`. |

## Frontend configuration (main.yaml)

### `MAIN.general`

| Key | Required | Default | Description |
|---|---|---|---|
| `logDir` | No | `/var/log/siterm-site-fe/` | Directory for Frontend logs. |
| `logLevel` | No | `INFO` | Logging verbosity (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`). |
| `privatedir` | No | `/opt/siterm/config/` | Base directory for runtime artifacts. |
| `sitename`.  | Yes | - | Sitename in format of `T<level>_<country_2_letter>_<facility_name>`. Preferrable match sitename of directory structure |
| `webdomain` | Yes |. - | Frontend full HTTP URL. Once you identified the VM/Host/Ingress to run frontend, set this to: `https://<fqdn>:443` |
| `probes` | No | predefined list | Prometheus probe names for health checks run by SENSE Monitoring tools. |

Default probes:

```bash
https_v4_siterm_2xx
icmp_v4
icmp_v6
https_v6_siterm_2xx
```

## Site Configuration (`MAIN.<SITENAME>`)

Sitename listed at `MAIN.general.sitename` must have a corresponding section for Site configuration.

### Site section

| Key | Required | Default | Description |
|---|---|---|---|
| `domain` | **Yes** | — | DNS domain of the site. |
| `latitude` | **Yes** | — | Geographic latitude of the site. |
| `longitude` | **Yes** | — | Geographic longitude of the site. |
| `plugin` | **Yes** | — | Control plugin (`ansible` or `raw`). |
| `privatedir` | No | `/opt/siterm/config/<SITENAME>/` | Site-specific runtime directory. |
| `year` | **Yes** | — | First deployment year. |
| `metadata` | No | — | Arbitrary site metadata for lookup and site description. |
| `switch` | **Yes** | — | List of switch names controller by SiteRM. Arbitrary names, like `["cisco_s0", "arista_s1",...]` |
| `ipv4-address-pool` | **No** | `"10.251.85.0/24", "10.251.86.0/24", "10.251.87.0/24", "10.251.88.0/24", "10.251.89.0/24", "172.16.3.0/30", "172.17.3.0/30", "172.18.3.0/30", "172.19.3.0/30", "172.31.10.0/24", "172.31.11.0/24", "172.31.12.0/24", "172.31.13.0/24", "172.31.14.0/24", "172.31.15.0/24"` | IPv4 addresses available for SENSE to configure on the Switch/Router. In case any of the ranges are used on the network equipment, need to exclude it and configure new list. |
| `ipv6-address-pool` | **No** | `"fc00:0000:0100::/40", "fc00:0000:0200::/40", "fc00:0000:0300::/40", "fc00:0000:0400::/40", "fc00:0000:0500::/40", "fc00:0000:0600::/40", "fc00:0000:0700::/40", "fc00:0000:0800::/40", "fc00:0000:0900::/40", "fc00:0000:ff00::/40"` | IPv6 addresses available for SENSE to configure on the Switch/Router. In case any of the ranges are used on the network equipment, need to exclude it and configure new list. |
| `ipv4-subnet-pool` | No | — | IPv4 subnets allowed for SENSE to be advertised via BGP. |
| `ipv6-subnet-pool` | No | — | IPv6 subnets allowed for SENSE to be advertised via BGP. |

---

## Switch Configuration (`MAIN.<SWITCHNAME>`)

Each switch, defined under `MAIN.<SITENAME>.switch` must have switch sections under `MAIN.<SWITCH_NAME>`

### Switch defaults (auto-injected)

| Key | Required | Default | Description |
|---|---|---|---|
| `rsts_enabled` | No | — | Enable BGP Control. Supports text as: `ipv4` or `ipv4,ipv6` or `ipv6`. Requires to have `ipv<N>-subnet-pool` defined under site configuration and `private_asn` under switch. |
| `rate_limit`| No | `False` | Enable QoS enforcement on the network device |
| `bgpmp`| No | `True` | Enable BGP multipath support. Please see [Supported Network Devices](/getting-started/install-supported-network-devices/) page for device support. |
| `private_asn` | No | — | Private ASN Number. Please consult SENSE team for next available private ASN Number |
| `vrf` | No | — | VRF Name. |
| `vlan_mtu`| No | `9000` | Default VLAN MTU. |
| `allports`| No | `True` | Automatically include all ports identified on the device by Ansible. |
| `allvlans`| No | `False` | Automatically include all VLANs. |
| `vlan_range` | **Yes** | — | Global VLAN range per device for SENSE Control. This tells which VLANs are allowed to be created on the device by SENSE between one or more ports. Supports comma and dash syntax (`100-200,300`). |

---

### Ports (`MAIN.<SWITCH>.ports`)

Each port may define:

| Key | Required | Description |
|---|---|---|
| `vlan_range` | No | Overrides switch-wide VLAN range. |
| `capacity` | Conditional | Required for `raw`, optional for `ansible`. If specified for `ansible` - it will override max available capacity for port. |
| `isAlias` | No | Alias to remote port. Needed for: when LLDP is unavailable, Interface is a PortChannel; Points to a remote Site or Network |
| `wanlink` | No | Marks WAN-facing links. |
| `rate_limit` | No | Enables per-port rate limiting. |

## Final Notes

* Mandatory fields **must** be present or SiteRM Frontend will fail to start.
* Optional fields are **preset at runtime**, and are not copied into Git.
* Remote Site Configuration file is the single source of truth; local files only bootstrap by referencing a specific configuration file.

## Example and other Site configuration files

For examples, please see [SiteRM Configuration repo](https://github.com/sdn-sense/rm-configs)

## Startup configuration

The startup configuration file tells SiteRM which site configuration to pull from Git at boot time.

**Docker/Podman:** Edit `fe/conf/etc/siterm.yaml` in the cloned `siterm-startup` repository:

```yaml
GIT_REPO: https://github.com/<your-org>/rm-configs
BRANCH: master
MD5: <md5-hash-from-mapping.yaml>    # Leave empty to auto-compute md5(hostname -f)
SITENAME: T2_US_YOURSITE
```

| Parameter | Required | Description |
|---|---|---|
| `GIT_REPO` | Yes | URL to the Git repository containing site configuration files |
| `BRANCH` | Yes | Branch of the Git repository to pull configuration from |
| `MD5` | No | MD5 hash from `mapping.yaml` identifying this Frontend. If omitted, computed as `md5(hostname -f)` |
| `SITENAME` | Yes | Must match the `sitename` value in `FE/main.yaml` and `mapping.yaml` |

**Kubernetes (Helm):** These same parameters are specified directly in the Helm `values.yaml` under the `siterm` section:

```yaml
siterm:
  gitrepo: https://github.com/<your-org>/rm-configs
  gitbranch: master
  md5: <md5-hash-from-mapping.yaml>
  sitename: T2_US_YOURSITE
```

The environment file (`fe/conf/environment` for Docker, or Helm `env` values for Kubernetes) must also contain the MariaDB password:

```bash
# fe/conf/environment (Docker/Podman only)
MARIA_DB_PASSWORD=<your-secure-password>
```

**Important:** Choose a strong password and do not change it between redeployments of the same Frontend, as the database will already contain data encrypted with the original password.
