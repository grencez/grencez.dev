---
canonical_url: https://grencez.dev/2024/ipv6-forwarding-lxc-20240624
date: 2024-06-24
last_modified_at: 2024-06-24
description: Forwarding IPv6 traffic through an Alpine LXC router on Proxmox.
---

# How to route IPv6 through an Alpine LXC on Proxmox

Date: 2024-06-24

## Motivation
I just want to run a lightweight LXC as an IPv6 router in Proxmox.

In this article, we'll configure the following:
- `route-3-host` as an Alpine LXC that acts as a simple IPv6 router.
- `eth0` as `route-3-host`'s WAN interface that obtains IPv6 addresses via DHCPv6.
  - `vmbr0` on the Proxmox host. This should already exist.
- `eth1` as `route-3-host`'s LAN interface that provides IPv6 addresses via SLAAC.
  - `vmbr3` on the Proxmox host. We'll create this too.
- `test-3-host` as an Alpine LXC whose traffic will go through `route-3-host`.
  - We'll give it a simple firewall in Proxmox that blocks inbound traffic.

## Setup
### Router LXC
Let's set up `route-3-host` along with its network bridge interface `vmbr3`.
- Click: A storage pool -> CT Templates -> Templates -> A new alpine package -> Download
- Click: Create CT
  - General
    - Name: `route-3-host`
  - Template: The CT Template you just downloaded.
  - (... defaults are fine ...)
  - Network
    - Name: `eth0`
    - Bridge: `vmbr0`
    - IPv4: DHCP
    - IPv6: Static (It'll use DHCP, but we don't bother configuring it here.)
    - Firewall: No
- Click: A datacenter node (i.e., the Proxmox host) -> Network -> Create -> Linux Bridge
  - Name: `vmbr3`
- Click: `route-3-host` -> Network -> Add
  - Name: `eth1`
  - Bridge: `vmbr3`
  - Firewall: No
  - IPv4 and IPv6: Static

Now boot up the new `route-3-host` LXC and login as root.
You'll be greeted with some text that mentions running `setup-alpine`, but we already did the initial setup in Proxmox, so let's overwrite the Message of the Day:
```shell
echo '# Main screen turn on.' >/etc/motd
```

Freshen up the system by updating packages:
```shell
apk update
apk upgrade
```

Verify that `route-3-host` can reach the internet over IPv6:
```shell
nslookup ip6only.me
```

### Forwarding
Configure `sysctl` to enable IPv6 forwarding across all devices:
```shell
# Enable forwarding.
cat >/etc/sysctl.conf <<"HEREDOC"
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
HEREDOC
rc-update add sysctl default
rc-service sysctl start
```

Verify that both `eth0` and `eth1` report a "1" value for IPv6 forwarding:
```shell
cat /proc/sys/net/ipv6/conf/eth0/forwarding
cat /proc/sys/net/ipv6/conf/eth1/forwarding
```

### DHCP Client
Configure `dhcpcd` to obtain an IPv6 address on `eth0` along with an IPv6 prefix to delegate to `eth1`:
```shell
apk add dhcpcd
cat >/etc/dhcpcd.conf <<"HEREDOC"
noipv6rs
ipv6ra_noautoconf
interface eth0
  ipv6rs
  ia_na 1
  ia_pd 2 eth1/0
interface eth1
  ipv6only
HEREDOC
rc-service networking restart
```

Verify that `route-3-host` can still reach the internet over IPv6:
```shell
nslookup ip6only.me
ping -6 -c 3 grencez.dev
```

Verify that `route-3-host` has 2 IPv6 addresses for `eth0` and another 2 for `eth1`:
```shell
ip -6 address show dev eth0
ip -6 address show dev eth1
```

For both interfaces, expect to see a link-local address that begins with `fe8` and a global address that doesn't.

An IPv4 address may also exist for `eth0` (run `ip -4 address` to check).
If you don't want it anymore, add an "ipv6only" line under "interface eth0" in `/etc/dhcpcd.conf` and restart the `networking` service again.

### SLAAC Router
Configure `radvd` to advertise that `route-3-host` can act as a router for SLAAC clients on `eth1`:
```shell
apk add radvd
cat >/etc/radvd.conf <<"HEREDOC"
interface eth1 {
  AdvSendAdvert on;
  prefix ::/64 {
    AdvOnLink on;
    AdvAutonomous on;
  };
};
HEREDOC
rc-update add radvd default
rc-service radvd start
```

## Test
### Client LXC
In order to test, let's create the client LXC named `test-3-host`.
This time we let Proxmox know how we actually intend to obtain IP addresses.
- Click: Create CT
  - General
    - Name: `test-3-host`
  - (... defaults are fine ...)
  - Network
    - Name: `eth0`
    - Bridge: `vmbr3`
    - IPv4: Static
    - IPv6: SLAAC
    - Firewall: Yes
  - DNS
    - Servers: `2606:4700:4700::1111,2001:4860:4860::8888` (Cloudflare and Google DNS servers)
- Click: `test-3-host` -> Firewall -> Options
  - Firewall: Yes
  - NDP: Yes
  - log_level_in: info
  - log_level_out: nolog
  - Input Policy: DROP
  - Output Policy: ACCEPT

### Client Connectivity
Boot up the new `test-3-host` LXC and hope for the best!
Try to lookup a hostname first in order to test DNS resolution:
```shell
nslookup grencez.dev
ping -c 3 grencez.dev
```

### Client Firewall
Next we should ensure that a firewall is actually blocking traffic.

On `test-3-host`, grab one of the addresses returned by `ip address` and try pinging it from `route-3-host`.
The ping command should not show any responses; 100% packet loss.

You should also be able to see these DROPped ping attempts in the Proxmox UI at `test-3-host` -> Firewall -> Log.

## Followup
I'd like to eventually use this Alpine LXC to replace a pfSense VM in my Proxmox host and run similar setups on dedicated hardware.
Router operating systems actually kind of suck.
But there's a few more challenges to tackle:
- **Stable IPs.** I currently use IPv4 addresses assigned deterministically by a DHCP server. That can probably be replicated with IPv6's unique local addresses (ULA).
- **DNS server.** The two LXC hosts we configured in this article cannot find each other by name. It would be best if `route-3-host` could also act as a DNS server.
- **Firewall.** Proxmox has a great firewall tool, but it obviously won't suffice if the router runs on its own machine.
- **Wi-Fi.** It should be pretty easy to use a Wi-Fi device instead of `eth0`. Just not in an LXC.
- **Ansible.** While this article was pretty simple, my actual setup will quickly become unmanageable without some automation to keep configs consistent.

## Reference
- [https://oscillate.gr/words/router-pt3/](https://oscillate.gr/words/router-pt3)
- [https://riedstra.dev/2022/02/alpine-linux-home-router](https://riedstra.dev/2022/02/alpine-linux-home-router)
- [https://wiki.gentoo.org/wiki/IPv6_router_guide](https://wiki.gentoo.org/wiki/IPv6_router_guide)
- [https://man.archlinux.org/man/dhcpcd.conf.5](https://man.archlinux.org/man/dhcpcd.conf.5)
