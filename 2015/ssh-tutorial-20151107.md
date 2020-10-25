---
canonical_url: https://grencez.dev/2015/ssh-tutorial-20151107
date: 2015-11-07
description: How to set up passwordless SSH login and tunneling.
---

# Being a Pro with SSH

Date: 2015-11-07

## Reduce your Typing {#sec:sanity}

Let `host=apklinkh@guardian.it.mtu.edu`.
We will learn how to log in quickly to this server, even if the name is quite long.

### Passwordless Login

We can generate a key pair stored on the current machine at `~/.ssh/id\_rsa.pub` (public, safe to share) and `~/.ssh/id\_rsa` (private, never share this one).
```shell
ssh-keygen -t rsa -b 4096
```
Just use the defaults by hitting enter.
Then, we append the content of `~/.ssh/id\_rsa.pub` to `~/.ssh/authorized\_keys` on the host machine.
```shell
ssh-copy-id $host
```
And that's all! You should be able to `ssh $host` without a password!
For passwordless login to subsequent machines, all you need to do is run the `ssh-copy-id` command.

### Aliases

If `$host` is very long to type, or even if it's short, we can make it shorter by adding the following lines to `~/.ssh/config`.
```shell
## ~/.ssh/config
Host wopr
User apklinkh
Hostname guardian.it.mtu.edu
```
Now we can type `ssh wopr` instead of `apklinkh@guardian.it.mtu.edu`.

### Tunneling
Sometimes you want to `ssh` to a host that you can only reach from an internal network.
If you have access to a machine on the internal network, some additions to `~/.ssh/config` make it possible to `ssh` directly to the desired machine.
In this example, `superior` is the machine that we want to access, but we must tunnel through `wopr`.
```shell
## ~/.ssh/config
Host wopr
User apklinkh
Hostname guardian.it.mtu.edu

Host superior
User apklinkh
Hostname superior-login1.research.mtu.edu
ProxyCommand ssh wopr /usr/bin/nc %h %p 2>/dev/null
```
