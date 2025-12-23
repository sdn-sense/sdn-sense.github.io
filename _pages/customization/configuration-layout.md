---
title: "Configuration Layout"
layout: single
classes: wide
permalink: "/customization/configuration-layout/"
author_profile: false
sidebar:
  nav: "docs"
---

**IMPORTANT: DO NOT UPLOAD ANY SECRETS OR PASSOWRDS, ANSIBLE CONFIGURATION WITH PASSWORD/SSH KEY TO PUBLIC REPOS**. For more details about Ansible configuration, see here: [Supported Network Devices](/getting-started/install-supported-network-devices/)

## Main Site directory

* All configuration files must be valid YAML format.
* Default values are not required to be set in the configuration file. (unless you want to override the default value)
* Configuration file must be stored in a Github/Gitlab repository under /\<SITENAME>/ directory.
* SENSE team maintains Github repository for Site configurations here: [SiteRM Configuration repo](https://github.com/sdn-sense/rm-configs)
* /\<SITENAME>/ directory must contain a `mapping.yaml` file with the following format:

```yaml
---
8feb35ed655904aa30d466658756a87f: # echo -n "<hostname>" | md5sum - replace hostname with full fqdn
  config: FE/ # This is the directory where configuration files will be stored for that hostname. Directory name can be anything. To make it easier in future, preferrable to use fqdn hostname for dir names
  maintainer: "Justas Balcas" # Name of the person responsible for the this specific deployment
  status: production # Status of the deployment. Can be production, development, testing
  type: FE # Type of the deployment. Can be FE, Agent, Debugger
8e27a5535404f39045af089421c38e78: # echo -n "<hostname>" | md5sum - replace hostname with full fqdn
  config: Agent01/
  maintainer: "Justas Balcas"
  status: production
  type: Agent
```

All sites should always have minimum one FE (Frontend). With information from notes and minimal `mapping.yaml` configuration, here is how directory structure will look like initially:

```bash
└── T3_US_SITENAME (directory)
    ├── Agent01 (directory)
    ├── FE (directory)
    └── mapping.yaml (file)
```

## Frontend configuration files

Frontend support few configuration files inside Frontend configuration directory:

* main.yaml - Main configuration file for Frontend;
* auth.yaml - Authentication file (allowed users/machines) to communicate with the Frontend;
* auth-re.yaml - Authentication file (allowed users/machines) to communicate with the Frontend (Regex match supported);

All 3 files must exist in FE type directory. Directory layour will be:

```bash
└── T3_US_SITENAME
    ├── Agent01 (directory)
    ├── FE (directory)
    │   ├── auth-re.yaml (file)
    │   ├── auth.yaml (file)
    │   └── main.yaml (file)
    └── mapping.yaml (file)
```

## Agent configuration files

Agent stores only one file: `main.yaml` with full main configuration details for Frontend. Directory structure with new Agent configuration file:

```bash
└── T3_US_SITENAME
    ├── Agent01 (directory)
    │   └── main.yaml (file)
    ├── FE (directory)
    │   ├── auth-re.yaml (file)
    │   ├── auth.yaml (file)
    │   └── main.yaml (file)
    └── mapping.yaml (file)
```

## Debugger configuration files

Debugger could have it's own configuration file, but generally, this is not required. Debugger is expected to run on the same node as Agent, in this case Debugger can point to the same configuration file as Agent.