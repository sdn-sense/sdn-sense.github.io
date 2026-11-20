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
{% assign featured_presentations = site.data.presentations | where: "featured", true %}
{% assign featured_presentation = featured_presentations | first %}
{% assign participants = site.data.participants.organizations %}

<section class="home-hero">
  <div class="shell home-hero-grid">
    <div>
      <p class="eyebrow">End-to-end network orchestration</p>
      <h1>The network becomes part of the workflow.</h1>
      <p class="hero-lead">SENSE gives science applications a way to request, provision, monitor, and troubleshoot network services across sites and administrative domains.</p>
      <div class="action-row">
        <a class="button button-light" href="#how-it-works">See how SENSE works</a>
        <a class="button button-outline-light" href="{{ '/install-quick-start/' | relative_url }}">Deploy SiteRM</a>
      </div>
      <ul class="hero-proof" aria-label="SENSE capabilities">
        <li>Intent-based requests</li>
        <li>Site-controlled policy</li>
        <li>Live service visibility</li>
      </ul>
    </div>

    <div class="network-stage" aria-label="A science workflow connected through SENSE orchestration to two managed sites">
      <svg viewBox="0 0 500 440" aria-hidden="true" focusable="false">
        <defs>
          <linearGradient id="network-line" x1="40" y1="40" x2="460" y2="400" gradientUnits="userSpaceOnUse">
            <stop stop-color="#82e1ff"/>
            <stop offset="1" stop-color="#2f70ff"/>
          </linearGradient>
        </defs>
        <path d="M103 74C180 76 184 176 250 190S350 110 407 90"/>
        <path d="M250 190C218 255 157 289 101 352"/>
        <path d="M250 190C300 250 351 296 404 353"/>
        <path class="path-muted" d="M102 352C185 402 323 401 404 353"/>
      </svg>
      <div class="network-node node-workflow"><strong>Science workflow</strong><small>service intent</small></div>
      <div class="network-node node-orchestrator"><strong>SENSE-O</strong><small>multi-domain plan</small></div>
      <div class="network-node node-core"><strong>Service</strong><small>lifecycle</small></div>
      <div class="network-node node-site-a"><strong>SiteRM A</strong><small>local control</small></div>
      <div class="network-node node-site-b"><strong>SiteRM B</strong><small>local control</small></div>
    </div>
  </div>
</section>

<section class="section" id="why-sense">
  <div class="shell">
    <div class="section-heading section-heading-split">
      <div>
        <p class="eyebrow">Why SENSE</p>
        <h2>Make network behavior visible and actionable</h2>
      </div>
      <p>Distributed science depends on instruments, data, compute, and storage at many facilities. SENSE connects those resources with network services that applications can request and operators can govern.</p>
    </div>
    <ul class="card-grid card-grid-four">
      <li class="feature-card">
        <span class="feature-icon" aria-hidden="true">API</span>
        <h3>Express intent</h3>
        <p>Workflows describe the connectivity and performance they need instead of scripting device-specific changes.</p>
      </li>
      <li class="feature-card">
        <span class="feature-icon" aria-hidden="true">E2E</span>
        <h3>Coordinate domains</h3>
        <p>The orchestrator plans an end-to-end service and coordinates resource managers along the path.</p>
      </li>
      <li class="feature-card">
        <span class="feature-icon" aria-hidden="true">POL</span>
        <h3>Keep site control</h3>
        <p>Each SiteRM validates requests against local policy before applying an approved configuration.</p>
      </li>
      <li class="feature-card">
        <span class="feature-icon" aria-hidden="true">OBS</span>
        <h3>Operate the service</h3>
        <p>Telemetry and active diagnostics help teams see service state and isolate host, network, or application issues.</p>
      </li>
    </ul>
  </div>
</section>

