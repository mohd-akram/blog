---
title: Fix WSL File System Behavior
description: >
  Learn to fix WSL's default file/directory permissions and case-sensitivity
  setting to work correctly with UNIX tools.
---

WSL's default file system options are not the best when working with UNIX
tools. To fix them, do the following:

1. Add the following to `/etc/wsl.conf` in your WSL distribution:

   ```ini
   [automount]
   options="metadata,case=dir,umask=22,fmask=111"
   ```

2. Check your umask setting by running `umask` in WSL. If it's `0000`, you'll
   need to add `umask 022` to `~/.profile`. This can be done by running `echo
   "umask 022" >> ~/.profile` to add it to the end of the file.

3. Close all instances of WSL then run `wsl -t distribution_name` replacing
   `distribution_name` with the name of your distribution. To get a list of
   them, run `wsl -l`.

---

The `automount` options in `/etc/wsl.conf` specify the mount options for DrvFs
which allows accessing Windows files from WSL. These changes do the following:

- `chmod` and `chown` don't work with Windows partitions (eg. `/mnt/c`) by
  default in WSL. Adding the `metadata` option fixes this.

- Files in DrvFs are not case-sensitive by default (`case=off`). Adding
  `case=dir` causes any new directory created in WSL and all its contents to be
  case-sensitive. This is important for programs like Git which will not detect
  case-sensitive renames properly without this option.

- By default, all files and directories in DrvFs have 777 permissions. That is,
  they are readable, writable, and executable by everyone. Adding the
  `umask=22` (same as 022) option masks (turns off) the write permission (i.e.
  the second bit which is equal to 2) for everyone but the owner, making all
  files and directories have 755 permissions. Adding `fmask=111` further masks
  those permissions for files specifically, turning off the execute bit (i.e.
  the first bit) for everyone, bringing file permissions down to 644. Having
  the correct permissions is also important for Git which will commit files
  with an executable bit as such.

While the automount options will affect files in DrvFs, they have no effect on
files created in the regular filesystem. There, the default permissions are 777
for directories and 666 for files. These are then modified by a system umask.
In current versions of Windows 10, the system umask is [not
applied](https://github.com/microsoft/WSL/issues/352) resulting in a umask of
0, giving everyone write permissions. Setting a umask of 022 in the shell's
`~/.profile` fixes this.
