
```shell
zfs list -t snapshot ${zvol}
#^ List snapshots.

date -u +%F_%T -d "15 minutes ago"
#^ Get UTC time before messing up.

zfs rollback -r ${zvol}@${snapshot}
#^ Perform rollback. Destroy newer snapshots.
```

### EXAMPLE

```shell
zfs list -t snapshot jankenpool/e/vm-104-disk-0

date -u +%F_%T -d "10:00 PDT"

zfs rollback -r jankenpool/e/vm-104-disk-0@autosnap_2022-07-21_17:00:02_hourly

qm rescan  # Due to volsize change!
```
