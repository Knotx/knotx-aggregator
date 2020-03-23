---
title: Knot.x {{shortVersion}} released!
description: We have just released a minor release Knot.x {{version}}.
author: admin
keywords: release
order: 1
date: {{ releaseDate | date("yyyy-MM-dd") }}
knotxVersions:
  - {{shortVersion}}
---

# Knot.x {{shortVersion}}


## Release Notes

{% for repo in repositories %}### {{ repo.title }}
{% for entry in repo.changes %}{{ entry }}
{% endfor %}{% endfor %}

## Upgrade notes