<section class="section section-tint" id="how-it-works">
  <div class="shell architecture-grid">
    <figure class="architecture-figure">
      <img src="{{ '/images/sense-arch.png' | relative_url }}" alt="SENSE architecture showing orchestrators, resource managers, and supporting services" width="1280" height="726" loading="lazy">
      <figcaption>SENSE coordinates orchestration across independently operated resource domains.</figcaption>
    </figure>
    <div>
      <p class="eyebrow">How it works</p>
      <h2>Global intent, local authority</h2>
      <p>SENSE separates end-to-end planning from site-level control. The orchestrator builds the service plan; each resource manager publishes available resources, evaluates the requested change, and controls its own infrastructure.</p>
      <ol class="component-list">
        <li>
          <span class="component-index">01</span>
          <div><h3>A workflow requests a service</h3><p>The request carries application context and network requirements.</p></div>
        </li>
        <li>
          <span class="component-index">02</span>
          <div><h3>SENSE-O computes the path</h3><p>Resource models from participating domains support multi-domain planning.</p></div>
        </li>
        <li>
          <span class="component-index">03</span>
          <div><h3>SiteRM enforces local policy</h3><p>The site accepts, rejects, or provisions the requested change on hosts and network devices.</p></div>
        </li>
      </ol>
      <div class="action-row">
        <a class="button button-outline" href="{{ '/install-quick-start/' | relative_url }}">Read the deployment guide</a>
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="shell">
    <div class="section-heading">
      <p class="eyebrow">SiteRM</p>
      <h2>Site-level control for real infrastructure</h2>
      <p>SiteRM translates SENSE service requests into guarded, observable actions on the site network and connected systems.</p>
    </div>
    <ul class="card-grid">
      <li class="feature-card">
        <span class="feature-icon" aria-hidden="true">FE</span>
        <h3>Frontend</h3>
        <p>Publishes the site resource model, evaluates deltas, coordinates provisioning, and exposes the control and visibility API.</p>
        <a href="{{ '/main-install/frontend/' | relative_url }}">Install the Frontend</a>
      </li>
      <li class="feature-card">
        <span class="feature-icon" aria-hidden="true">AG</span>
        <h3>Agent</h3>
        <p>Reports host and interface state, then applies approved VLAN, IP, routing, DSCP, and QoS changes on managed systems.</p>
        <a href="{{ '/main-install/agent/' | relative_url }}">Install an Agent</a>
      </li>
      <li class="feature-card">
        <span class="feature-icon" aria-hidden="true">DBG</span>
        <h3>Debugger</h3>
        <p>Runs authorized tests such as ping, traceroute, iPerf, FDT, and packet capture to investigate end-to-end behavior.</p>
        <a href="{{ '/main-install/debugger/' | relative_url }}">Install the Debugger</a>
      </li>
    </ul>
  </div>
</section>

<section class="section section-dark">
  <div class="shell">
    <div class="section-heading section-heading-split">
      <div>
        <p class="eyebrow">Built for heterogeneous sites</p>
        <h2>One control plane across network platforms</h2>
      </div>
      <p>SiteRM uses a shared resource model and vendor-specific backends to collect state and apply supported services across production and software-based network systems.</p>
    </div>
    <ul class="vendor-cloud" aria-label="Supported production network platforms">
      <li>Dell OS9</li><li>Dell OS10</li><li>Arista EOS</li><li>Juniper Junos</li><li>Cisco NX-OS</li><li>SONiC</li><li>FRRouting</li><li>FRR + VPP</li>
    </ul>
    <div class="action-row" style="margin-top: 2rem">
      <a class="button button-outline-light" href="{{ '/getting-started/install-supported-network-devices/' | relative_url }}">Compare supported capabilities</a>
    </div>
  </div>
</section>

{% if participants and participants.size > 0 %}
<section class="section section-tint" id="participants">
  <div class="shell">
    <div class="section-heading section-heading-split">
      <div>
        <p class="eyebrow">Deployed across the community</p>
        <h2>Participating sites and network partners</h2>
      </div>
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
<section class="section">
  <div class="shell spotlight-grid">
    <div class="spotlight-panel">
      <p class="eyebrow">Current stable release</p>
      <span class="release-version">SiteRM {{ latest_release.version }}</span>
      <h2>{{ latest_release.summary }}</h2>
      <p class="release-meta">Published {{ latest_release.date | date: "%B %-d, %Y" }}</p>
      <div class="action-row">
        <a class="button button-light" href="{{ latest_release.url | relative_url }}">Read the release notes</a>
        <a class="button button-outline-light" href="{{ '/main-update/frontend/' | relative_url }}">Upgrade SiteRM</a>
      </div>
    </div>
    <div>
      <p class="eyebrow">Release highlights</p>
      <h2>Safer automation and clearer topology</h2>
      <p>SiteRM {{ latest_release.version }} adds the Archify topology experience, idempotent delta submission, and stable paging for delta and model views.</p>
      {% if latest_release.highlights %}
      <ul class="component-list">
        {% for highlight in latest_release.highlights %}
        <li><span class="component-index">{{ forloop.index | prepend: '0' }}</span><div><h3>{{ highlight }}</h3></div></li>
        {% endfor %}
      </ul>
      {% endif %}
    </div>
  </div>
