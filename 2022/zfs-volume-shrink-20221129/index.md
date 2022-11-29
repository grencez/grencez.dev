---
canonical_url: https://grencez.dev/2022/zfs-volume-shrink-20221129
date: 2022-11-29
last_modified_at: 2022-11-29
description: How to shrink a ZFS volume on Proxmox.
---

# How to shrink a ZFS volume in Proxmox

Date: 2022-11-29

So you'd like to shrink the ZFS volume used as a VM disk.
It isn't too hard, but we have to shrink the VM's partition before shrinking the ZFS volume itself.
Be sure to have snapshots/backups of all volumes used by this VM.
You might screw them up!

## Command Reference
```shell
export zvol=jankenpool/e/vm-106-disk-0
export desired_GiB=64
```

### Resize the partition
Assuming this volume is a VM's disk, boot that VM with a GParted livecd.
Resize the partition there.
Make it maybe 1 MiB less than you want, just in case.

### Resize the volume
```shell
zfs set volsize=${desired_GiB}G ${zvol}

qm rescan
#^ Update Proxmox's view of reality.
```

## Example
```shell
#> Reparation in the VM first! I like using the GParted livecd.

zfs set volsize=400G jankenpool/e/vm-106-disk-0

qm rescan
```
