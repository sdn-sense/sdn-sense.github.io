---
title: "Publications & Presentations"
description: "Talks, technical material, and peer-reviewed work from the SENSE project."
layout: single
classes: wide
permalink: "/docs/publications/"
author_profile: false
sidebar:
  nav: "docs"
---

<div class="archive-intro">
  <p class="eyebrow">Project library</p>
  <p class="page-lede">Explore conference talks, technical material, and peer-reviewed work from the SENSE and SiteRM teams.</p>
</div>

## Presentations

{% comment %}
Presentation records live in _data/presentations.yml. Add approved files and
preview images there instead of duplicating card markup on this page.
{% endcomment %}

<div class="presentation-grid">
  {% for presentation in site.data.presentations %}
    {% if presentation.external_url %}
      {% assign presentation_href = presentation.external_url %}
    {% else %}
      {% assign presentation_href = presentation.file | relative_url %}
    {% endif %}
    {% if presentation.cta_label %}
      {% assign presentation_action = presentation.cta_label %}
    {% elsif presentation.file %}
      {% capture presentation_action %}Download {{ presentation.format }}{% endcapture %}
    {% else %}
      {% assign presentation_action = "View presentation" %}
    {% endif %}
    <article class="presentation-card">
      {% if presentation.cover %}
        <a class="presentation-card__image" href="{{ presentation_href }}" aria-label="{{ presentation_action }}: {{ presentation.title }}">
          <img src="{{ presentation.cover | relative_url }}" alt="{{ presentation.cover_alt }}" width="{{ presentation.cover_width }}" height="{{ presentation.cover_height }}" loading="lazy">
        </a>
      {% else %}
        <a class="presentation-card__image presentation-card__placeholder" href="{{ presentation_href }}" aria-label="{{ presentation_action }}: {{ presentation.title }}">
          <span class="presentation-card__placeholder-kicker">{{ presentation.event }}</span>
          <span class="presentation-card__placeholder-title">{{ presentation.title }}</span>
        </a>
      {% endif %}
      <div class="presentation-card__body">
        <p class="card-meta">
          <time datetime="{{ presentation.date | date: '%Y-%m-%d' }}">{{ presentation.date | date: '%B %-d, %Y' }}</time>
          {% if presentation.event %}<span aria-hidden="true"> · </span>{% if presentation.event_url %}<a href="{{ presentation.event_url }}">{{ presentation.event }}</a>{% else %}{{ presentation.event }}{% endif %}{% endif %}
          {% if presentation.location and presentation.location != "" %}<span aria-hidden="true"> · </span>{{ presentation.location }}{% endif %}
          {% if presentation.time %}<span aria-hidden="true"> · </span>{{ presentation.time }}{% endif %}
        </p>
        <h3><a href="{{ presentation_href }}">{{ presentation.title }}</a></h3>
        <p>{{ presentation.summary }}</p>
        <p class="card-byline">{{ presentation.speakers | join: ", " }}</p>
        {% if presentation.contributors %}<p class="card-contributors">Contributors: {{ presentation.contributors | join: ", " }}</p>{% endif %}
        <p class="card-meta">{{ presentation.status }}<span aria-hidden="true"> · </span>{{ presentation.format }}<span aria-hidden="true"> · </span>{{ presentation.length }}</p>
        <div class="presentation-card__links">
          <a class="text-link" href="{{ presentation_href }}">{{ presentation_action }}</a>
          {% if presentation.event_url and presentation.event_url != presentation_href %}<a class="text-link text-link--secondary" href="{{ presentation.event_url }}">Event details</a>{% endif %}
          {% if presentation.recording_url %}<a class="text-link text-link--secondary" href="{{ presentation.recording_url }}">Watch recording{% if presentation.recording_start %} <span>(starts at {{ presentation.recording_start }})</span>{% endif %}</a>{% endif %}
        </div>
      </div>
    </article>
  {% endfor %}
</div>

## Selected publications

{% comment %}
Publication records live in _data/publications.yml and are ordered newest first.
Prefer canonical DOI URLs and publisher-verified metadata.
{% endcomment %}

<div class="publication-list">
  {% for publication in site.data.publications %}
    <article class="publication-card">
      <p class="card-meta">{{ publication.year }}<span aria-hidden="true"> · </span>{{ publication.venue }}</p>
      <h3><a href="{{ publication.url }}">{{ publication.title }}</a></h3>
      <p>{{ publication.summary }}</p>
      <p class="card-byline">{{ publication.authors | join: ", " }}</p>
      <a class="text-link" href="{{ publication.url }}">View publication <span class="visually-hidden">{{ publication.title }}</span></a>
    </article>
  {% endfor %}
</div>
