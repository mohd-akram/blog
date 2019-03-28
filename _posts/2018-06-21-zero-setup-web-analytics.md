---
title: Zero-Setup Web Analytics
description: >
  Using GoAccess to get a visual analysis of web traffic with little effort.
---

I recently discovered [GoAccess](https://goaccess.io) which is a great tool for
analyzing server logs that you already collect in a visual manner. It's also
available on [pretty much every platform](https://goaccess.io/download#distro)
and requires no configuration to get started.

Once you've installed GoAccess on your server, you can use this short script to
get a visual report of web traffic in a single command:

```shell
#!/bin/sh
help="usage: `basename $0` [options] [user@]hostname"

i=0
for arg do
	[ "$arg" = "-h" ] || [ "$arg" = "--help" ] && echo $help && exit
	shift
	[ $i = $# ] && break
	set -- "$@" "$arg"
	i=$((i+1))
done

file=`mktemp`.html
ssh "$arg" sh << EOF > $file && `command -v xdg-open || command -v open` $file
sudo sh -c "zcat -f /var/log/nginx/access.log*" |
goaccess -o html --html-report-title=\`hostname\` --log-format=COMBINED \
	${@+"$@"} -
EOF
```

Save it as `analytics` and place it in your `PATH`. Then, using your SSH
credentials, simply do:

    analytics example.com

That's it. Your logs never leave the server and a dashboard view of your web
traffic will open in your web browser.

You can also pass [options](https://goaccess.io/man#options) to GoAccess like
so:

    analytics --enable-panel=REFERRERS example.com

The script assumes an Nginx server, but you can tweak it by just changing the
log path to wherever your server stores logs.
