---
title: macOS Terminal Dark Mode Toggle
---

Add to `~/.profile`:

```shell
alias dark="osascript -e '
tell application \"System Events\" to \
tell appearance preferences to \
set dark mode to not dark mode'"
```

Use:

```terminal
$ dark
```
