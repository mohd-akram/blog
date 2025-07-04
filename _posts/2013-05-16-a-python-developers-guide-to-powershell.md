---
title: A Python Developer's Guide to Powershell
description: An introduction to PowerShell for Python developers.
---

Introduction
------------

Python is a great scripting language - it's available by default on Linux and
Mac and so it's easy to quickly write a short script that runs on many systems.
However, this isn't the case on Windows. You need to install Python or wrap
your application to distribute it. Sometimes this is inconvenient, especially
if you want to do something simple or deal directly with Windows specific
functions, so we need an alternative. This is where PowerShell comes in.

Getting started
---------------

PowerShell is a very powerful scripting language and is cmd.exe's successor. It
also comes with a capable IDE which you can use for this tutorial. Find
*Windows PowerShell ISE* in the Start menu or open *Windows PowerShell* and
type the `ise` command to start it. Now let's write our first program.

In Python, this is how you'd write a "hello world" program:

```python
print("hello, world")
```

It's even easier in PowerShell:

```powershell
"hello, world"
```

PowerShell automatically outputs any values to the screen without any command.
That's kind of cheating, so here's the explicit way to do it:

```powershell
Write-Host "hello, world"
```

The names of PowerShell *cmdlets* are very consistent. They follow what
[Microsoft calls](https://docs.microsoft.com/en-us/powershell/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
a verb-noun pair convention.

Variables
---------

Variables are defined by prepending a dollar sign to the variable name.

```powershell
$a = 5
$b = 6
```

You can also do Python style variable swapping:

```powershell
$a, $b = $b, $a

Write-Host a=$a, b=$b
Write-Host ($a + $b)
```

Without parentheses, the second `Write-Host` command would produce `5 + 6`
instead of `11`.

PowerShell supports fixed-size arrays:

```powershell
$array = 2, "cheese", 6.5, "cake"

# Explicit syntax
$array = @(5, "ice", 3.14, "cream")

# Inclusive range
$array = (1..10)
```

And dictionaries:

```powershell
$table = @{"a" = "apple"; "b" = "ball"}
$table["a"] = "acorn"

# Loop through keys
foreach ($key in $table.Keys) {
    Write-Host $key
}

# Loop through values
foreach ($value in $table.Values) {
    Write-Host $value
}

# Loop through items
foreach ($item in $table.GetEnumerator()) {
    Write-Host $item.Key $item.Value
}
```

Loops
-----

What if we wanted to print the numbers from 1 to 10. In Python, it would look
like this:

```python
for i in range(1, 11):
    print(i)
```

Similarly, in PowerShell:

```powershell
foreach ($i in 1..10) {
    Write-Host $i
}
```

Or, to avoid creating a range array:

```powershell
for ($i=1; $i -le 10; $i++) {
    Write-Host $i
}
```

You could just as easily use a while loop:

```powershell
$i = 1
while ($i -le 10) {
    Write-Host $i
    # Increment i
    $i++
}
```

Another interesting loop method is do...until:

```powershell
$i = 0
do {
    $i++
    Write-Host $i
} until ($i -eq 10)
```

Conditions
----------

Conditions look slightly different in PowerShell:

```powershell
# Equal to
$true -eq $false # False
# Not equal to
$true -ne $false # True

# Less than
5 -lt 10 # True
# Greater than
5 -gt 10 # False

# Less than or equal to
5 -le 10 # True
# Greater than or equal to
5 -ge 10 # False
```

PowerShell supports the same logical operators as Python including `-and`,
`-or`, and `-not`.

```powershell
# Logical operators
$happy = $true
$knowit = $true

if ($happy -and $knowit) {
    "Clap hands!"
} elseif ($happy) {
    "Yay!"
} else {
    "No!"
}
```

Functions
---------

A typical Fibonacci function in Python looks like this:

```python
def fib(n):
    if n < 2:
        return n
    return fib(n - 2) + fib(n - 1)
```

To define a function in PowerShell, use the `Function` keyword:

```powershell
Function Fib($N) {
    if ($N -lt 2) {
        return $N
    }
    return (Fib ($N - 2)) + (Fib ($N - 1))
}
```

Again, the parentheses around the `Fib` calls are important to properly return
a value.

List comprehensions
-------------------

To get a list of all the multiples of 2 from 1 to 20, you'd do this in Python:

```python
multiples = [i for i in range(1, 21) if i % 2 == 0]
```

PowerShell:

```powershell
$multiples = 1..20 | Where-Object { $_ % 2 -eq 0 }
```

The list comprehensions are somewhat different than in Python and make use of
piping, which is a very powerful tool in PowerShell. In this case, a range from
1 to 20 is piped to the `Where-Object` command which filters the list of items
according to the condition `$_ % 2 -eq 0`. The `$_` variable essentially refers
to each item in a list of objects.

To do an operation on each multiple of two, say find its square, we pipe the
multiples to the `ForEach-Object`:

```powershell
$squares = $multiples | ForEach-Object { $_ * $_ }
```

You can also do it all on one line:

```powershell
$squares = 1..20 | ? { $_ % 2 -eq 0 } | % { $_ * $_ }
```

The `?` is an alias for `Where-Object` and `%` is an alias for `ForEach-Object`.

Example program
---------------

I've written a short program in both Python and PowerShell that downloads a
bunch of xkcd comics to a "xkcd" folder on the Desktop.

Python:

```python
import os
from urllib.request import urlopen
from html.parser import HTMLParser


# Parse xkcd page
class Parser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.is_comic = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        # If found 'comic' div, then next img has comic link
        if tag == 'div' and 'id' in attrs:
            if attrs['id'] == 'comic':
                self.is_comic = True

        # Set self.url to comic image url
        elif tag == 'img' and self.is_comic:
            self.url = attrs['src']
            self.is_comic = False


def get_xkcd(n=''):
    # Path to xkcd folder on Desktop
    folder = os.path.join(os.path.expanduser('~'), 'Desktop/xkcd')

    # If folder doesn't exist, create one
    if not os.path.exists(folder):
        os.makedirs(folder)

    # Download comic page
    url = 'https://xkcd.com/{}'.format(n)
    page = urlopen(url).read().decode('utf-8')

    # Get image url from parser
    parser = Parser()
    parser.feed(page)

    image_name = parser.url.split('/')[-1]
    path = os.path.join(folder, image_name)

    with open(path, 'wb') as f:
        f.write(urlopen(parser.url).read())

# Get a bunch of comics
for i in range(1200, 1212):
    get_xkcd(i)
    print('Downloaded xkcd #{}'.format(i))
```

PowerShell:

```powershell
# Function to download xkcd comic. Get latest one if no $n is provided
Function GetXkcd($n='') {
    # Path to xkcd folder on Desktop.
    # [Environment] is a .NET class with static method GetFolderPath.
    # Trailing backtick for line continuation.
    $folder = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) `
                        -ChildPath 'xkcd'

    # If folder doesn't exist, create one
    if (-not (Test-Path -Path $folder)) {
        New-Item $folder -Type Directory
    }

    # Initiate web request (requires PowerShell 3). See Notes.
    # Uses -f to format string to replace {0} by comic number
    $result = Invoke-WebRequest ("https://xkcd.com/{0}" -f $n)

    # Get URL of image that is a comic
    $url = ($result.Images | where src -match /comics/).src

    # Join folder path with image file name
    $destination = Join-Path -Path $folder `
                             -ChildPath ((Split-Path -Leaf $url))

    # Download image
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $destination)
}

# Get a bunch of comics
foreach ($i in 1200..1211) {
    GetXkcd $i
    "Downloaded xkcd #{0}" -f $i
}
```

Notes
-----
You might have to change your PowerShell
[execution policy](https://technet.microsoft.com/en-us/library/ee176961.aspx)
to run scripts. To do this, run PowerShell as Administrator and type
`Set-ExecutionPolicy RemoteSigned`.

A great way to learn about PowerShell is to use the `Get-Help` cmdlet. Simply
type `Get-Help` followed by any other cmdlet to get more information about it.
You can update your help files to be more comprehensive by running
`Update-Help` as an administrator (PowerShell 3).

You can use
[IE to parse HTML](https://dmitrysotnikov.wordpress.com/2012/08/06/new-in-powershell-3-parse-html-without-ie-object-unless-a-local-file/)
instead of `Invoke-WebRequest` if you don't have PowerShell 3.

Conclusions
-----------

This is just scratching the surface of PowerShell by covering the syntax
basics. The real power of PowerShell comes from piping and the various types of
cmdlets that come built in to the language, similar to the Python standard
library. You also get a nice IDE to boot - and it's already on your Windows
machine.
