---
title: Improving Date Formatting Performance in Node.js
description: >
  A look at how I was able to improve the performance of date formatting in
  Node.js and what led me to it.
---

Some months ago, I was investigating why a particularly large response in a
Node.js application was taking too much time to produce. The application was an
aggregator for movie showtimes, and depending on the selected filters, a large
number of results could be returned. This is how I went about investigating the
issue and what came out of it.

## How to profile?

Whenever I encountered a slow running Node.js application before, I'd reach for
the `--prof` flag in `node`, which, after some processing, generated a text
file that showed which functions took the most time. For some reason, it did
not work as well as it used to (much of the CPU time spent would be marked as
"unaccounted") and it wasn't clear why. Fortunately, in the meantime Node.js
added a new flag, `--cpu-prof`. When run with this flag, `node` would create a
`.cpuprofile` file that could then be loaded into Chrome DevTools and you could
visually inspect where time is being spent in your code. This is done by going
to `chrome://inspect` in Chrome, and selecting to open dedicated DevTools for
Node. Particularly, loading the profile in the *Performance* panel and looking
at the *Bottom-Up* tab, sorted by *Self Time* in descending order. This will
show you the functions that are, quite simply, doing too much work in and of
themselves (as opposed to the total time which includes time spent calling
other functions). Expanding any entry in this view shows its callers, hence the
bottom-up (for a more visual guide, see the [DevTools
docs](https://developer.chrome.com/docs/devtools/performance/nodejs)).

## Why is it slow?

It turned out there were several libraries that the application depended on
that had performance issues. I submitted some fixes to those projects, some of
which have been released and some are still pending. However, the most
prominent bottleneck was date and time formatting. I used the
[Luxon](https://moment.github.io/luxon/) library for date and time handling in
this project, particularly for time zone support. In order for Luxon to get the
offset of a particular time zone for a given datetime, it resorts to using the
`Intl.DateTimeFormat` API. This API provides the ability to format any datetime
value in a locale-specific manner with [many
options](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/DateTimeFormat)
to customize the output. It also allows you to format a datetime in a given
time zone. Since there is no native way in JavaScript to get the offset of a
time zone ([yet](https://tc39.es/proposal-temporal/docs/)), libraries resort to
this feature to essentially format the datetime in a given time zone, then
parse the components of the formatted version and calculate the timestamp from
that. By comparing this to the known UTC timestamp, the offset can be found. As
you might guess, this is a somewhat expensive operation for a seemingly simple
requirement. In my application there might be several hundred showtimes, and
each of those would need to go through this operation in order to be used as a
Luxon timezone-aware `DateTime`, which in turn might be formatted several more
times for human and machine output.

## How to make it faster?

After figuring out the root cause, the solution was simple - find a way to get
the offset in a more efficient manner. One way to do it would be to use the
`longOffset` option to format the `timeZoneName`. Then, no other components
would be required (which slow down formatting) and the offset can be extracted
and turned into a number easily. This made things more than twice as fast, but
it was still noticeable when profiling.

## Why is it still slow?

After a lot of profiling, it was clear that the problem was in
`Intl.DateTimeFormat`. Since the `format` method is native C++ code, it won't
show up in the Chrome profiler. For that, I'd have to use something else.
Since I'm on macOS, I usually go for the
[Instruments](https://help.apple.com/instruments/mac/current/) profiler that
comes with Xcode.

Using Instruments, and specifically the *Time Profiler*, showed that
`Intl.DateTimeFormat` was implemented in the V8 engine used by Node.js, and
that did little more than call the ICU library - the International Components
for Unicode. This is the library that implements the Unicode standard, and is
used by most operating systems and browsers. While generally well-optimized, it
has a [vast surface area](https://icu.unicode.org/) so improvements can always
be made. I started looking into it.

## Making ICU faster

The first step was to write a simple benchmark that did nothing more than
format a datetime several thousand times in a loop. I ran that through
Instruments and looked at the results. Here too, the bottom-up feature (*Invert
Call Tree* in Instruments) and self time (*Self Weight*) are most useful. After
a lot of benchmarking and trial and error, there were problems in essentially
four areas:

- Memory allocations
- Floating-point operations
- Unoptimized hot paths
- Missing fast paths

### Memory allocations

This was by far the biggest culprit in the slow formatting performance. ICU
would heap allocate (`malloc`) an object for every number component formatted
in a date (eg. day, hour, minute) followed by a `free` soon after. A datetime
might have six components - year, month, day, hour, minute and second. That's
six memory allocations, times a few hundred formatting operations and it adds
up quickly. One additional allocation was also used for a calendar object that
had to be cloned per formatting operation. Eliminating all those allocations
and using the stack provided a significant performance boost right off the bat.

### Floating-point operations

This was a surprise to me, but while profiling I saw `fmod` show up a lot. This
function computes the floating-point remainder, similar to `%` for integers.
It's not surprising for calender calculations to utilize modular arithmetic
heavily, but surely there are no floats in date and time? Indeed there aren't,
and converting `fmod` to a regular `%` and ensuring integers are used
throughout provided another performance boost.

### Unoptimized hot paths

When formatting a component in a datetime, such as the hour, the formatting
code needs to get the relevant information for that particular pattern
character (in this case `H` in eg. an `HH` pattern). This was done by looping
through an array of those pattern characters until it found the matching one,
and that same index would be used for another array that contained the
information. This was changed to a simple lookup table, so it would take O(1)
time to convert a pattern character to an index rather than O(N).

### Missing fast paths

At the core of the ICU library, is the `UnicodeString` object which is used for
anything string related. In a given formatting operation, a string is
constantly appended to, and for small strings `UnicodeString` uses the stack
while for large strings it allocates on the heap, then it appends using
`memmove`. For date formatting, short strings are exclusively used, so it's
prudent to add a fast path for short strings that would fit into the existing
stack buffer. In that case, avoiding the call to `memmove` and doing a simple
unrolled loop copy for small strings proved to be noticeably faster.

## Is it fast?

With all these changes, formatting is now up to twice as fast, and sometimes
more. But is it as fast as it can get? I decided to compare with the reliable
`strftime` in the C standard library. On my 2016 MBP, running `strftime` with a
simple `%I:%M %p` format (hour:minute am/pm), it can do a million formatting
operations in around 630 ms. Doing the same with ICU 74.2 (before the
optimizations, using the equivalent `hh:mm a` format), it took almost three
times as long at 1700 ms. And now, with the recently released ICU 75.1 which
includes all the mentioned optimizations, it takes around 800 ms. A pretty good
improvement!

## Making Node.js faster

With the recently released versions
[20.13](https://nodejs.org/en/blog/release/v20.13.0) and
[22.1](https://nodejs.org/en/blog/release/v22.1.0) these changes have made
their way back to Node.js. To try them out, I ran a simple benchmark comparing
20.13 (ICU 75) and 18.20 (ICU 74). The official releases from the Node.js
website (such as the ones obtained via [nvm](https://github.com/nvm-sh/nvm))
bundle the ICU library in the same binary. If you get Node.js from your package
manager, it might use the system ICU library which might not be the latest
version. To check which version Node.js uses, run `node -p
process.versions.icu`. Finally, let's check if `Intl.DateTimeFormat` is faster
as expected:

```javascript
const fmt = new Intl.DateTimeFormat("en-US", {
  hour: "2-digit",
  minute: "2-digit",
  hour12: true,
});

const date = new Date();
const n = 1_000_000;

console.time("format");
for (let i = 0; i < n; i++) {
  fmt.format(date);
}
console.timeEnd("format");
```

Running this script, I get 2100 ms for Node.js 18 and 1400 ms for Node.js 20 -
a 1.5x improvement!
