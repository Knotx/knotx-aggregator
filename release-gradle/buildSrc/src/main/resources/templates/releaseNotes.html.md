---
title: Knot.x {{version}} released!
description: We have just released a {{releaseType}} release Knot.x {{version}}.
keywords: release
order: 1
date: {{ releaseDate | date("yyyy-MM-dd") }}
knotxVersions:
  - {{version}}
---

# Knot.x {{version}}
We are extremely pleased to announce that the Knot.x version {{version}} has been released.


## Release Notes

{% for repo in repositories %}### {{ repo.title }}
{% for entry in repo.changes %}{{ entry }}
{% endfor %}{% endfor %}

## Upgrade notes