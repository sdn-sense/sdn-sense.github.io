---
layout: home
title: SENSE
summary: End-to-end network orchestration for science workflows.
description: SENSE gives science workflows intent-based, end-to-end network orchestration across sites and domains, with local policy control and live service visibility.
image:
  path: /assets/images/social/sense-social-card.png
  width: 1200
  height: 630
  alt: SENSE end-to-end network orchestration for science workflows
permalink: /
---

{% assign releases = site.categories.releases %}
{% assign latest_release = releases | first %}
{% assign featured_presentations = site.categories.presentations | where: "featured", true %}
{% assign featured_presentation = featured_presentations | first %}
{% assign participants = site.data.participants.organizations %}

<section class="home-hero" aria-labelledby="home-title">
  <div class="shell home-hero-grid">
    <h1 id="home-title">The network becomes part of the workflow.</h1>
    <div class="home-hero-side">
      <p class="lead">SENSE gives science applications a way to request, provision, monitor, and troubleshoot network services across sites and administrative domains.</p>
      <div class="action-row">
        <a class="button button-primary" href="{{ '/architecture/' | relative_url }}">Explore the architecture</a>
        <a class="button" href="{{ '/install-quick-start/' | relative_url }}">Deploy SiteRM</a>
      </div>
    </div>
    <figure class="service-diagram home-hero-diagram">
      <div class="service-diagram__viewport" tabindex="0" role="region" aria-label="Scrollable SENSE architecture diagram">
        <img src="{{ '/images/sense-architecture.svg' | relative_url }}" alt="Science workflows call the intent-based API of the SENSE Orchestrator, which works with SENSE SSO and RTMon, runs embedded Resource Managers, and contacts SiteRM at end sites and regional networks to build one end-to-end service" width="1120" height="600" fetchpriority="high">
      </div>
      <figcaption>SENSE components and the domains they coordinate. Domain names are examples.</figcaption>
    </figure>
  </div>
</section>

<section class="section" id="why-sense">
  <div class="shell rows-layout">
    <div class="rows-head">
      <h2>Make network behavior visible and actionable</h2>
      <p>Distributed science depends on instruments, data, compute, and storage at many facilities. SENSE connects those resources with network services that applications can request and operators can govern.</p>
    </div>
    <ul class="rows">
      <li><h3>Express intent</h3><p>Workflows describe the connectivity and performance they need instead of scripting device-specific changes.</p></li>
      <li><h3>Coordinate domains</h3><p>The orchestrator plans an end-to-end service and coordinates Resource Managers along the path.</p></li>
      <li><h3>Keep local control</h3><p>Each site and network checks requests against its own policy before any configuration changes.</p></li>
      <li><h3>Operate the service</h3><p>Telemetry and active diagnostics help teams see service state and isolate host, network, or application issues.</p></li>
    </ul>
  </div>
</section>

<section class="section section-tint" id="how-it-works">
  <div class="shell architecture-grid">
    <figure class="architecture-figure">
      <img src="{{ '/images/sense-arch.png' | relative_url }}" alt="SENSE between application workflow agents above and the SDN layer below, which spans end sites, regional networks, WANs, and an SDX" width="1280" height="726" loading="lazy">
      <figcaption>SENSE sits between science workflows and the systems that control each network and end site.</figcaption>
    </figure>
    <div class="split-copy">
      <h2>Global intent, local authority</h2>
      <p>SENSE separates end-to-end planning from control of each domain. The orchestrator builds the service plan. Each Resource Manager publishes available resources, evaluates the requested change, and controls its own infrastructure.</p>
      <ol class="component-list">
        <li><h3>A workflow requests a service</h3><p>The request carries application context and network requirements.</p></li>
        <li><h3>SENSE-O computes the path</h3><p>Resource models from participating domains support multi-domain planning.</p></li>
        <li><h3>Resource Managers provision each domain</h3><p>A domain accepts or rejects the requested change, then applies it to its own hosts and network devices.</p></li>
        <li><h3>The service reports back</h3><p>Status, monitoring, and troubleshooting information return through the same API.</p></li>
      </ol>
      <div class="action-row">
        <a class="text-link" href="{{ '/architecture/' | relative_url }}">Read the architecture</a>
      </div>
    </div>
  </div>
