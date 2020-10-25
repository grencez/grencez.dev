---
canonical_url: https://grencez.dev/2020/backup-20201018
date: 2020-10-18
description: How to make simple encrypted backups in Linux with cryptsetup and rsync.
---

# Encrypted backups of a Linux system with cryptsetup and rsync

Date: 2020-10-18

Script: [backup.sh](backup.sh), which can also be found at https://github.com/grencez/s/blob/trunk/backup.sh

## Intro

It's very important to back up data, and yet I haven't done it in a while.
My plan is to create an encrypted partition and just `rsync` everything to it.
I took this approach before and successfully recovered from it after doing something akin to `rm -fr /`.

## Create the partition

I ran `fdisk`:

```shell
sudo fdisk /dev/sdb
```

It has a menu that takes letter commands. I did the following:

1. `g` to create GPT partition table. Skip this if the disk already has partitions on it.
1. `n` to create new partition.
  1. `1` (default) is the partition number.
  1. `2048` (default) is the first sector.
  1. `+460G` to allocate 460 GiB for the partition.
1. `w` to write it.

### Encrypt the partition

```shell
sudo cryptsetup -q --cipher aes-xts-plain64 --key-size 512 --label backup-trinidad luksFormat /dev/sdb1
```

### Format the partition

```shell
sudo cryptsetup luksOpen /dev/sdb1 backupdev
sudo mkfs.ext4 /dev/mapper/backupdev
sudo cryptsetup luksClose backupdev
```

## RSync

The actual copying is done with `rsync -a --delete /path/to/mounted/root/ /path/to/mounted/backup/`.
I use a `/path/to/mounted/root/` instead of just `/` to avoid copying `/dev/` and `/proc/`.

The steps to mount everything are somewhat tedious, so I wrap them in a [backup.sh](backup.sh) script that just needs to be told what the backup device is:

```shell
sudo sh ~/s/backup.sh /dev/sdb1
```

It decrypts `/dev/sdb1`, mounts it as `/root/backmnt/`, mounts the root directory (and the `/boot/` partition) in `/dev/rootmnt/`, then backs up the data.
It actually backs up to a directory called `trinidad` (this computer's hostname) to avoid conflicts with other backups (if there were others).
Explicitly, the commands it runs (as root) are:

```shell
mkdir -p /root/backmnt /root/rootmnt
cryptsetup luksOpen /dev/sdb1 backupimage
mount /dev/mapper/backupimage /root/backmnt
mount /dev/sda3 /root/rootmnt
mount /dev/sda1 /root/rootmnt/boot
mkdir -p /root/backmnt/trinidad
rsync -a --delete /root/rootmnt/ /root/backmnt/trinidad/
umount /root/rootmnt/boot /root/rootmnt /root/backmnt
cryptsetup luksClose backupimage
rmdir /root/rootmnt /root/backmnt
```

