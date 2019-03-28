---
title: Get Notifications From the Terminal
description: >
  Learn how to get push notifications from your terminal to your phone and
  desktop, including automatic notifcations for long-running processes.
---

Often I'd run a long-running process and want to know when it ends when I'm
away from the computer. I found a simple way to do this using
[Pushover](https://pushover.net). Pushover lets you receive notifications on
your iOS and Android devices using their app, or via a browser such as Chrome
or Firefox. On macOS, notifications don't require a browser to be open once
set up via Safari.

To get started, [create an account](https://pushover.net/login) on their site
and log in to it. Then, note down your user key that's at the top of the
homepage. After that, choose to [create an
application](https://pushover.net/apps/build) and give it a name, such as the
name of your machine. On the application's page, take note of the token key.

Finally, add this little function to your `~/.profile`, replacing `$user_key`
and `$token_key` with your own values:

```shell
notify() {
	curl -s -F user="$user_key" \
		-F token="$token_key" \
		-F message="$*" \
		https://api.pushover.net/1/messages.json > /dev/null
}
```

After setting up [one of their apps](https://pushover.net/clients), you can
then notify yourself of anything, such as when a project has [finished
compiling](https://xkcd.com/303/) like so:

```shell
make; notify finished compiling!
```

The nice thing about this method is that it only requires curl, so you can use
it pretty much everywhere, including on servers.

More options
------------

There are two small problems with the above method. The first is that it
requires you to use Pushover, and for that you'll need to purchase a one-time
license for each of the platforms you use (iOS, Android and Desktop) after a
7-day trial period. The second problem is that just after you run the
equivalent of `sleep 1000`, you might notice that you forgot to add the
`notify` command. The answer to both these problems is
[ntfy](https://ntfy.readthedocs.io). ntfy lets you choose from a [variety of
services](https://ntfy.readthedocs.io/en/latest/#backends) and has built-in
shell integration for automatic notifications after long-running commands
finish. First, you'll need to install it:

```shell
pip install ntfy
```

You can configure Pushover with it as well if you wish. To do so, create a
`~/.ntfy.yml` file with the following contents, replacing `$user_key` and
`$token_key` as before:

```yaml
backends:
  - pushover
pushover:
  user_key: $user_key
  api_token: $token_key
```

You can omit the `api_token` option to use ntfy's key.

Then, add the following to either `~/.bashrc` or `~/.zshrc` depending on
whether you use bash or zsh:

```shell
eval "$(ntfy shell-integration -f -L 60)"
```

This will cause ntfy to send you a notification on completion of commands that
run for 60 seconds or longer. The `-f` option causes notifications to be sent
even if the terminal is in the foreground and the `-L` option specifies the
duration in seconds. You can also manually send a notification like so:

```shell
make; ntfy send "finished compiling!"
# or
ntfy done make
```

Tips
----

- If you forget to add the `notify` command, you can still do so by suspending
  a running process via `Ctrl-Z` and then resuming it by running `fg; notify
  done!`.

- I found adding `eval "$(ntfy shell-integration)"` to `~/.bashrc` slows down
  the shell's startup. To overcome this, you can manually copy the relevant
  lines from the output of `echo "$(ntfy shell-integration)"`.

- ntfy also supports providing a PID of a running process to get notified of
  its completion via `ntfy done -p $pid`. You'll need to do a `pip install
  ntfy[pid]` to enable this feature.

- I also came across [noti](https://github.com/variadico/noti) which is an
  alternative to ntfy written in Go, but with fewer services and without
  automatic notifications.
