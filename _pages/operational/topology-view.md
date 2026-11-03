---
title: "Topology View"
layout: single
classes: wide
permalink: "/operational/topology-view/"
author_profile: false
sidebar:
  nav: "docs"
---

> **Available from SiteRM 1.6.5.** It replaces the older topology graph on the Frontend home page.

The Frontend home page shows a diagram of the site: WAN peers at the top, switches in the middle and servers (Agents) at the bottom. It is generated on the Frontend from the latest topology data and rendered with [Archify](https://github.com/tt-a1i/archify).

## Reading the diagram

**Link speed.** Each physical link is a line coloured by its speed. Faster links are also drawn thicker, and the legend below the diagram lists the colours.

| Speed | Colour |
| --- | --- |
| up to 10G | blue |
| 25G | orange |
| 40-50G | aqua |
| 100G | yellow |
| 200G | pink |
| 400G | green |
| 800G and above | violet |
| unknown | grey, dashed |

**Port-channels.** Members of a port-channel are drawn as closely spaced parallel lines with a small ring at each end. Separate links between the same two devices are spaced a little further apart. Hover over a line or a ring to see the ports, speed and port-channel name.

**Device health.** Each switch and server has a coloured outline and a dot in its top-right corner, and the text under its name repeats the state:

| State | Meaning |
| --- | --- |
| OK (green) | All reported services are fine. |
| WARNING (amber) | At least one service reports a warning. |
| FAILED (red) | A service has failed. For switches: the last configuration fetch from the device failed (`fetch error`). |
| UNKNOWN (grey) | No report for more than 10 minutes, or the Agent never reported. |

A server's state is the worst state among its Agent services (Agent, Ruler, Debugger, ...). Cards below the diagram list every link, every WAN peer, the state of each Frontend service, and every device problem with its message.

## Filters

- **Filter switch / Filter Server:** show only the selected devices. WAN peers follow the switches they connect to.
- **Active path:** lists the active L2 connections (VLAN, state and devices). Selecting one shows only the devices on that path, including the WAN peer it leaves the site through. Links the path uses are drawn normally, other links between those devices are faded, and a Path card lists every hop with its VLAN and state.

To share a path, link to `https://<FE_HOST>/index.html?path=<CONNECTION_ID>`.

## Where the data comes from

The diagram is drawn from `topology.json`, which the Frontend's SNMPMonitoring service regenerates periodically:

- **Switch-to-switch links** come from LLDP on the switches, and **server links** from LLDP on the Agent hosts (or the `switch`/`port` settings of the Agent's interfaces when LLDP is not available).
- **Port-channel membership and link speeds** come from the switch interface data and the Agent's NIC speeds.
- **WAN peers** come from switch ports that have `isAlias` in the site configuration: ports marked `wanlink`, and any alias that leads outside the site (another domain, or a device that is not one of the site's switches or Agents).

After changing LLDP, port-channels or `isAlias` settings, the diagram updates once SNMPMonitoring has regenerated `topology.json`.

## API

All endpoints need read permission.

| Endpoint | Returns |
| --- | --- |
| `GET /api/<SITENAME>/topo/archify` | The diagram as an HTML page. Optional query parameters: `switch` and `server` (repeatable), `path` (an active connection id) and `view` (`full`, the default, or `graph` for the diagram without the cards). |
| `GET /api/<SITENAME>/topo/paths` | Active L2 connections as JSON: `id`, `state`, `vlans` and `devices`. |
| `GET /api/<SITENAME>/topo/gettopology` | The raw `topology.json`. |

The diagram page is served with `Content-Security-Policy: sandbox`, so its scripts never get access to your SiteRM session.

## In Autogole Grafana

Each SiteRM site dashboard in [Autogole Grafana](https://autogole-grafana.nrp-nautilus.io) starts with a collapsed "Topology" row that shows the diagram without the cards. Grafana shows it as a static picture: hovering works, but zoom, theme switching and export do not; use the Frontend page for those. It is refreshed at most every 5 minutes.

If the row shows "Topology for <SITE> is not available", the message says why. Usually the Frontend runs a SiteRM version older than 1.6.5, or Autogole monitoring could not get a token for the site because its Frontend was unreachable.

## Troubleshooting

- **A link is missing:** enable LLDP on both ends, or set `switch`/`port` for the Agent interface.
- **A WAN peer is missing:** the switch port needs `isAlias` in the site configuration's `ports` mapping.
- **A link shows "unknown speed":** the device did not report a speed for that port, for example a port-channel member that is down.
