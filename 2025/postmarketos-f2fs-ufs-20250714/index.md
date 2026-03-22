---
canonical_url: https://grencez.dev/2025/postmarketos-f2fs-ufs-20250714
date: 2025-07-14
last_modified_at: 2026-03-22
description: How to install PostmarketOS on a Minisforum S100.
---

# Installing PostmarketOS on a Minisforum S100
Date: 2025-07-14

Update: 2026-03-22 -- Added the post-install mkinitfs step.

## Brief
In this article, we install PostmarketOS on a Minisforum S100 with the following high-level procedure:
- Build PostmarketOS in a way that loads custom kernel modules at boot time.
- Create a LiveUSB and boot the target machine from it.
- Overwrite the target machine's internal storage over SSH.

These instructions should mostly work for any x86-64 target machine.
Just omit or customize the `--sector-size=4096` flag when building a disk image.

## Hardware
The Minisforum S100 is a mini desktop computer with a quad-core Intel N100 processor 8 GB of RAM.
At launch, many people tried to install their favorite flavors of Linux on the S100, but only a few distributions like Proxmox actually booted from internal storage.
The issues revolve around 3 oddities of its internal storage:
- **Universal Flash Storage (UFS).**
  Not many Linux distributions expect to boot an x86-64 machine from UFS, so they don't install modules to support it at boot time.
- **4096-byte sector size.**
  The Linux default is 512, which means that a naive `dd` from a disk image will have a bad partition table.
- **Unified Extensible Firmware Interface (UEFI).**
  The EFI System Partition should be FAT32, which requires at least 65525 sectors to be designated as FAT32 clusters.
  The S100's firmware is picky about this, so the partition needs more than 65525 sectors (or 256 MiB or 269 MB).
  I use 512 MB in this article, but you could probably trim that to 300 MB.

Due to reports of short lifespans of the internal storage, I'm also opting to format the root partition with the Flash-Friendly File System (F2FS).
Granted, the main issue is that the S100 overheats when relying on Power over Ethernet rather than its USB-C adapter.

## Build PostmarketOS

### Install dependencies
We'll be cloning a fresh version of `pmbootstrap` with `git`, so we need to install dependencies manually.
See [the full requirements list](https://gitlab.postmarketos.org/postmarketOS/pmbootstrap#requirements) for details.
Chances are, you have most of them installed already.
I only needed `multipath-tools`:
```shell
# For `kpartx`.
sudo apt install multipath-tools
```

### Create build user
If you have `doas` installed, the `pmbootstrap` command will use that to act as `root`.
Rather than giving your normal user ambient root access, it's easiest to do this whole process as a different user.
```shell
sudo sh
useradd --create-home -g users root-delegate || busybox adduser -D -G users root-delegate
echo "permit nopass root-delegate as root" >>/etc/doas.conf
su root-delegate
```

### Parameters
The instructions assume you're running as the correct user and have the following environment variables set.
```shell
top_dir="${HOME}/Desktop/pmos"
pmbootstrap_device=generic-x86_64

alias pmbootstrap="${top_dir}/pmbootstrap/pmbootstrap.py --config '${top_dir}/pmbootstrap.cfg'"
# Put `losetup` in `${PATH}` if it isn't already.
export PATH="${PATH}:/usr/sbin"
```

### Initialize configuration
```shell
mkdir -p "${top_dir}/work" "${top_dir}/export"
cd "${top_dir}"
git clone --single-branch https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git

cat >"${top_dir}/pmbootstrap.cfg" <<HEREDOC
[pmbootstrap]
work = ${top_dir}/work
aports = ${top_dir}/pmaports
boot_size = 512
device = ${pmbootstrap_device}
hostname = pmos
systemd = never
user = root-delegate
build_pkgs_on_install = False
HEREDOC

pmbootstrap init
```

The last command has some prompts.
You can accept all the preselected values.
Feel free to change the hostname and other values that we customized below it.

### Customize pmbootstrap device
```shell
cat >>"${top_dir}/pmaports/device/community/device-${pmbootstrap_device}/modules-initfs" <<HEREDOC
f2fs
ufshcd
ufshcd_pci
HEREDOC

pmbootstrap checksum "device-${pmbootstrap_device}"
pmbootstrap build --force "device-${pmbootstrap_device}"
```

### Flash a LiveUSB
```shell
# Replace ${usb_devpath} with the device path of the flash drive that you want to overwrite (e.g., `/dev/sdb`).
# Remember, this erases the disk, so inspect the output of `lsblk` to verify your choice.
pmbootstrap install --filesystem=f2fs --disk "${usb_devpath}"
```

You'll be prompted for a password for the new user.

When it's done flashing, you can try booting to it.

### Build disk image
```shell
# We have to build from scratch to apply the sector size change.
pmbootstrap zap
pmbootstrap install --filesystem=f2fs --sector-size=4096
```

You'll be prompted for a password for the new user again.

```shell
pmbootstrap export "${top_dir}/export/"
pmbootstrap shutdown
```

## Install
Time to boot the LiveUSB!
You'll have to disable secure boot though.
- Power on the S100.
- Press the F7 key repeatedly.
- Enter setup.
- In the Security section, set an Administrator Password.
- In the Security section below that, disable secure boot.
- Save.

Hopefully you can boot from the LiveUSB now.
Remember to press F7 to select booting from the USB.

When it's up, SSH in and give the `root-delegate` user ambient `root` access:
```shell
ssh root-delegate@pmos
# Type password.
doas -u root -- sh
# Type password.
echo "permit nopass root-delegate as root" >/etc/doas.d/root-delegate.conf
exit
exit
```

Finally, we flash it:
```shell
ssh root-delegate@pmos -- "doas -u root -- dd of=/dev/sda bs=4M conv=fsync" <"${top_dir}/export/${pmbootstrap_device}.img"
```

PostmarketOS should load from internal storage upon reboot:
```shell
ssh root-delegate@pmos -- "doas -u root -- reboot"
```

## Post Install

Before updating any packages, add those UFS & F2FS modules that we needed earlier to `/etc/mkinitfs/modules/` so they get added to every future kernel's initramfs:
```shell
ssh root-delegate@pmos -- "doas -u root -- printf 'f2fs\nufshcd\nufshcd_pci\n' > /etc/mkinitfs/modules/10-storage.modules"
```
