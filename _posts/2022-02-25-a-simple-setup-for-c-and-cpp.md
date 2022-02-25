---
title: A Simple Setup for C and C++
description: >
  A few steps to allow quick development and debugging of C and C++ programs.
---

When developing C and C++ programs, the default compiler and debugger options
can be very bare bones, and not particularly helpful while developing. This can
lead to many unnecessary footguns and friction during development. Typically,
a build system is introduced, whether via an IDE such as Visual Studio or using
some form of makefiles. For quick experimentation and small programs, these can
be heavy, slow or complicated. With some minor changes, we can get much more
help from the compiler to write safer programs from the get-go, all while
reducing friction throughout the process.

Compiler
--------

The compiler comes with a lot of useful flags to catch common problems. A good
set of defaults is the following:

- `-Wall`, `-Wextra` - enable many useful warnings
- `-pedantic` - warn when using non-standard language extensions
- `-fsanitize=address,leak,undefined` - catch issues relating to memory and
  undefined behavior
- `-D_LIBCPP_DEBUG=1` (for Clang's `libc++` - used by default on macOS and FreeBSD) or `-D_GLIBCXX_DEBUG`
  (GCC's `libstdc++` - used on Linux) - catch undefined behavior when using the C++ library

Now let's try a quick example to see how these can help:

```c
#include <stdio.h>

int main(void)
{
	int values[] = { -1, 14, 32, -5, 24, 40, -3, 96, 23 };
	int total;
	for (int i = 0; i < 10; i++) {
		total += total*values[i] + 1;
	}
	printf("%d\n", total);
	return 0;
}
```

Save this file as `example.c`. You can then compile it by running
`make example` - this works because `make` will auto-detect the C file and
use a pre-defined implicit rule to build an `example` executable. Then,
run the file with `./example`. You will see that it will compile and run
without any issues, and print a total like `1503498210`. Now let's try
compiling with some warnings:

```
make example CFLAGS="-Wall -Wextra -pedantic"
```

We get one warning:

```
example.c:8:3: warning: variable 'total' is uninitialized when used here [-Wuninitialized]
                total += total*values[i] + 1;
                ^~~~~
example.c:6:11: note: initialize the variable 'total' to silence this warning
        int total;
                 ^
                  = 0
1 warning generated.
```

Easy enough to fix by setting `total` to 0 when declaring it. When compiling
again, we get no warnings and our little program is seemingly perfect!

### Sanitizers

Unfortunately, compilers do not catch everything at compile-time. Sometimes
the code needs to run to detect other kinds of problems. This is known as
dynamic analysis, as opposed to static analysis, and is done with the help of
sanitizers. Let's add a couple more flags to our build:

```
make -B example CFLAGS="-Wall -Wextra -pedantic \
	-fsanitize=address,leak,undefined"
```

*Note*: If you get a compile error, it might be because you need to install
additional libraries for these to work, namely `libasan`, `liblsan` and
`libubsan`, which you can do via your package manager.

Compiling again will not yield any new warnings. However, run the program now
and you'll discover some new things:

```
example.c:8:17: runtime error: signed integer overflow: 420559700 * 23 cannot be represented in type 'int'
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior example.c:8:17 in
example.c:8:18: runtime error: index 9 out of bounds for type 'int [9]'
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior example.c:8:18 in
=================================================================
...
```

The sanitizers have detected two issues in our code. Our bounds check is faulty,
it should be `i < 9` rather than `i < 10`, and our result had been overflowing
due to using an `int` instead of a `long` for the total. Fixing both those issues,
and adjusting the `printf` format string to use `%ld` to match the new type,
we compile and run again. This time we get the correct result, `10093432801`.

### C++

While sanitizers are useful, they can come with significant overhead to the
program, especially the address sanitizer. When writing modern C++, where use
of raw arrays and pointers can be less frequent, it might be helpful to just
check for out-of-bounds accesses at the library level. The C++ libraries
provided allow this by defining `_LIBCPP_DEBUG`/`_GLIBCXX_DEBUG`. `libstdc++`
also provides `_GLIBCXX_DEBUG_PEDANTIC` for further checks of non-standard
behavior.

Let's rewrite our program in C++:

```c++
#include <iostream>
#include <vector>

int main()
{
	std::vector<int> values = { -1, 14, 32, -5, 24, 40, -3, 96, 23 };
	int total;
	// Use a range-based for loop!
	for (int i = 0; i < 10; i++) {
		total += total*values[i] + 1;
	}
	std::cout << total << std::endl;
}
```

Compile the program with:

```
make example2 CPPFLAGS="-D_LIBCPP_DEBUG=1 -D_GLIBCXX_DEBUG" \
	CXXFLAGS="-std=c++20 -Wall -Wextra -pedantic -fsanitize=undefined"
```

When running our program, we get this:

```
example2.cpp:9:17: runtime error: signed integer overflow: 420559700 * 23 cannot be represented in type 'int'
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior example2.cpp:9:17 in
/usr/include/c++/v1/vector:1549: _LIBCPP_ASSERT '__n < size()' failed. vector[] index out of bounds
Abort trap: 6
```

Now we can resolve the overflow and out-of-bounds errors as before.

Debugger
--------

Clang comes with a powerful debugger, `lldb`, that also includes a convenient
GUI. If you use GCC, its respective debugger, `gdb`, also comes with a TUI mode
that can be accessed via `gdb -tui`. Both debuggers are quite similar and you
can find a helpful command map on the [LLDB
website](https://lldb.llvm.org/use/map.html). To use the debugger, rebuild the
executable with the `-g` flag to generate debug information:

```
make -B example CFLAGS="-g -Wall -Wextra -pedantic -fsanitize=address,leak,undefined"
```

Then, enter the debugger by running `lldb example`. Once in the REPL, you'll
need to run the program. Enter `r` or `run` to do so. This will cause it to
run to completion, which is not exactly what we want. This time, enter
`b main` to create a breakpoint at `main` so the debugger pauses just before
our code runs. Then, run again. The debugger will now pause at the
first line of our program. You can step to the next line using `n`. You can
view the current variables at any time using `v`, or a specific variable by specifying it, eg.
`v total`. To continue till the next breakpoint or the end, use `c`.

### GUI

It might be helpful to use the debugger's GUI instead. Right after running the
program with `r`, enter `gui` to go to GUI mode. The same keyboard shortcuts
will work there too, and there will be some additional ones that can be seen
with `h`. Once done, press Escape to exit the GUI.

### Debugging an executable that uses stdin

One thing you might notice is that there is no way to pass stdin to a debugged
program. There's a simple fix for this. Pass a file to lldb like so:

```
lldb example 3< input.txt
```

Then, run `set set target.input-path /dev/fd/3` at the beginning of the debug
session.

Simplifying the process
-----------------------

There's a lot to take in here, and too many steps in some cases. We can simplify
the process with some configuration. First, add the following aliases to your
shell's profile:

```
alias build="make \
CPPFLAGS="-D_LIBCPP_DEBUG=1 -D_GLIBCXX_DEBUG" \
CFLAGS=\"-g -Wall -Wextra -pedantic -fsanitize=address,leak,undefined\" \
CXXFLAGS=\"-std=c++20 -g -Wall -Wextra -pedantic -fsanitize=undefined\""

alias debug="lldb -o r"
```

You can tweak this alias to your liking. For example, you can use `CC` and `CXX`
to specify your preferred C and C++ compiler respectively.

Then, add the following to `~/.lldbinit`:

```
set set target.input-path /dev/fd/3
b main
```

This will automatically set the default input path and create a breakpoint at
`main` whenever you launch `lldb`. This leaves only one command, actually
running the program via `r` which is what the `debug` alias above achieves.

Now, it's as simple as `build example` and `debug example` to quickly build
and debug programs. You can pass additional files and libraries to the `build`
command via the `LDLIBS` variable. For release builds, once you're happy
with your program, call `make` directly with appropriate flags, such as `-O2`
for optimization, and avoid using the debug and sanitizer flags. Once your
project has become larger than a few files, and especially if your project is
shared with other people, it might be worth adding explicit targets to your
build system that perform similar functions to your local aliases.

Documentation
-------------

The easiest way to get documentation for any C standard library function is to
use `man`. For example, to see the documentation for `printf`, use `man 3
printf`. You can also view the list of functions in a header, eg. `man 3
stdio`. For C++, you might need to install a libstdc++ docs package. This will
then allow you to look up documentation for C++ standard library namespaces and
classes, eg. `man std::string`.
