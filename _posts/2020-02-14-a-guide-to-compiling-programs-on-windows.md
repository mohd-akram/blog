---
title: A Guide to Compiling Programs on Windows
description: >
  A guide to compiling C programs on Windows, with all the gotchas in one
  place.
---

Compiling a program on a UNIX or UNIX-like system is often as simple as running
`cc main.c` and having your executable ready to go. Things are not so simple on
Windows. When it comes to compilation and running your code, Windows follows
the mantra of make simple things difficult and make hard things possible. In
this post, I will attempt to save you and my future self much head-scratching
over seemingly simple tasks.

Hello World
-----------

The first program we want to write is a simple "hello world":

```c
#include <stdio.h>

int main(void)
{
	puts("Hello, world!");
	return 0;
}
```

Now if you save this file as `main.c` on your Desktop and try to run `cc
main.c`, you will be greeted with this message:

```
'cc' is not recognized as an internal or external command,
operable program or batch file.
```

This is understandable since we are on Windows and not a UNIX OS. The first
step you'll need to do is download [*Build Tools for Visual Studio
20xx*](https://visualstudio.microsoft.com/downloads/). Open the installer,
select *C++ build tools* and hit *Install*. Despite the name, these tools also
support C, specifically C99 at the time of writing. The typical way of
compiling programs on Windows involves using the full version of Visual Studio
and doing everything there, but this guide will be focused on using the
terminal exclusively. If you already have an existing version of Visual Studio
installed, you do not need to install the Build Tools and can simply replace
the references to `BuildTools` in the environment variables below with the
version you have, e.g., `Community`.

Once you've done that, the next thing you'll want to do is set up some
environment variables to use these tools. Hit the Windows key and search for
"environment variables" and you'll find an option mentioning them. You'll want
to edit the *User variables* and not the *System variables*.

For simplicity, the rest of this post will assume the latest version of Visual
Studio (currently 2019) and a 64-bit version of Windows 10. The first
environment variable to be set is the location of our new installation:

| Variable       | Value |
|----------------|-------|
| `VSInstallDir` | `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\` |

Then, add `%VSInstallDir%VC\Auxiliary\Build` to your `PATH` variable.

This is sufficient for us to compile our "hello world" program. Close your
existing terminal window and open a new one for the `PATH` to refresh, and `cd`
to where you stored your `main.c` file. Now, run the following:

```console
vcvars64
cl main.c
main
```

The first line sets the environment up for compiling a 64-bit program (use
`vcvars32` for 32-bit), and adds where `cl.exe` is to your path. The next line
compiles the program, creating an executable with the same name as the source
file (`main.exe`) and the third line runs it.

We could stop here and simply call `vcvars64` once before using the compiler.
However, that's not very convenient. You might have also noticed that
`vcvars64` isn't exactly the fastest program to run. Furthermore, if you try to
call `vcvars64` a few times in one terminal session, say 5 or more times you'll
eventually see this lovely message:

```
The input line is too long.
The syntax of the command is incorrect.
```

This is because `vcvars64` isn't the smartest program either. It keeps adding
the same paths to the `PATH` environment variable every time you call it until
it exceeds the terminal limit. Run `set path` to see for yourself.

Beyond vcvars
-------------

To avoid waiting for `vcvars64` to finish whatever it's taking several seconds
to do, we can set up our environment beforehand to bypass it completely. First,
add the following environment variable:

| Variable            | Value |
|---------------------|-------|
| `VCToolsInstallDir` | `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\xx.xx.xxxxx\`

Replace the `xx.xx.xxxxx` with the current version of the compiler which you
can get by running `dir /b "%VSInstallDir%VC\Tools\MSVC"`. You might need to
update this environment variable after updating Visual Studio.

Next, add the following environment variables:

| Variable            | Value                                     |
|---------------------|-------------------------------------------|
| `WindowsSDKDir`     | `C:\Program Files (x86)\Windows Kits\10\` |
| `WindowsSDKVersion` | `xx.x.xxxxx.x\`                           |

Replace the `xx.x.xxxxx.x` with the latest version of the Windows SDK, which
you can get by running `dir /b /o-d "%WindowsSDKDir%Lib"` and selecting the top
entry. You might also need to update this environment variable when you update
Windows.

So far, we have only added convenience variables that we will be making use of
now. Add the following environment variables:

| Variable  | Value |
|-----------|-------|
| `INCLUDE` | `%VCToolsInstallDir%include;%WindowsSDKDir%Include\%WindowsSDKVersion%shared;%WindowsSDKDir%Include\%WindowsSDKVersion%ucrt;%WindowsSDKDir%Include\%WindowsSDKVersion%um`
| `LIB`     | `%VCToolsInstallDir%lib\x64;%WindowsSDKDir%Lib\%WindowsSDKVersion%ucrt\x64;%WindowsSDKDir%Lib\%WindowsSDKVersion%um\x64`

This will add the necessary header files (in our case, `stdio.h`) and library
files (in our case, the C library `libcmt.lib`) to our search paths. Add
`%VCToolsInstallDir%bin\Hostx64\x64` to your `PATH` variable (this will give us
`cl.exe`).

Now, close your terminal window and open a new one. Go back to your project
folder and run `cl main.c` again. You'll see that it now compiles successfully
&mdash; no `vcvars` needed.

### What are those folders

| Name     | Description                                           |
|----------|-------------------------------------------------------|
| `ucrt`   | Universal C Runtime Library                           |
| `um`     | User mode APIs (contain the bulk of the Windows SDK)  |
| `shared` | Shared components                                     |

Incorporating the Windows API
-----------------------------

Now that we've written our program, we can start to incorporate some Windows
API features. Let's say we want to add a "tada" sound every time the program is
run, instead of a "hello world" message. We'd also like to hide the console
window when the program runs, such as when double-clicking it from Explorer.
This is what the new program looks like:

```c
#include <windows.h>

int main(void)
{
	PlaySound("C:\\Windows\\Media\\tada.wav", NULL, SND_FILENAME);
	return 0;
}
```

If you try to compile this program now, you will get this message:

```
main.obj : error LNK2019: unresolved external symbol __imp_PlaySoundA referenced in function main
main.exe : fatal error LNK1120: 1 unresolved externals
```

As you can guess by the `__imp_PlaySoundA`, it's having trouble with the
`PlaySound` function. In order to use a Windows API function, we need to link
the correct library. To know which one to link, you can look up [the
function](https://docs.microsoft.com/en-us/previous-versions/dd743680(v=vs.85))
on the internet. At the top of the function's page on the Microsoft Docs
website, you'll find the function declaration, which can be deciphered using a
[helpful
table](https://docs.microsoft.com/en-us/windows/win32/winprog/windows-data-types).
Towards the end of the page you'll find the name of the library required. In
this case, it's `winmm.lib`. Try to compile again, this time running `cl main.c
winmm.lib`. No more linker error! Let's also change the name of the output file
using the `/Fe` flag. Run `cl /Fe:tada main.c winmm.lib`. Now, say the magic
word - `tada`!

Hiding the console window
-------------------------

To get rid of the console window, we have to compile our program with the
`/subsystem:windows` flag passed to the linker. This is done by adding the
linker flags at the end of the compile command, following the `/link` flag. The
full command will be `cl /Fe:tada main.c winmm.lib /link /subsystem:windows`.
You might be disappointed to stumble upon yet another error message:

```
LIBCMT.lib(exe_winmain.obj) : error LNK2019: unresolved external symbol WinMain referenced in function "int __cdecl __scrt_common_main_seh(void)" (?__scrt_common_main_seh@@YAHXZ)
tada.exe : fatal error LNK1120: 1 unresolved externals
```

What's happening here is that since we decided to link with
`/subsystem:windows` instead of the default mode (`/subsystem:console`), the
linker is now expecting our `main` function to be called `WinMain`. Now we
[could](https://docs.microsoft.com/en-us/windows/win32/learnwin32/winmain--the-application-entry-point)
change our `main` function to `WinMain` with the correct parameters, but what
if we want to keep things simple, especially since we won't be using any of
those parameters. The answer lies in the `/entry` linker flag. Despite our
program seemingly having a `main` entry function, the true entry point to
console programs is a hidden function known as `mainCRTStartup` which calls
`main`. In the case of non-console applications, the entry function is
`WinMainCRTStartup` which calls `WinMain`. To get back the old behavior while
still hiding the console window, add `/entry:mainCRTStartup` to the linker
flags. Our current compilation command will be:

```console
cl /Fe:tada main.c winmm.lib /link /entry:mainCRTStartup /subsystem:windows
```

Now when we open `tada` by double-clicking it, we won't see an ugly console
window.

Dealing with Unicode
--------------------

Instead of only playing a single sound, it would be nice to be able to tell the
program which sound to play and fallback to a default sound if we don't. This
can be done like so:

```c
#include <windows.h>

int main(int argc, char *argv[])
{
	const char *default_sound = "C:\\Windows\\Media\\tada.wav";
	const char *sound = default_sound;
	if (argc > 1)
		sound = argv[1];
	PlaySound(sound, NULL, SND_FILENAME | SND_NODEFAULT);
	return 0;
}
```

We can test it by calling the program with a different sound:

```console
tada "C:\Windows\Media\notify.wav"
```

Now let's copy `C:\Windows\Media\notify.wav` to the same place as `tada` and
rename it to something like `صوت.wav`. If you try to run `tada صوت.wav`, you're
probably not going to hear anything. This is because our program, as of now,
does not support Unicode. To support Unicode we have to do a couple of changes:

```c
#include <tchar.h>
#include <windows.h>

int _tmain(int argc, _TCHAR *argv[])
{
	const _TCHAR *default_sound = _T("C:\\Windows\\Media\\tada.wav");
	const _TCHAR *sound = default_sound;
	if (argc > 1)
		sound = argv[1];
	PlaySound(sound, NULL, SND_FILENAME | SND_NODEFAULT);
	return 0;
}
```

We've made four changes here:

- Include `tchar.h`
- Change `main` to `_tmain`
- Change `char` to `_TCHAR`
- Wrap string literals in `_T()`

What this aims to do is to allow us to switch between 8-bit ANSI characters and
16-bit Unicode characters at will. Other programs might require [additional
changes](https://docs.microsoft.com/en-us/cpp/c-runtime-library/generic-text-mappings).
To complete the transformation, we will modify our compile command to the
following:

```console
cl /Fe:tada /D_UNICODE /DUNICODE main.c winmm.lib /link /entry:wmainCRTStartup /subsystem:windows
```

We added two preprocessor definitions - `_UNICODE` and `UNICODE`. `_UNICODE` is
used by `tchar.h` to transform `_tmain` into `wmain` instead of `main`,
`_TCHAR` into `wchar_t` instead of `char`, and `_T` into `L` instead of a
no-op. `UNICODE` transforms all Windows API functions (in this case
`PlaySound`) into their Unicode variants (`PlaySoundW`) instead of the default
ANSI variant (`PlaySoundA`).

We also changed the `/entry` flag from `mainCRTStartup` to its Unicode sibling
`wmainCRTStartup`.

Unicode on Windows 10 - UTF-8 edition
-------------------------------------

If you've already written a program that uses `char *` everywhere, changing it
to support Unicode can be a lot of work. Luckily, in recent versions of Windows
10, there's a new beta option that extends the ANSI functions with UTF-8
support, since ANSI is a subset of UTF-8 encoding. To enable it, go to the
[language settings](ms-settings:regionlanguage), click *Administrative language
settings*, then *Change system locale...* and tick the *Beta: Use Unicode UTF-8
for worldwide language support* option. Once you restart your computer, change
the program back to the `char *` version then compile and run it with the same
test file. I recommend you use the new [Windows
Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701) for
this. If all goes well, you'll be experiencing the full fruits of Unicode
without any extra effort!

Note: If you use [CMake](https://cmake.org/), you'll need a version > 3.16.4
when [using this setting](https://gitlab.kitware.com/cmake/cmake/issues/20320).
The vcpkg section below will require CMake (Visual Studio includes CMake, but
the version may be outdated - make sure the new version is added to your path).

Using a Makefile
----------------

Now that we have our program up and running with full Unicode support, we'd
like to automate the build so it's as simple as running `make`. Well, as simple
as running `nmake`, the Windows flavor of it. The first thing we'll need to do
is create a new file named `Makefile`. This file will contain our desired
output (`tada.exe`), our input files (`main.c` and `winmm.lib`) and a recipe
for how to generate the former from the latter (using `cl.exe`). We'll be using
the `tchar` version of our program. This is how it looks:

```makefile
tada.exe: main.c
	cl /Fe:tada /D_UNICODE /DUNICODE main.c winmm.lib /link /entry:wmainCRTStartup /subsystem:windows
```

Now, simply run `nmake`. You might get a message that `tada.exe` is up-to-date
as `nmake` is smart enough to realize that there haven't been any edits to
`main.c` since we compiled it. You can force the program to build by running
`nmake /a`. You can make the Makefile a little neater by using a backslash for
line continuation:

```makefile
tada.exe: main.c
	cl /Fe:tada /D_UNICODE /DUNICODE main.c winmm.lib /link \
		/entry:wmainCRTStartup /subsystem:windows
```

Also, make sure the file is indented with tabs and not spaces.

A cross-platform program
------------------------

We can modify our program to compile on non-Windows platforms by adjusting it
slightly. Instead of playing a sound, the program will only print a message on
those platforms. The new program looks like this:

```c
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#endif

int main(int argc, char *argv[])
{
#ifdef _WIN32
	const char *default_sound = "C:\\Windows\\Media\\tada.wav";
	const char *sound = default_sound;
	if (argc > 1)
		sound = argv[1];
	PlaySound(sound, NULL, SND_FILENAME | SND_NODEFAULT);
#endif
	puts("Tada!");
	return 0;
}
```

The `_WIN32` macro can be used to detect if a program is being compiled on
Windows. Ideally, you'd replace any use of the Windows API with a corresponding
API on other platforms by checking similar platform-specific macros.

A cross-platform Makefile
-------------------------

We can also create a cross-platform Makefile for our cross-platform program.
This is done by creating an additional Windows-specific makefile called
`tools.ini` that will be automatically read by `nmake`:

```makefile
[NMAKE]
EXEEXT=.exe

LIBS=winmm.lib
LINKFLAGS=/entry:mainCRTStartup /subsystem:windows

!if [set _CL_=/link $(LINKFLAGS)]
!endif
```

And the main Makefile:

```makefile
tada$(EXEEXT): main.c
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) main.c $(LIBS)
```

The `_CL_` environment variable allows appending options to the compiler, `cl`.
Using the `!if` directive and the `set` command, this can be done in
`tools.ini` for Windows-specific options. To prepend options, the `CL`
environment variable can be used.

`$@` in the rule refers to the output, in this case `tada$(EXEEXT)`.

If you have WSL installed, try using `nmake && tada` in Windows and then `make
&& ./tada` in WSL - both should work just fine. For more complex builds, using
the same Makefile with `make` and `nmake` might require [additional
tweaks](https://stackoverflow.com/questions/8270391/use-the-same-makefile-for-make-linux-and-nmake-windows).

To compile in release mode on Windows, do `nmake CPPFLAGS=/DNDEBUG CFLAGS="/O2
/GL"`. The `NDEBUG` macro turns off asserts, `/O2` enables optimization and
`/GL` enables whole program optimization which includes link-time optimization.

