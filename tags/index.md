---
layout: page
title: Tags
permalink: /tags/
background: '/img/bg-category.jpg'
pagination:
  enabled: true
---

<h1>Tags</h1>

<ul>
  {% for tag in site.tags %}
    <li>
      <a href="{{ site.baseurl }}/tags/{{ tag[0] | slugify }}/">{{ tag[0] }} ({{ tag[1].size }})</a>
    </li>
  {% endfor %}
</ul>
