---
title: "Selected publications"
description: "Peer-reviewed work describing the SENSE architecture, integrations, and measured impact."
layout: single
classes: wide
permalink: "/docs/publications/"
author_profile: false
sidebar:
  nav: "docs"
---

<div class="archive-intro">
  <p class="page-lede">Explore peer-reviewed work from the SENSE and SiteRM teams. Conference talks, release notes, and practical examples now appear together in the <a href="{{ '/blog/' | relative_url }}">SENSE Blog</a>.</p>
</div>

{% comment %}
Publication records live in _data/publications.yml and are ordered newest first.
Prefer canonical DOI URLs and publisher-verified metadata.
{% endcomment %}

<div class="publication-list">
  {% for publication in site.data.publications %}
    <article class="publication-card">
      <p class="card-meta meta-list"><span>{{ publication.year }}</span><span>{{ publication.venue }}</span></p>
      <h3><a href="{{ publication.url }}">{{ publication.title }}</a></h3>
      <p>{{ publication.summary }}</p>
      <p class="card-byline">{{ publication.authors | join: ", " }}</p>
      <a class="text-link" href="{{ publication.url }}">View publication <span class="visually-hidden">{{ publication.title }}</span></a>
    </article>
  {% endfor %}
</div>
