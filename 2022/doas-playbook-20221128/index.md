---
canonical_url: https://grencez.dev/2022/doas-playbook-20221128
date: 2022-11-28
last_modified_at: 2022-11-28
description: A quick way to run commands as a different user.
---

# Using the doas command to run as a different user

Date: 2022-11-28

## Command Reference
```shell
export main_user=grencez
export delegate_user=grencez-for-games
export command="echo hello world"
```

### Create User
```shell
sudo -E su
useradd -g $(id -g -n "${main_user}") --shell /bin/false "${delegate_user}"
printf "permit nopass %s as %s\n" "${main_user}" "${delegate_user}" >>"/etc/doas.conf"
exit
```

### Run
```shell
doas -u ${delegate_user} $command
```