Adding third-party libraries
----------------------------

### Getting vcpkg

To use third-party libraries, we can use vcpkg. You'll need to have
[git](https://git-scm.com/) installed for this.

Run the following to install vcpkg in your preferred directory (the home
directory is a good choice):

```shell
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg
```

Once it's done, run `echo %cd% | clip` in the same directory to copy the path
of vcpkg. Set the `VCPKG_ROOT` environment variable to the copied value. Then,
set the `VCPKG_DEFAULT_TRIPLET` environment variable to `x64-windows`. This
will ensure that vcpkg downloads 64-bit libraries by default. Add
`%VCPKG_ROOT%` to your `PATH` - this will give us access to the vcpkg tool.

Next, add the include directory of vcpkg to the `INCLUDE` environment variable
&mdash; this will be `%VCPKG_ROOT%\installed\%VCPKG_DEFAULT_TRIPLET%\include`.
Make sure to separate it from existing entries by using a semicolon. Do the
same for the lib directory, adding it to the `LIB` environment variable &mdash;
`%VCPKG_ROOT%\installed\%VCPKG_DEFAULT_TRIPLET%\lib`. This will allow the
compiler to find the header and library files.

Close any terminal windows you have open for the changes to take effect, and
open a new one.

### Installing a library

In our example, we're going to be using the popular SDL2 library. We'll need to
install it and copy the required DLLs over. To do so, run the following:

```
vcpkg install sdl2
vcpkg export sdl2 --raw --output=export
copy "%VCPKG_ROOT%\export\installed\%VCPKG_DEFAULT_TRIPLET%\bin\*.dll" .
```

Now we're finally ready to use the library in our program. Instead of calling
the Windows-specific `PlaySound`, we're going to use SDL2's WAV playing
capabilities. Modify the `main.c` file to the following:

```c
#include <stdio.h>

#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>

int main(int argc, char *argv[])
{
	SDL_SetMainReady();
	const char *sound = NULL;
#ifdef _WIN32
	sound = "C:\\Windows\\Media\\tada.wav";
#endif
	if (argc > 1)
		sound = argv[1];
	if (sound) {
		puts("Tada!");
		/* Make sure to check for errors in a real program */
		SDL_Init(SDL_INIT_AUDIO);
		SDL_AudioSpec spec;
		Uint8 *buffer;
		Uint32 length;
		SDL_LoadWAV(sound, &spec, &buffer, &length);
		SDL_AudioDeviceID id =
			SDL_OpenAudioDevice(NULL, 0, &spec, NULL, 0);
		SDL_QueueAudio(id, buffer, length);
		SDL_PauseAudioDevice(id, 0);
		while (SDL_GetQueuedAudioSize(id))
			;
		SDL_CloseAudioDevice(id);
		SDL_FreeWAV(buffer);
		SDL_Quit();
	}
	return 0;
}
```

Then, modify the `Makefile` to this:

```makefile
# POSIX \
!if 0
LIBS=-lSDL2
# \
!endif

tada$(EXEEXT): main.c
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) main.c $(LIBS)
```

This adds the SDL2 library for POSIX/UNIX machines. Traditional `make` will
read the `!if` and `!endif` lines (which are `nmake`-specific directives) as a
continuation of the comments above them due to the backslash, thereby ignoring
them. However, `nmake` does not recognize the backslash as a line-continuation
character for comments and will therefore process the directives, effectively
ignoring the body of the `!if` directive. This way, `LIBS` is set to `-lSDL2`
only on UNIX machines.

We'll handle the SDL2 dependency for Windows in `tools.ini`. Modify it to the
following, adding `SDL2.lib` to `LIBS`:

```makefile
[NMAKE]
EXEEXT=.exe

LIBS=SDL2.lib
LINKFLAGS=/entry:mainCRTStartup /subsystem:windows

!if [set _CL_=/link $(LINKFLAGS)]
!endif
```

Now, run `nmake` and then `tada` - you should hear the tada sound! You can
build and run the same code on a UNIX machine (you can build it in WSL too, but
sound won't work when you run the program).
