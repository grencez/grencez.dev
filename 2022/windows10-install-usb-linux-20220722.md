---
canonical_url: https://grencez.dev/2022/windows10-install-usb-linux-20220722
date: 2022-07-22
description: Linux commands that create a bootable USB from Windows 10 ISO.
last_modified_at: 2022-07-23
---

# Creating a Windows 10 install USB in Linux

Date: 2022-07-22

Before watching [Philip Yip's video](https://youtu.be/Y388W8MaPME), I couldn't get a bootable Windows 10 USB.
Unlike a usual Linux ISO, the Windows 10 installer ISO should not be copied directly to a USB via `dd`.
Here's a short summary of the steps involved.

First copy the Windows 10 ISO to the Desktop.
We'll be working in that folder exclusively.

Next open a terminal and set 2 variables to identify your USB device and the Windows 10 iso file:

```shell
usbdev=/dev/sdz
isofile=Win10_21H2_EnglishInternational_x64.iso

cd ~/Desktop
# Sanity check.
test -f "${isofile}" && echo 'OKAY so far' || echo "ERROR ${isofile} does not exist!" >&2
```

Next we'll be running GParted on the USB device to reformat.
Either do that in a GUI or run it from terminal as:

```shell
sudo gparted "${usbdev}"
```

In GParted, we'll reformat the drive.
As always, this **will delete all data** on the device, so you better be sure it's your USB!
When you are mentally prepared for the consequences, perform these 3 operations in GParted:
1. Reformat.
2. Make first partition 1024 MiB. Fat32. Name it BOOT.
3. Make second partition the rest. NTFS. Name it INSTALL.

Finally, mount the ISO and partitions and copy files:

```shell
mkdir isomnt bootmnt installmnt
sudo mount "${isofile}" mountiso -o loop
sudo mount "${usbdev}1" bootmnt
sudo mount "${usbdev}2" installmnt

# Copy everything but the sources/ folder to BOOT.
sudo rsync -r --exclude /sources/ isomnt/ bootmnt/
# Copy sources/boot.wim over too.
sudo rsync -r  --include /sources/ --include /sources/boot.wim --exclude '*' isomnt/ bootmnt/

# Copy everything to INSTALL. I didn't need root here.
rsync -r isomnt/ installmnt/ --progress

sudo umount isomnt bootmnt installmnt
rmdir isomnt bootmnt installmnt
```
