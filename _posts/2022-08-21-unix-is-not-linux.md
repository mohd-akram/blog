---
title: Unix is not Linux
description: Things to be aware of when discussing the shell and Unix programs.
---

Too often on the internet, tutorials and guides are written of POSIX and Unix
tools that implicitly assume a Linux installation, and more specifically a
GNU-based one. This has many implications when it comes to everything from the
behavior of the shell, its utilities, and even the C standard library. While
the dominance of Linux might mean that one can ignore this distinction, it is
still useful to be aware of it. I've outlined some of the more prominent
discrepancies below.

## Bash is not the standard shell

The default shell that is present on all Unix systems is `sh`, not `bash`. The
language used in the portable `sh` shell is described in the
[POSIX](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
standard. However, on many Linux systems `sh` is linked to `bash` - this makes
bash operate in a more compatible way with the standard, but still allows
certain `bash` features that may not work on other systems. When in doubt,
refer to the standard.

## Long options are not Unix

Many utilities accept both a long option, eg. `grep --count` with a double
hyphen, in addition to a short option, eg. `grep -c`. The former is a GNU
invention, and they generally do not exist on other systems, such as BSDs. In
fact, the standard [`getopts`
utility](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/getopts.html),
and corresponding [`getopt` C
function](https://pubs.opengroup.org/onlinepubs/9699919799/functions/getopt.html)
only support the short style.

## Make isn't GNU make

The version of make specified by POSIX is much more limited than the GNU
version. This one is harder to deal with as the specification is lacking in
many aspects, particularly any kind of logical or conditional operators. You
can workaround this by moving some logic to a `configure` script that generates
another Makefile that is then included by the main one. Further, the BSD
`make`s have a completely different syntax than the GNU one for things like
conditionals. Luckily, if your focus is on macOS and Linux only, you can get
away with depending on GNU features as macOS's make is based on the GNU one.

## The C compiler is not GCC

This is related to the previous point, as it often comes up in Makefiles. When
referring to the C compiler in that context, it is better to use the implicit
`$(CC)` variable, and when compiling C++ code, to use the `$(CXX)` variable.
Most BSD systems have now switched to Clang as the default compiler and do not
provide a `gcc` binary. When referring to the C and C++ compilers outside of
Makefiles, the `cc` and `c++` commands are reliable and work across systems.

## GNU is not Linux

This is slightly different, but even GNU interfaces are not necessarily the
ones present on a Linux system. The Alpine Linux distribution for example,
popular as a base in Docker containers due to its light weight, forgoes the GNU
C Library for musl, and uses BusyBox instead of the GNU utilities. Therefore,
one would be well advised to try to stick to portable interfaces even if
targeting solely Linux systems.

## Unix is not UNIX

Finally, even Unix is not UNIX. The latter is a trademark that requires
certification by [The Open Group](https://www.opengroup.org/). [Certified
operating systems](https://www.opengroup.org/openbrand/register/), the most
well-known of which is macOS, are guaranteed to follow the [UNIX
specification](https://pubs.opengroup.org/onlinepubs/9699919799/). That said,
most Unix-like operating systems, including the BSDs, as well as the GNU tools
make a strong effort to stick to the standard as much as possible.
