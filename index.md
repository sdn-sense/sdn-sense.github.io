---
layout: home
title: SENSE
summary: End-to-end network orchestration for science workflows.
description: SENSE gives science workflows intent-based, end-to-end network orchestration with site-controlled policy, automated provisioning, and live service visibility.
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
        <a class="button button-primary" href="{{ '/install-quick-start/' | relative_url }}">Deploy SiteRM</a>
        <a class="button" href="#how-it-works">See how SENSE works</a>
      </div>
    </div>
    <figure class="product-shot home-hero-shot">
      <img src="{{ '/images/siterm-frontend-topology.png' | relative_url }}" alt="SiteRM Frontend topology view of T2_US_Caltech: six WAN peers above three switches, linked to six transfer servers and a LAN segment" width="1575" height="740" fetchpriority="high">
      <figcaption>SiteRM Frontend topology view of T2_US_Caltech.</figcaption>
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
      <li><h3>Coordinate domains</h3><p>The orchestrator plans an end-to-end service and coordinates resource managers along the path.</p></li>
      <li><h3>Keep site control</h3><p>Each SiteRM validates requests against local policy before applying an approved configuration.</p></li>
      <li><h3>Operate the service</h3><p>Telemetry and active diagnostics help teams see service state and isolate host, network, or application issues.</p></li>
    </ul>
  </div>
</section>

<section class="section section-tint" id="how-it-works">
  <div class="shell architecture-grid">
    <figure class="architecture-figure">
      <img src="{{ '/images/sense-arch.png' | relative_url }}" alt="SENSE architecture showing orchestrators, resource managers, and supporting services" width="1280" height="726" loading="lazy">
      <figcaption>SENSE coordinates orchestration across independently operated resource domains.</figcaption>
    </figure>
    <div class="split-copy">
      <h2>Global intent, local authority</h2>
      <p>SENSE separates end-to-end planning from site-level control. The orchestrator builds the service plan; each resource manager publishes available resources, evaluates the requested change, and controls its own infrastructure.</p>
      <ol class="component-list">
        <li><h3>A workflow requests a service</h3><p>The request carries application context and network requirements.</p></li>
        <li><h3>SENSE-O computes the path</h3><p>Resource models from participating domains support multi-domain planning.</p></li>
        <li><h3>SiteRM enforces local policy</h3><p>The site accepts, rejects, or provisions the requested change on hosts and network devices.</p></li>
      </ol>
      <div class="action-row">
        <a class="text-link" href="{{ '/install-quick-start/' | relative_url }}">Read the deployment guide</a>
      </div>
    </div>
  </div>
</section>

<section class="section" id="siterm">
  <div class="shell">
    <div class="section-head">
      <h2>Site-level control for real infrastructure</h2>
      <p>SiteRM translates SENSE service requests into guarded, observable actions on the site network and connected systems.</p>
    </div>
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
<section class="section section-tint" id="participants">
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
<section class="section" id="releases">
  <div class="shell">
    <div class="section-head">
      <h2>Recent releases</h2>
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
      <p class="start-intro">Site operators can begin with the deployment checklist. Network engineers can review device coverage. Existing sites can move directly to operations and upgrades.</p>
      <ul class="start-list">
        <li class="start-card"><h3><a href="{{ '/install-quick-start/' | relative_url }}">Plan a SiteRM deployment</a></h3><p><strong>New site.</strong> Understand the Frontend, Agent, Debugger, configuration, and firewall requirements.</p></li>
        <li class="start-card"><h3><a href="{{ '/getting-started/install-supported-network-devices/' | relative_url }}">Review device capabilities</a></h3><p><strong>Network engineer.</strong> Compare model discovery, VLAN, BGP, diagnostics, and QoS support by platform.</p></li>
        <li class="start-card"><h3><a href="{{ '/operational/siterm-operations/' | relative_url }}">Operate and troubleshoot SiteRM</a></h3><p><strong>Site operator.</strong> Use service state, topology, monitoring, and active diagnostics in production.</p></li>
      </ul>
    </div>
  </div>
</section>
