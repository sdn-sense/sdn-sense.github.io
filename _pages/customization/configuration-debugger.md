---
title: "Debugger Configuration"
layout: single
classes: wide
permalink: "/customization/configuration-debugger/"
author_profile: false
sidebar:
  nav: "docs"
---

## Debugger configuration files

Debugger could have it's own configuration file, but generally, this is not required. Debugger is expected to run on the same node as Agent, in this case Debugger can point to the same configuration file as Agent. Point debugger to the same Sitename and MD5 as Agent.

## Manual file mode

Git-backed configuration is the default. To run a Debugger from a local `main.yaml` file instead, provide that file at startup — this is the same mechanism used by [Agent manual file mode](/customization/configuration-agent/#manual-file-mode), and the same `main.yaml` can be shared between Agent and Debugger on the same node.

**Docker/Podman:**

```bash
./run.sh -i latest -m /path/to/main.yaml
```

The startup script mounts the file under `/etc/siterm-config/main.yaml`, sets `MAIN_CONFIG_FILE`, sets `MAPPING_TYPE=Agent`, and SiteRM skips the Git configuration fetch. You can also configure the same behavior directly in `debugger/conf/etc/siterm.yaml`:

```yaml
SITENAME: T3_US_SITENAME
MAPPING_TYPE: Agent
MAIN_CONFIG_FILE: /etc/siterm-config/main.yaml
```

**Kubernetes (Helm, `siterm-debugger` chart):**

```yaml
manualConfig:
  enabled: true
  main: |
    MAIN:
      general:
        sitename: T3_US_SITENAME
```

`MAPPING_TYPE` is always `Agent` for Debugger (there is no separate Debugger mapping type) — the chart and `run.sh` set this automatically.