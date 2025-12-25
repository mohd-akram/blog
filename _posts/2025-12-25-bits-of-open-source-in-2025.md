---
title: Bits of Open-Source in 2025
description: My open-source interactions in the past year.
---

## Introduction

As part of my professional and personal work, I sometimes contribute fixes or
enhancements to open-source projects. I'll be going over some of the ones that
I found interesting this year.

## Node.js

The year started off with a long-standing
[PR](https://github.com/typeorm/typeorm/pull/10349) that I had for the Node.js
ORM, TypeORM, getting merged, that improved the performance of hydrating
entities. This was the last in a series of PRs directed at performance
improvements in projects in the Node.js ecosystem that I had worked on as a
result of profiling a [slow
application](improving-date-formatting-performance-in-node-js).

Elsewhere in the Node.js world, I contributed a [few
fixes](https://github.com/nodejs/import-in-the-middle/commits/main/?author=mohd-akram&since=2025-01-01&until=2025-12-31)
to the
[import-in-the-middle](https://www.npmjs.com/package/import-in-the-middle)
project, which is a library that lets you intercept imports in Node.js, notably
used by Sentry to add instrumentation. I was already familiar with the
library's code since last year when I had submitted a
[fix](https://github.com/nodejs/import-in-the-middle/pull/85) that touched many
of its core parts. This made it slightly less tricky to debug the issues this
time around, which can be difficult due to the intricacies of module resolution
in a JavaScript runtime.

I also reported an [issue](https://github.com/nodejs/node/issues/57143) in
Node.js regarding the `spawn` and `execFile` APIs that could lead to unsafe
usage. I was happy to see it resolved quickly and released as a [deprecation
warning](https://nodejs.org/en/blog/release/v24.0.0#deprecations-and-removals)
in Node.js 24. With all the supply chain attacks seen this year, it was good to
contribute something to the security of the ecosystem. As part of investigating
this problem, I also learned that it is [almost
impossible](https://flatt.tech/research/posts/batbadbut-you-cant-securely-execute-commands-on-windows/)
to pass arguments safely to cmd on Windows, and developed
[batspawn](https://www.npmjs.com/package/batspawn) to help with that.

## MacPorts

As a maintainer for MacPorts, I sometimes run into projects that do not tag
their releases, so we need to rely on git to check if there was an update for
them. There wasn't a good way to do this, so I contributed an
[enhancement](https://github.com/macports/macports-base/pull/364) that checks
for updates in a repository using the helpful `git ls-remote` command. This was
my first contribution to MacPorts base as I had previously only contributed to
ports. For ports, I had a total of [421
commits](https://github.com/macports/macports-ports/commits/master/?author=mohd-akram&since=2025-01-01&until=2025-12-31)
in 2025 as of writing.

One notable addition to ports was the [ANGLE](https://angleproject.org)
project, developed by Google, which provides a conformant OpenGL ES
implementation on almost every platform and is used by Chrome for WebGL. As
part of porting it, I set up [git mirrors](https://github.com/gsource-mirror)
for some of the dependencies hosted on googlesource.com (which doesn't offer
stable tarballs) and understood what a bare repository is.

I also maintain [include-what-you-use](https://include-what-you-use.org) on
MacPorts, which is a neat utility that ensures you include the right headers in
a C or C++ project, and submitted [several
enhancements](https://github.com/include-what-you-use/include-what-you-use/commits/master/?author=mohd-akram&since=2025-01-01&until=2025-12-31)
to the upstream project to improve its behavior on macOS.

## macOS

Since most of my personal work is done on macOS, I sometimes run into bugs in
the core tools (or userland) that come with it. Most of the tools in macOS come
from FreeBSD, so I submit the fixes there in the hopes that they will be picked
up in the next release of macOS. Two such issues were in sed, and one of which
had originated in OpenBSD code that FreeBSD imported. I decided to submit the
[fix](https://marc.info/?l=openbsd-tech&m=172381888706699) for that one to
OpenBSD first, and reported the
[other](https://marc.info/?l=openbsd-tech&m=173383873205691), which
interestingly had already been fixed in NetBSD years ago. They were both fixed
in OpenBSD, then picked up by FreeBSD, and finally brought to macOS 26. The
fixes themselves were simple, but it was interesting to see code move across
four different operating systems --- NetBSD, OpenBSD, FreeBSD, and macOS.

Another issue encountered on macOS was that the default syntax highlighting for
shell scripts in Vim was poor. This was because the default highlighting was
for the ancient Bourne shell syntax and not the modern POSIX one. This finally
changed after I submitted a [fix](https://github.com/vim/vim/pull/16939) for
it.

Last, but not least, less (the pager) had long had an issue that was a pet
peeve of mine: when trying to copy text from a git diff (paged through less),
tabs would get converted to spaces. Someone had mentioned the exact cause and
fix for this in a StackExchange
[post](https://unix.stackexchange.com/questions/412060/how-to-get-less-to-show-tabs-as-tabs)
years ago, so I submitted the same
[fix](https://github.com/gwsw/less/pull/620), and now diffs are displayed as
expected when using `less -rU` as the git pager.

## Conclusion

This year had more of a focus on macOS fixes while last year I followed up on
patches in the Linux world, largely to support an Arabic keyboard that I had
[submitted](https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/merge_requests/549)
the year before, which required co-ordination with several projects under
Freedesktop.org, X.Org and GNOME to support a new
[keysym](https://gitlab.freedesktop.org/xorg/proto/xorgproto/-/merge_requests/78).
