---
title: macOS Terminal Timer
description: Create timers that notify you when they're done in macOS.
---

Here's how to set up a macOS terminal timer that uses notifications:

1. Enable `atrun`:

   ```shell
   sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
   ```

2. Install `reattach-to-user-namespace`:

    - Homebrew: `brew install reattach-to-user-namespace`
    - MacPorts: `sudo port install tmux-pasteboard`

3. Add to `~/.profile`:

   ```shell
   after() (
   	count=$1; shift
   	unit=$1; shift
   	title=`echo $* | sed 's/"/\\\"/g'`
   	at now + $count $unit <<-EOF
   	reattach-to-user-namespace osascript -e '
   	display notification with title "$title" sound name ""'
   	EOF
   )
   ```

4. Enjoy:

   ```terminal
   $ after 1 minute cookies are ready!
   ```
