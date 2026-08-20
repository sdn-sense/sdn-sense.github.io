---
title: "Manual Testing: Network Control (VLAN)"
layout: single
classes: wide
permalink: "/operational/manual-testing-network-control/"
author_profile: false
sidebar:
  nav: "docs"
---

<!-- markdownlint-disable MD036 -->

`test-runner.py` lets you test the same code path SiteRM uses to push config to your devices (`getfacts.yaml`/`applyconfig.yaml`), without going through an actual SENSE delta request. Useful for validating a new device or a template change before trusting it with production circuits.

Everything goes through the script — **you never edit `host_vars`, build an inventory, or call `ansible-playbook` by hand.**

**This can push live, saved config to real hardware.** Always:

* Use `--dry-run` first and read the rendered config before pushing for real.
* Use an obviously-fake VLAN ID/description (e.g. `SENSE-TEST-DELETE-ME`) that won't collide with anything real.
* Run `delete-vlan` to remove the test VLAN again once you're done — don't leave test config on production devices.

## Getting a shell

Run all commands below **inside your SiteRM Frontend container**:

```bash
cd /opt/siterm/config/ansible/sense
```

## Get current config/facts

```bash
python3 test-runner.py get --host <host>
```

Omit `--host` to check every host in your inventory. Add `--dry-run` to just see which hosts would be queried, with no device contact.

## Create a VLAN

```bash
python3 test-runner.py create-vlan --host <host> --vlan <vlanid> --members <interface> --description "SENSE-TEST-DELETE-ME" --dry-run
```

This renders the config that *would* be pushed, without touching the device. Read it — for the right vendor/mode you should see plain vendor CLI `set ...` commands for the VLAN (and, if you passed `--members`, for that interface).

Once it looks right, drop `--dry-run` to push it for real:

```bash
python3 test-runner.py create-vlan --host <host> --vlan <vlanid> --members <interface> --description "SENSE-TEST-DELETE-ME"
```

`--members` is optional and repeatable (`--members ae4 --members ae5`). Leaving it out is the safest test — it creates the VLAN with no interface attached, so there's zero traffic impact.

## Verify it landed

```bash
python3 test-runner.py get --host <host>
```

Confirm the VLAN shows up in the returned facts. This exercises the same read path (`getfacts.yaml`) SiteRM relies on for drift detection, so it's the real test of whether the device's response is understood correctly — not just whether the push was accepted.

## Delete the test VLAN

```bash
python3 test-runner.py delete-vlan --host <host> --vlan <vlanid> --members <interface> --dry-run
```

Same idea — check the rendered `delete ...` commands first, then drop `--dry-run` to push it. Pass the same `--members` you used when creating the VLAN. Re-run `get --host <host>` afterwards to confirm it's gone from facts too.

## Full command reference

```bash
python3 test-runner.py -h
```

* `get [--host H] [--dry-run] [--verbosity N]` — get facts/config, all hosts by default
* `create-vlan --host H --vlan V [--members M ...] [--description TEXT] [--dry-run] [--verbosity N]`
* `delete-vlan --host H --vlan V [--members M ...] [--dry-run] [--verbosity N]`

`--verbosity` raises Ansible's own verbosity (like repeating `-v`) if you need to debug a failure.
