---
title: Today in History, Brought to You by UNIX
---

I accidentally came across a very interesting UNIX utility, `calendar`. Despite
its name, it does not actually show you a calendar (there's `cal` for that),
but rather, it shows you past events that occurred on any given day. The
`calendar` program is pre-installed on BSD systems (including macOS). If you're
on Linux, you might need to install it:

- Ubuntu: `sudo apt install bsdmainutils`
- Fedora: `sudo dnf install calendar`

You can then create a calendar file like so:

    mkdir -p ~/.calendar
    echo "#include <calendar.world>" > ~/.calendar/calendar

Then, just run `calendar`. Here's what today's entries look like:

```
Sep 10 	National Day in Belize
Sep 10 	Moon Festival in Taiwan
Sep 10 	Korean Thanksgiving Day (Chusuk) in South Korea
Sep 10 	Gandalf escapes from Orthanc
Sep 10 	Mountain Meadows Massacre.  Mormons kill Gentile wagon train, 1857
Sep 11 	National Holiday in Chile
Sep 11 	Ethiopian New Year in Ethiopia
Sep 11 	Anniversary of military coup in Chile
Sep 11 	Terrorists destroy World Trade Center in New York, 2001
Sep 11 	CIA-sponsored terrorists overthrow Chilean government, murder President Allende, 1973
```

You can `#include` additional calendars - the full list can be seen via `ls
/usr/share/calendar` - or add your own events in the same format.

To get daily reminders of your calendar, run `sudo crontab -e` and add the
following:

    0 12 * * * calendar -a

This will mail you everyday at 12 PM with a notification in your terminal,
which you can read by running `mail` and hitting the return key, followed by
`q` and return to quit.

History
------

The original version of `calendar` was released with V7 UNIX, which was the
last UNIX to come out of Bell Labs. It had a very short man page, with the
following description:

> Calendar consults the file ‘calendar’ in the current directory and prints out
> lines that contain today’s or tomorrow’s date anywhere in the line. Most
> reasonable month-day dates such as ‘Dec. 7,’ ‘december 7,’ ‘12/7,’ etc., are
> recognized, but not ‘7 December’ or ‘7/12’. On weekends ‘tomorrow’ extends
> through Monday.
>
> When an argument is present, calendar does its job for every user who has a
> file ‘calendar’ in his login directory and sends him any positive results by
> mail(1). Normally this is done daily in the wee hours under control of
> cron(8).

It essentially reads a file like this:

```
Jan. 1 New Year
Jan. 2 Break New Year's resolutions
```

and prints out the days that match today and tomorrow.

I searched for the original implementation out of curiosity, and found it on
the helpful [UNIX history
repo](https://github.com/dspinellis/unix-history-repo/blob/Research-V7/usr/src/cmd/calendar.c):

```c
/* /usr/lib/calendar produces an egrep -f file
   that will select today's and tomorrow's
   calendar entries, with special weekend provisions

   used by calendar command
*/
#include <time.h>

#define DAY (3600*24L)

char *month[] = {
	"[Jj]an",
	"[Ff]eb",
	"[Mm]ar",
	"[Aa]pr",
	"[Mm]ay",
	"[Jj]un",
	"[Jj]ul",
	"[Aa]ug",
	"[Ss]ep",
	"[Oo]ct",
	"[Nn]ov",
	"[Dd]ec"
};
struct tm *localtime();

tprint(t)
long t;
{
	struct tm *tm;
	tm = localtime(&t);
	printf("(^|[ (,;])((%s[^ ]* *|%d/)0*%d)([^0123456789]|$)\n",
		month[tm->tm_mon], tm->tm_mon + 1, tm->tm_mday);
}

main()
{
	long t;
	time(&t);
	tprint(t);
	switch(localtime(&t)->tm_wday) {
	case 5:
		t += DAY;
		tprint(t);
	case 6:
		t += DAY;
		tprint(t);
	default:
		t += DAY;
		tprint(t);
	}
}
```

A surprisingly short file. At first glance, it doesn't seem to be reading
anything and just prints a few lines. C has unbreakable backwards
compatibility, so we can try to compile and run it:

    cc -o calendar calendar.c && ./calendar

The output:

    (^|[ (,;])(([Ss]ep[^ ]* *|9/)0*10)([^0123456789]|$)
    (^|[ (,;])(([Ss]ep[^ ]* *|9/)0*11)([^0123456789]|$)

This is when the comment at the top of the file comes in handy:

```c
/* /usr/lib/calendar produces an egrep -f file
   that will select today's and tomorrow's
   calendar entries, with special weekend provisions
   used by calendar command
*/
```

It prints a fancy regex to be used by `egrep` for selecting today's and
tomorrow's date. Where's `egrep` getting called? In `/usr/bin/calendar`:

```shell
PATH=/bin:/usr/bin
tmp=/tmp/cal$$
trap "rm $tmp; exit" 0 1 2 13 15
/usr/lib/calendar >$tmp
case $1 in
-)
	sed '
		s/\([^:]*\):.*:\(.*\):[^:]*$/y=\2 z=\1/
	' /etc/passwd \
	| while read x
	do
		eval $x
		if test -r $y/calendar; then
			egrep -f $tmp $y/calendar 2>/dev/null  | mail $z
		fi
	done;;
*)
	egrep -f $tmp calendar
esac
```

The shell script does a couple of interesting things. First, it uses a `trap`
command to run cleanup actions on exit, which in this case is to remove the
temporary file that will hold the regexes. The file is created on the next line
via `/usr/lib/calendar` which is the short C program we just compiled. Then, it
checks if an argument is given, and if so, runs `sed` on `/etc/passwd` with yet
another regex which returns each line as `y=/home/dir z=username`. This is then
piped into a while loop and `eval`d to get them as separate variables.
Finally, a check for the calendar file is done in each user's home directory,
and if it exists, `egrep` is run on it via the regex file and the resulting
events of the day are `mail`ed to the user.

The implementation is interesting because it's an excellent example of
composition and the UNIX philosophy. It uses C for the core logic, `egrep` for
filtering, `sed` for querying, `mail` for notifications and finally `cron` for
running it all.

---

At [some
point](https://github.com/dspinellis/unix-history-repo/blob/BSD-4_1c_2/usr/src/usr.bin/calendar/calendar.sh)
during the development of 4.1BSD, someone came up with the clever idea of
running the calendar file through `cpp`, the C preprocessor, taking the
composition approach even further. This two-line change would allow "a global
data base of dates to be included in users' calendar files" as the commit
mentions. Users could now use existing calendars, such as ones for holidays and
world events, with a simple `#include`.
