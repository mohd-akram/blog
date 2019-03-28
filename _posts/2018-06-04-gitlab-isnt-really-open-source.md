---
title: GitLab Isn’t Really Open-Source
description: >
  GitLab's open-source version is missing several features present in its
  proprietary one.
---

Microsoft [recently
announced](https://blogs.microsoft.com/blog/2018/06/04/microsoft-github-empowering-developers/)
its acquisition of GitHub which has led to a
[spike](https://twitter.com/gitlab/status/1003409836170547200) in the number of
repositories imported to GitLab. One reason for the spike is that GitLab often
touts itself as open-source, but that is only partially true.

GitLab has two versions of its software - GitLab Community Edition, the
open-source version, and GitLab Enterprise Edition, the proprietary version.
[Both](https://gitlab.com/gitlab-org/gitlab-ce/)
[versions](https://gitlab.com/gitlab-org/gitlab-ee/) have their sources
published on GitLab with the former having an MIT license and the latter a
proprietary one which requires a paid subscription with GitLab.

Originally, both versions had an MIT license, but this changed in 2014 because
GitLab found that ["the open source license of EE is
confusing"](https://about.gitlab.com/2014/02/11/gitlab-ee-license-change/) to
potential subscribers.

You can see the differences between these two versions [on their
site](https://about.gitlab.com/images/feature_page/gitlab-features.pdf). A lot
of them are focused on enterprise features such as LDAP and Kerberos
authentication, but many aren't:

>
- Host static pages (with TLS & CNAME support) from GitLab using GitLab Pages
- Contribution Analytics, see detailed statistics of contributors
- Rebase merge requests before merge
- Use fast-forward merges when possible
- Git hooks (commit message must mention an issue, no tag deletion, etc.)
- Approve Merge Requests
- Project importing from GitLab.com to your private GitLab instance
- Super-powered search using Elasticsearch

Furthermore, the free version running on GitLab.com is the Enterprise Edition.
This means that if you wish to move from their hosted service to your own one,
you would be losing several features and would even have to pay to import your
projects based on the above list.

It is therefore unsurprising that GitLab [started referring to itself as "open
core"](https://about.gitlab.com/2016/07/20/gitlab-is-open-core-github-is-closed-source/)
in 2016. The question then is - what chunk of GitLab will be considered "core"
in the future?

Perhaps GitLab would be better off providing its entire product under a more
restrictive/free license such as GPL the way companies like Red Hat operate -
they've certainly proven that it can work.