</section>

<section class="section" id="components">
  <div class="shell">
    <div class="section-head">
      <h2>The SENSE ecosystem</h2>
      <p>An orchestrator, Resource Managers in every domain, and shared identity and monitoring.</p>
    </div>
    <ul class="service-rows">
      <li><h3>SENSE Orchestrator</h3><p>Holds the end-to-end model, plans services across domains, and manages each one from request to teardown.</p><a class="text-link" href="{{ '/architecture/' | relative_url }}#sense-orchestrator-sense-o">About SENSE-O</a></li>
      <li><h3>Resource Managers</h3><p>Control one domain each. Drivers embedded in the orchestrator reach NSI networks, Internet2 AL2S, FABRIC, L3VPNs, and clouds. Sites deploy SiteRM.</p><a class="text-link" href="{{ '/architecture/' | relative_url }}#resource-managers">Compare Resource Managers</a></li>
      <li><h3>SENSE SSO</h3><p>Provides federated sign-in, role-based access control, and the service tokens used between components.</p><a class="text-link" href="{{ '/architecture/' | relative_url }}#sense-sso">About SENSE SSO</a></li>
      <li><h3>RTMon</h3><p>Follows one flow across every domain it crosses and builds a live dashboard for that service.</p><a class="text-link" href="{{ '/architecture/' | relative_url }}#real-time-monitoring-rtmon">About RTMon</a></li>
    </ul>
  </div>
</section>

<section class="section section-tint" id="services">
  <div class="shell rows-layout">
    <div class="rows-head">
      <h2>Services across domains</h2>
      <p>Workflows choose the kind of connectivity they need. SENSE builds it across the sites and networks on the path.</p>
      <div class="action-row">
        <a class="text-link" href="{{ '/services/' | relative_url }}">Compare services</a>
      </div>
    </div>
    <ul class="rows">
      <li><h3>Layer 2 point-to-point</h3><p>Connects Data Transfer Nodes at two sites.</p></li>
      <li><h3>Layer 2 multipoint</h3><p>Puts several attachment points in one broadcast domain.</p></li>
      <li><h3>Layer 3 VPN attachment</h3><p>Adds site resources or specific flows to an existing L3VPN for a requested period.</p></li>
      <li><h3>Site L3 over P2P VLAN</h3><p>Carries selected IPv6 subnets over a traffic-engineered wide-area path.</p></li>
    </ul>
  </div>
</section>

<section class="section" id="use-cases">
  <div class="shell">
    <div class="section-head">
      <h2>Where SENSE is used</h2>
      <p>LHC data movement uses SENSE services in production. Resource orchestration for the American Science Cloud is in design and prototype.</p>
    </div>
    <ul class="service-rows">
      <li><h3>Priority Network Service</h3><p>Routes chosen IPv6 subnets over an ESnet OSCARS circuit between two sites. Traffic returns to the default path when the service ends.</p><a class="text-link" href="{{ '/services/' | relative_url }}#priority-network-service">How it works</a></li>
      <li><h3>Rucio priority transfers</h3><p>Gives authorized CMS and ATLAS users priority for individual Rucio replication rules.</p><a class="text-link" href="{{ '/services/' | relative_url }}#rucio-priority-data-transfer-service">Read about Rucio</a></li>
      <li><h3>AmSC resource orchestration</h3><p>Extends the SENSE orchestration framework to compute and data alongside the network.</p><a class="text-link" href="{{ '/services/' | relative_url }}#amsc-resource-orchestration">Read about AmSC-IRO</a></li>
    </ul>
  </div>
</section>

