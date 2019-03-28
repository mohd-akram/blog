---
title: macOS Terminal Timer
description: Create timers that notify you when they're done in macOS.
---

Here's how to set up a macOS terminal timer that uses notifications:

1. Enable `atrun`:

   ```shell
   sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
   ```

   If you're on macOS Mojave or higher, you'll also need to give `atrun` and
   Terminal full disk access. To do so:

   1. Open [System Preferences > Security & Privacy > Privacy > Full Disk
      Access](x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles)
      and click the lock to make changes.

   2. Click the + button to open the file dialog and use Command + Shift + G to
      go to `/usr/libexec/atrun` and open it.

   3. Repeat the process for `/Applications/Utilities/Terminal.app`.

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