</section>
{% endif %}

<section class="section section-tint">
  <div class="shell start-grid">
    <div>
      <p class="eyebrow">Start with SiteRM</p>
      <h2>Choose the path that matches your role</h2>
      <p>Site operators can begin with the deployment checklist. Network engineers can review device coverage. Existing sites can move directly to operations and upgrades.</p>
    </div>
    <div>
      <article class="start-card"><p class="eyebrow">New site</p><h3><a href="{{ '/install-quick-start/' | relative_url }}">Plan a SiteRM deployment</a></h3><p>Understand the Frontend, Agent, Debugger, configuration, and firewall requirements.</p></article>
      <article class="start-card"><p class="eyebrow">Network engineer</p><h3><a href="{{ '/getting-started/install-supported-network-devices/' | relative_url }}">Review device capabilities</a></h3><p>Compare model discovery, VLAN, BGP, diagnostics, and QoS support by platform.</p></article>
      <article class="start-card"><p class="eyebrow">Site operator</p><h3><a href="{{ '/operational/siterm-operations/' | relative_url }}">Operate and troubleshoot SiteRM</a></h3><p>Use service state, topology, monitoring, and active diagnostics in production.</p></article>
    </div>
  </div>
</section>

{% if releases and releases.size > 0 %}
<section class="section">
  <div class="shell">
    <div class="section-heading section-heading-split">
      <div><p class="eyebrow">Project updates</p><h2>Recent releases</h2></div>
      <p>Each release article summarizes operational impact, upgrade notes, supported platforms, and the source tag.</p>
    </div>
    <div class="release-grid">
      {% for release in releases limit: 3 %}{% include release-card.html release=release %}{% endfor %}
    </div>
    <div class="action-row" style="margin-top: 2rem"><a class="button button-outline" href="{{ '/releases/' | relative_url }}">Browse every release</a></div>
  </div>
</section>
{% endif %}

{% if featured_presentation %}
<section class="section section-tint">
  <div class="shell architecture-grid">
    <figure class="architecture-figure">
      <img src="{{ featured_presentation.cover | relative_url }}" alt="{{ featured_presentation.cover_alt }}" width="{{ featured_presentation.cover_width }}" height="{{ featured_presentation.cover_height }}" loading="lazy">
    </figure>
    <div>
      <p class="eyebrow">Featured presentation</p>
      <h2>{{ featured_presentation.title }}</h2>
      <p class="card-meta">{{ featured_presentation.event }} · {{ featured_presentation.date | date: "%B %-d, %Y" }}</p>
      <p>{{ featured_presentation.summary }}</p>
      <div class="action-row">
        <a class="button" href="{{ featured_presentation.file | relative_url }}">{{ featured_presentation.cta_label | default: "Download presentation" }}</a>
        <a class="button button-outline" href="{{ '/docs/publications/' | relative_url }}">View the project library</a>
      </div>
    </div>
  </div>
</section>
{% endif %}

<section class="section section-dark">
  <div class="shell section-heading section-heading-split" style="margin-bottom: 0">
    <div><p class="eyebrow">Work with SENSE</p><h2>Bring deterministic network services to your science workflow</h2></div>
    <div><p>Talk with the SENSE team about orchestration needs, site policy, integration, and deployment.</p><div class="action-row"><a class="button button-light" href="mailto:{{ site.email }}">Contact the SENSE team</a><a class="button button-outline-light" href="https://github.com/sdn-sense">Explore the source</a></div></div>
  </div>
</section>
