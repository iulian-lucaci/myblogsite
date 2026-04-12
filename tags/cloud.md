---
layout: page
title: Tag Cloud
permalink: /tags/cloud/
background: '/img/bg-category.jpg'
description: Browse your tags by popularity in a visual cloud.
---

<p>Browse all tags by popularity. Larger tags have more posts.</p>

<div class="tag-cloud">
  {% assign min_count = 9999 %}
  {% assign max_count = 0 %}
  {% for tag in site.tags %}
    {% assign count = tag[1].size %}
    {% if count > max_count %}
      {% assign max_count = count %}
    {% endif %}
    {% if count < min_count %}
      {% assign min_count = count %}
    {% endif %}
  {% endfor %}
  {% assign range = max_count | minus: min_count %}

  {% for tag in site.tags %}
    {% assign count = tag[1].size %}
    {% if range > 0 %}
      {% assign weight = count | minus: min_count | times: 4 | divided_by: range | plus: 1 %}
    {% else %}
      {% assign weight = 2 %}
    {% endif %}
    <a class="tag-cloud-item tag-weight-{{ weight }}" href="{{ "/tags/" | append: tag[0] | relative_url }}" title="{{ count }} post{% if count != 1 %}s{% endif %}">
      {{ tag[0] | capitalize }}
    </a>
  {% endfor %}
</div>
