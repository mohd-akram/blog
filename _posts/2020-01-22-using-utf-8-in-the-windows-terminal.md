---
title: Using UTF-8 in the Windows Terminal
description: >
  Learn to set up your Windows 10 system and terminal to work well with UTF-8.
---

Windows is not known for its interporability with UTF-8 (and you can find
[countless](https://duckduckgo.com/?q=windows+utf-8) search results on the
matter). However, things have changed in Windows 10 and if you follow these
steps, you can have a UTF-8 workflow.

1. Get the new [Windows
   Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701).
   It has full support for Unicode and UTF-8.
2. Download the new
   [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows).
   The new version of PowerShell is UTF-8 first, and will output UTF-8 files by
   default (see the [default encoding of
   Out-File](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-7)).
3. Ensure that Windows Terminal uses `pwsh.exe` and not `powershell.exe` in the
   [Windows Powershell
   profile](https://github.com/microsoft/terminal/blob/master/doc/user-docs/UsingJsonSettings.md).
4. Enable the new UTF-8 option in Windows settings. Go to the [language
   settings](ms-settings:regionlanguage), click *Administrative language
   settings*, then *Change system locale...* and tick the *Beta: Use Unicode
   UTF-8 for worldwide language support* option.
5. Restart your computer.

If you stick to using the new Windows Terminal, everything should read, write
and display UTF-8 by default.
