---
layout: page
title: Tags
permalink: /tags/
background: '/img/bg-category.jpg'
---

<h1>Tags</h1>

<ul>
  {% for tag in site.tags %}
    <li>
      <a href="{{ "/tags/" | append: tag[0] | relative_url }}">{{ tag[0] }} ({{ tag[1].size }})</a>
    </li>
  {% endfor %}
</ul>
