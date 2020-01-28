---
title: Editing Configuration Files Programmatically
description: Using ex to edit configuration files programmatically.
---

Introduction
------------

`ex` is a very powerful tool for editing configuration files. Its syntax
consists of a string of commands delimited by newlines or `|`. The `x` command
saves the file and quits ex. To avoid mistakes, first examine your changes by
replacing the `x` with `%p` and comparing `ex`'s output with the original file:

```shell
echo $commands | ex $file | diff -u $file -
```

Note: The shell variables used throughout this post are for illustration
purposes only and should be replaced with actual values as shown in the
examples. It's advisable to use a configuration utility where possible and
resort to `ex` only when necessary.

Recipes
-------

### Comment a line

Form:

```shell
echo "/$pattern/s/^/#/ | x" | ex $file
```

Example:

```shell
echo '/^PermitRootLogin yes/s/^/#/ | x' | ex /etc/ssh/sshd_config
```

### Uncomment a line

Form:

```shell
echo "/$pattern/s/^#// | x" | ex $file
```

Example:

```shell
echo '/^#net.ipv4.ip_forward=1/s/^#// | x' | ex /etc/sysctl.conf
```

### Add a new line

Form:

```shell
echo $line >> $file
```

Example:

```shell
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
```

### Change a line

Form:

```shell
echo "/$pattern/c
$replacement
.
x" | ex $file
```

Example:

```shell
echo '/^DNS1=/c
DNS1=1.1.1.1
.
x' | ex /etc/sysconfig/network-scripts/ifcfg-eth0
```

### Add a line after an existing one

Form:

```shell
echo "/$pattern/a
$replacement
.
x" | ex $file
```

Example:

```shell
echo '/^DNS1=/a
DNS2=1.0.0.1
.
x' | ex /etc/sysconfig/network-scripts/ifcfg-eth0
```

Use the `i` command instead of `a` to add a line before an existing one.

### Multiple edits

Form:

```shell
echo "
$command_1
$command_n
x" | ex $file
```

Example:

```shell
echo '
/^#net.ipv4.ip_forward=1/s/^#//
/^#net.ipv6.conf.all.forwarding=1/s/^#//
x' | ex /etc/sysctl.conf
```

### Edit a group of lines

Form:

```shell
echo "/$begin_pattern/,/$end_pattern/$command | x" | ex $file
```

Example:

```shell
# Disable Apache indexes in /var/www
echo '/<Directory \/var\/www\/>/,/<\/Directory>/s/ Indexes// | x' |
	ex /etc/apache2/apache2.conf
```

### Combining actions

Form:

```shell
echo "/$pattern/
$command_1
$command_n
x" | ex $file
```

Example:

```shell
# Change DNS1 and add DNS2 after it
echo '/^DNS1=/
c
DNS1=1.1.1.1
.
a
DNS2=1.0.0.1
.
x' | ex /etc/sysconfig/network-scripts/ifcfg-eth0
```