<section class="section section-tint" id="siterm">
  <div class="shell">
    <div class="section-head">
      <h2>SiteRM: control at the site</h2>
      <p>SiteRM is the Resource Manager that sites deploy and own. It translates SENSE service requests into guarded, observable actions on the site network and connected systems.</p>
    </div>
    <figure class="product-shot siterm-shot">
      <img src="{{ '/images/siterm-frontend-topology.png' | relative_url }}" alt="SiteRM Frontend topology view of T2_US_Caltech: six WAN peers above three switches, linked to six transfer servers and a LAN segment" width="1575" height="740" loading="lazy">
      <figcaption>SiteRM Frontend topology view of T2_US_Caltech.</figcaption>
    </figure>
    <ul class="service-rows">
      <li><h3>Frontend</h3><p>Publishes the site resource model, evaluates deltas, coordinates provisioning, and exposes the control and visibility API.</p><a class="text-link" href="{{ '/main-install/frontend/' | relative_url }}">Install the Frontend</a></li>
      <li><h3>Agent</h3><p>Reports host and interface state, then applies approved VLAN, IP, routing, DSCP, and QoS changes on managed systems.</p><a class="text-link" href="{{ '/main-install/agent/' | relative_url }}">Install an Agent</a></li>
      <li><h3>Debugger</h3><p>Runs authorized tests such as ping, traceroute, iPerf, FDT, and packet capture to investigate end-to-end behavior.</p><a class="text-link" href="{{ '/main-install/debugger/' | relative_url }}">Install the Debugger</a></li>
    </ul>
    <div class="platform-panel">
      <div>
        <h3>One control plane across network platforms</h3>
        <p>SiteRM uses a shared resource model and vendor-specific backends to collect state and apply supported services across production and software-based network systems.</p>
        <div class="action-row">
          <a class="text-link" href="{{ '/getting-started/install-supported-network-devices/' | relative_url }}">Compare supported capabilities</a>
        </div>
      </div>
      <ul class="vendor-cloud" aria-label="Supported production network platforms">
        <li>Dell OS9</li><li>Dell OS10</li><li>Arista EOS</li><li>Juniper Junos</li><li>Cisco NX-OS</li><li>SONiC</li><li>FRRouting</li><li>FRR + VPP</li>
      </ul>
    </div>
  </div>
</section>

{% if participants and participants.size > 0 %}
<section class="section" id="participants">
  <div class="shell">
    <div class="section-head">
      <h2>Participating sites and network partners</h2>
      <p>Current SiteRM configurations span production facilities, research networks, testbeds, and sites deploying now. Organizations are deduplicated from the public-facing site inventory; internal topology details are not published.</p>
    </div>
    <ul class="participant-grid" aria-label="SENSE participating organizations">
      {% for participant in participants %}
      <li>
        <a class="participant-card" href="{{ participant.url }}">
          <span class="participant-logo" aria-hidden="true">
            <img src="{{ participant.mark | relative_url }}" alt="" width="240" height="96" loading="lazy" style="--participant-logo-scale: {{ participant.logo_scale | default: 1 }};">
          </span>
          <span class="participant-copy">
            <strong>{{ participant.short_name | default: participant.name }}</strong>
            <small>{{ participant.category }}</small>
          </span>
        </a>
      </li>
      {% endfor %}
    </ul>
    <p class="participant-note">Deployment inventory verified {{ site.data.participants.verified | date: "%B %-d, %Y" }} from <code>rm-configs</code>. This is a technical participation list, not a sponsorship claim.</p>
  </div>
</section>
{% endif %}

