---
canonical_url: https://grencez.dev/2014/gentoo-install-20140305
date: 2014-03-05
description: Steps I took to install Gentoo Linux.
---

# Installing Gentoo

Date: 2014-03-05

I've been using Gentoo Linux for a few years and have followed these notes a few times on different computers.

## Prepare the Disk

### Partition Disk

Start fdisk to work on `/dev/sda`

```shell
fdisk /dev/sda
```

Create boot partition by following:

```
new -> primary -> 1st partition
  -> start at default ->  end 256 MB later
  -> p -> 1 -> -> +256M
```

make it bootable

```
a -> 1
```

Create swap partition

```
n -> p -> 2 -> -> +512M
```

Set its type to "Linux Swap"

```
t -> 2 -> 82
```

Create root parition taking up the rest
`n -> p -> 3 -> ->`

finally, write `w`

### Format the Partitions

Boot partition as ext3

```shell
mkfs.ext3 /dev/sda1
```

Create and activate swap

```shell
mkswap /dev/sda2
swapon /dev/sda2
```

Make `sda3` an ext4 filesystem

```shell
mkfs.ext4 /dev/sda3
```

### Mount the Partitions

```shell
mount /dev/sda3 /mnt/gentoo
mkdir /mnt/gentoo/boot
mount /dev/sda1 /mnt/gentoo/boot
```

### Get Gentoo System

Boot up `links` and go to http://www.gentoo.org/main/en/mirrors.xml,
choose a mirror, and get stage3 tarball at `releases/x86/2007.0/stages/` press `d` to download

Do a checksum:

```shell
# NOTE: You'll probably want to use `sha512sum` instead.
#   Just `cat` the DIGESTS file to see what kind(s) of hashes it has.
md5sum -c stage3-i686-2007.0.tar.bz2.DIGESTS
```

Untar the tarball:

```shell
tar xvjpf stage3-*.tar.bz2 -C /mnt/gentoo
```

The options mean:

```
x - extract, v - verbose,
j - decompress with bzip2, p - preserve permissions,
f - extract a file
```

Sometimes you want to leave the verbose part out when using a slow terminal

Do the same with Portage from

```shell
snapshots/portage-latest.tar.bz2
```
but untar with the command

```shell
tar xvjf portage-latest.tar.bz2 -C /mnt/gentoo/usr
```

Choose mirrors:

```shell
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
mirrorselect -i -r -o >> /mnt/gentoo/etc/portage/make.conf
```

### Copy DNS Info

```shell
cp -p mode -L /etc/resolv.conf /mnt/gentoo/etc/
```

(the `-L` option ensures no symbolic link,
and `-p mode` ensures that the file remains readable for normal users)

### Mount /proc and /dev

```shell
mount -t proc none /mnt/gentoo/proc
mount -o bind /dev /mnt/gentoo/dev
```

## Configure the System

### Chroot into Gentoo

change root from `/` to `/mnt/gentoo`

```shell
chroot /mnt/gentoo /bin/bash
```

create new environment (variables)

```shell
env-update
```

load environment variables

```shell
source /etc/profile
export PS1="(chroot) $PS1"
```

### Update Portage Tree

to the latest version

```shell
emerge --sync
```

for slow console...

```shell
emerge --sync --quiet
```

### Kernel Setup

get kernel

```shell
emerge -q gentoo-sources
```

and make it (with -s for silent)

```shell
cd /usr/src/linux
make menuconfig
make -s && make -s modules_install
```

copy kernel image to /boot

```shell
cp arch/x86_64/boot/bzImage /boot/kernel-3.13.5
```

Use whatever kernel version is appropriate in the name.

### Specify Modules to Autoload

List modules for autoloading in `/etc/modules.autoload.d/kernel-2.6`
to view all available:

```shell
find /lib/modules/<kernel version>/ \
  -type f -iname '*.o' -or -iname '*.ko'
```

### Create fstab

Syntax: `<partition> <mount point> <filesystem> <mount options> <needs dump> <fsk>`

This example's options:

```shell
/dev/sda1    /boot       ext3 defaults,noatime 1 2
/dev/sda2    none        swap sw 0 0
/dev/sda3    /           ext4 noatime 0 1
/dev/cdrom   /mnt/cdrom  auto noauto,usr 0 0
```

### Configure the Network

Name your computer by putting the following line in `/etc/conf.d/hostname`.

```
HOSTNAME="bat-masterson"
```

Define hosts that aren't resolved by the nameserver by editing `/etc/hosts`.

```
127.0.0.1       localhost       bat-masterson
::1             localhost
```

### Get PCMCIA working

```shell
emerge pcmciautils
```

### Set root password

```shell
passwd
```

System Information

```
/etc/rc.conf
```

## Install Other Stuff

### System Logger

```shell
emerge syslog-ng
rc-update add syslog-ng default
```

### Cron Daemon

Among others, you can use `dcron`, `fcron`, or `vixie-cron` for this, but I chose `vixie-cron`.

```shell
emerge vixie-cron
rc-update add vixie-cron default
```

if `dcron` or `fcron`, also do

```shell
crontab /etc/crontab
```

### File Indexing

for the locate tool

```shell
emerge mlocate
```

### File System Tools

possi-ex: xfsprogs, jfsutils

```shell
emerge xfsprogs
```

### DHCP Client

```shell
emerge dhcpcd
```

### Framebuffer

find info in `/usr/src/linux/Documentation/fb/vesafb.txt`

```shell
emerge vesafb-tng
```

### GRUB Setup

First install Grub.

```shell
emerge grub
```

Set up grub through grub-install
first setup `/etc/mtab`

```shell
grep -v rootfs /proc/mounts > /etc/mtab
```

With `/boot` still mounted, install Grub.

```shell
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

This second command should be rerun any time you install a new kernel.
It reads some settings from `/etc/default/grub`.

## Finalize the Install

### Reboot into new System

tidy up a little first

```shell
exit
cd
umount /mnt/gentoo/boot /mnt/gentoo/dev /mnt/gentoo/proc /mnt/gentoo
reboot
```

### Add User

```shell
useradd -m grencez
```

## Commands

Describe the USE flags for a specific package.

```shell
equery --nocolor uses =sys-devel/llvm-3.3-r1 -a
```
