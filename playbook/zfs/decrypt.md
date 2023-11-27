
```shell
zfs mount -l jankenpool/e
zfs mount -l vampool/backup

swapon /dev/zvol/swapool/swapfile

# https://wiki.gentoo.org/wiki/ZFS#Adjusting_ARC_memory_usage
echo 2147483648 >>/sys/module/zfs/parameters/zfs_arc_max
```