{% if latest_release %}
<section class="section section-tint" id="releases">
  <div class="shell">
    <div class="section-head">
      <h2>Recent SiteRM releases</h2>
      <p>Each release article summarizes operational impact, upgrade notes, supported platforms, and the source tag.</p>
    </div>
    <div class="release-lead">
      <p class="release-version"><small>Current stable release</small>{{ latest_release.version }}</p>
      <div>
        <h3>{{ latest_release.summary }}</h3>
        <p class="release-meta">SiteRM {{ latest_release.version }}, published {{ latest_release.date | date: "%B %-d, %Y" }}</p>
        {% if latest_release.highlights %}
        <ul>
          {% for highlight in latest_release.highlights %}<li>{{ highlight }}</li>{% endfor %}
        </ul>
        {% endif %}
        <div class="action-row">
          <a class="button" href="{{ latest_release.url | relative_url }}">Read the release notes</a>
          <a class="text-link" href="{{ '/main-update/frontend/' | relative_url }}">Upgrade SiteRM</a>
        </div>
      </div>
    </div>
    {% if releases.size > 1 %}
    <div class="release-list">
      {% for release in releases offset: 1 limit: 2 %}{% include release-card.html release=release %}{% endfor %}
    </div>
    {% endif %}
    <a class="text-link" href="{{ '/releases/' | relative_url }}">Browse every release</a>
  </div>
</section>
{% endif %}

{% if featured_presentation %}
<section class="section" id="presentation">
  <div class="shell architecture-grid architecture-grid--reverse">
    <figure class="architecture-figure">
      <img src="{{ featured_presentation.cover | relative_url }}" alt="{{ featured_presentation.cover_alt }}" width="{{ featured_presentation.cover_width }}" height="{{ featured_presentation.cover_height }}" loading="lazy">
    </figure>
    <div class="split-copy">
      <h2>{{ featured_presentation.title }}</h2>
      <p class="card-meta meta-list"><span>{{ featured_presentation.event }}</span><time datetime="{{ featured_presentation.date | date_to_xmlschema }}">{{ featured_presentation.date | date: "%B %-d, %Y" }}</time></p>
      <p>{{ featured_presentation.summary }}</p>
      <div class="action-row">
        <a class="button" href="{{ featured_presentation.file | relative_url }}">{{ featured_presentation.cta_label | default: "Download presentation" }}</a>
        <a class="text-link" href="{{ '/blog/' | relative_url }}">Browse the blog</a>
      </div>
    </div>
  </div>
</section>
{% endif %}

<section class="section section-tint" id="start">
  <div class="shell close-grid">
    <div>
      <h2>Bring deterministic network services to your science workflow</h2>
      <p>Talk with the SENSE team about orchestration needs, site policy, integration, and deployment.</p>
      <div class="action-row">
        <a class="button" href="mailto:{{ site.email }}">Contact the SENSE team</a>
        <a class="text-link" href="https://github.com/sdn-sense">Explore the source</a>
      </div>
    </div>
    <div>
      <h2 class="start-title">Choose the path that matches your role</h2>
      <p class="start-intro">Workflow developers can start with the Python client. Site operators can begin with the deployment checklist, network engineers can review device coverage, and existing sites can move directly to operations and upgrades.</p>
      <ul class="start-list">
        <li class="start-card"><h3><a href="{{ '/blog/sense-client-discovery-and-scheduling/' | relative_url }}">Request services from a workflow</a></h3><p><strong>Workflow developer.</strong> Install the Python client, discover endpoints, and schedule a service.</p></li>
        <li class="start-card"><h3><a href="{{ '/install-quick-start/' | relative_url }}">Plan a SiteRM deployment</a></h3><p><strong>New site.</strong> Understand the Frontend, Agent, Debugger, configuration, and firewall requirements.</p></li>
        <li class="start-card"><h3><a href="{{ '/getting-started/install-supported-network-devices/' | relative_url }}">Review device capabilities</a></h3><p><strong>Network engineer.</strong> Compare model discovery, VLAN, BGP, diagnostics, and QoS support by platform.</p></li>
        <li class="start-card"><h3><a href="{{ '/operational/siterm-operations/' | relative_url }}">Operate and troubleshoot SiteRM</a></h3><p><strong>Site operator.</strong> Use service state, topology, monitoring, and active diagnostics in production.</p></li>
      </ul>
    </div>
  </div>
</section>
