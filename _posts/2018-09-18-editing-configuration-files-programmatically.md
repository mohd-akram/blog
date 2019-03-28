---
title: Editing Configuration Files Programmatically
description: Using sed to edit configuration files programmatically.
---

Introduction
------------

`sed` is a very powerful tool for editing configuration files. The examples
below use it extensively, including the `-i` flag for editing configuration
files in place. To avoid mistakes, first examine your changes by comparing
`sed`'s output with the original file:

```shell
sed $commands $file | diff -u $file -
```

Recipes
-------

### Comment a line

Form:

```shell
sed -i "/$pattern/s/^/#/" $file
```

Example:

```shell
sed -i '/^PermitRootLogin yes/s/^/#/' /etc/ssh/sshd_config
```

### Uncomment a line

Form:

```shell
sed -i "/$pattern/s/^#//" $file
```

Example:

```shell
sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
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
sed -i "/$pattern/c\\
$replacement
" $file
```

Example:

```shell
sed -i '/^DNS1=/c\
DNS1=1.1.1.1
' /etc/sysconfig/network-scripts/ifcfg-eth0
```

### Add a line after an existing one

Form:

```shell
sed -i "/$pattern/a\\
$replacement
" $file
```

Example:

```shell
sed -i '/^DNS1=/a\
DNS2=1.0.0.1
' /etc/sysconfig/network-scripts/ifcfg-eth0
```

### Multiple edits

Form:

```shell
sed -i "
# Optional comment describing command_1
$command_1
# Optional comment describing command_n
$command_n
" $file
```

Example:

```shell
sed -i '
# Forward IPv4 packets
/^#net.ipv4.ip_forward=1/s/^#//
# Forward IPv6 packets
/^#net.ipv6.conf.all.forwarding=1/s/^#//
' /etc/sysctl.conf
```

### Edit a group of lines

Form:

```shell
sed -i "/$begin_pattern/,/$end_pattern/$function" $file
```

Example:

```shell
# Disable Apache indexes in /var/www
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/s/ Indexes//' \
	/etc/apache2/apache2.conf
```

### Combining actions

Form:

```shell
sed -i "/$pattern/{
$function_1
$function_n
}" $file
```

Example:

```shell
# Change DNS1 and add DNS2 after it
sed -i '/^DNS1=/{
a\
DNS2=1.0.0.1
c\
DNS1=1.1.1.1
}' /etc/sysconfig/network-scripts/ifcfg-eth0
```

Tips
----

- Do `sed $commands $file > $file.new && mv $file.new $file` instead of using
  the `-i` flag for portability.

- The `-n` option can be used to output only the lines affected by the `sed`
commands instead of the entire file.

- Use the `p` function combined with `-n` to print matching lines (like
  `grep`).

- Use the `i\` function instead of `a\` to add a line before an existing one.

- If there are many forward slashes in your pattern, you can use a different
  delimiter:

```shell
# Before
sed -n '/<Directory \/var\/www\/>/p' /etc/apache2/apache2.conf

# After (using | as a delimiter)
sed -n '\|<Directory /var/www/>|p' /etc/apache2/apache2.conf
```
