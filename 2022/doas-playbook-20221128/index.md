---
canonical_url: https://grencez.dev/2022/doas-playbook-20221128
date: 2022-11-28
last_modified_at: 2022-11-28
description: A quick way to run commands as a different user.
---

# How to run programs as a different user via doas

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
printf "permit nopass %s as %s\n" "${main_user}" "${delegate_user}" >"/etc/doas.d/${delegate_user}.conf"
# If the above command failed, append to /etc/doas.conf instead:
#   printf "permit nopass %s as %s\n" "${main_user}" "${delegate_user}" >>"/etc/doas.conf"
exit
```

### Run
```shell
doas -u ${delegate_user} $command
```

