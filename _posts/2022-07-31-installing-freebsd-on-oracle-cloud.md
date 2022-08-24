---
title: Installing FreeBSD on Oracle Cloud
description: A short guide to installing FreeBSD on Oracle Cloud.
---

Oracle Cloud has a fairly generous [free
tier](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm), but
one thing it does not include is the ability to use [custom
images](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingcustomimages.htm),
which require a paid account. This guide will show you how to install FreeBSD
(or any custom image) using an alternative method.

*Note: For arm64 instances, a FreeBSD image is currently available under the
partner images source when creating the instance, so you can skip the steps
below unless you need a specific version.*

Install
-------

1. [Create two
instances](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/launchinginstance.htm)
in Oracle Cloud using the default image. We will be using one for the FreeBSD
server, and a temporary one for the installation process. Make sure to specify
your SSH public key when creating the temporary instance.

2. On the FreeBSD instance page, stop it if it is running, and [detach the boot
volume](https://docs.oracle.com/en-us/iaas/Content/Block/Tasks/detachingabootvolume.htm).

3. On the temporary instance page, attach the FreeBSD instance's boot volume as
a block volume. Make sure to select *Paravirtualized* as the attachment type.

4. SSH into the temporary instance. Check the path of the newly attach volume.
You can do this by running `lsblk` and seeing which one has nothing mounted on
it (it will most likely be `/dev/sdb`).

   Then, run the following command to install a raw FreeBSD image onto the volume.
Modify the release version and the volume path as needed.

   ```shell
   curl https://download.freebsd.org/ftp/releases/VM-IMAGES/13.1-RELEASE/amd64/Latest/FreeBSD-13.1-RELEASE-amd64.raw.xz | xz -dc | sudo dd of=/dev/sdb bs=1M conv=fdatasync
   ```

5. Once the process is complete, detach the block volume from the temporary
instance.

6. Re-attach the FreeBSD instance's boot volume and start the instance.

Setup
-----

Once the FreeBSD instance has booted, we can now configure it.

1. In the instance's page, launch a Cloud Shell connection (you may need to
press Enter in the console if it appears to be stuck for a while). This will
give us preliminary access and allow us to enable SSH on the new server.

2. Run `passwd` to set a password for the `root` user - make sure to choose a
strong one.

3. Create a new user using `adduser`. When asked to invite the user to other
groups, enter `wheel` to give the user root privileges.

4. Enable and start the SSH service by running `service sshd enable`, followed
by `service sshd start`.

5. Copy your public key from your local machine using `ssh-copy-id
user@freebsd-instance-ip`.

6. Now you can SSH into your new FreeBSD server and do any additional setup.
Enjoy!

Additional Setup
----------------

### IPv6

To get IPv6 working on a FreeBSD instance on Oracle Cloud, we need support for
DHCPv6, which is not yet available in FreeBSD's DHCP client `dhclient`. To get
around this, we can use the `dual-dhclient-daemon` package which supports
dual-stack DHCP. You can install and enable it with the following:

```shell
pkg install dual-dhclient-daemon
sysrc dhclient_program=/usr/local/sbin/dual-dhclient
```

You will also need to [enable
IPv6](https://www.51sec.org/2021/09/20/enable-ipv6-on-oracle-cloud-infrastructure/)
for your instance in the Oracle Cloud settings.
