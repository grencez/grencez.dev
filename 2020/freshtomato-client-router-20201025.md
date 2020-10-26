---
canonical_url: https://grencez.dev/2020/freshtomato-client-router-20201025
date: 2020-10-25
description: How I set up FreshTomato on a router to act as a Wi-Fi adapter.
---

# Setting up FreshTomato on a router to act as a wireless adapter

Date: 2020-10-25

## Motivation

I had DD-WRT on a Linksys E1200 v2 router acting as a wirelss adapter (for my desktop connected by ethernet), but its admin console became inaccessible.
This was basically okay until I wanted it to connect to a different access point.

Since I was going to hard reset, I figured it might be time for a new firmware.
But wow, DD-WRT hasn't been updated in a while, is there some new hotness?
OpenWRT doesn't fit in the Linksys E1200 memory, so that's not an option.
Is there a fresh version of Tomato?
Turns out, yes. (FreshTomato)[https://freshtomato.org].

## Steps

**Install.** I followed https://easylinuxtipsproject.blogspot.com/p/tomato.html#ID3 pretty closely.

1. https://wiki.freshtomato.org/doku.php/hardware_compatibility sayss that the `K26RT-N` version of FreshTomato supports Linksys E1200 v2.
1. Grab the latest iteration of that from https://freshtomato.org/downloads.
  1. I used: https://freshtomato.org/downloads/freshtomato-mips/2020/2020.6/K26RT-N/Linksys%20E-series/freshtomato-E1200v2-NVRAM64K_RT-N5x-MIPSR2-2020.6-Max.zip
  1. Then unzip it. We'll use the `.bin` file.
1. Hard reset (hold down the recessed reset button until lights flash. Then power cycle.
1. DD-WRT shows up at http://92.168.1.1 now.
1. `Administration -> Firmware Upgrade` tab.
  1. `Don't reset` after finishing. We'll hard reset to wipe settings.
  1. Select the FreshTomato file ending in `.bin`.
  1. Upgrade.
1. Wait for FreshTomato to serve http://192.168.1.1. Or at least be sure it's finished installing.
1. Hard reset to clear memory. May need to power cycle too.
1. Login as username `root` with password `admin`.

**Change local IP to avoid conflicts.** Before we get access to the rest of the local network, we should make sure that the router uses a different subnet than others.

1. `Basic -> Network` tab.
  1. Set `LAN -> IP Address` on a unique subnet. I used `192.168.5.1` (with a subnet mask of `255.255.255.0`) since nothing else on the network starts with `192.168.5.`.
  1. Set `LAN -> IP Range` on the same unique subnet. I used `192.168.5.2` to `192.168.5.50` even though I only really need 1 address.
  1. Save.
1. Change the browser URL accordingly (e.g., to http://192.168.5.1).
1. Refresh your IP.
  1. `sudo ifconfig eth0 down` followed by `sudo ifconfig eth0 up` is the quick and dirty way.
  1. (`eth0` is the network device reported by `ifconfig`. Actually, mine is `enp9s0`.)

**Configure Wireless Client mode.** I followed https://learntomato.flashrouters.com/setup-wireless-client-bridge-tomato-router/ pretty closely.

1. `Basic -> Network` tab.
  1. Set `Wireless Client Mode` as `2.4 GHz / eth1` (not disabled).
    1. This automatically changes `Wireless Mode` to `Wireless Client`.
  1. Set `SSID` as the primary router's SSID.
  1. Set `Security` as the primary router's security mode (`WPA2 Personal`).
  1. Set `Shared Key` as the primary router's password.
  1. Save.

## Other

**Lock down access.** Might as well handle the security steps now.

1. Login as username `root` with password `admin`.
1. `Administration -> Admin Access`
  1. Set username and password to something better than the defaults.
  1. Save.
  1. Sign in with new password.
  1. Set `Allow Wireless Access` as not checked.
  1. Save. Don't let the browser pdate a saved password here, it's trying to set the wrong one.

**TODO: Enable IPv6?**
I did have IPv6 working with DD-WRT configured as a `Client Bridge` (when it became inaccessible...).
That method involved setting the primary access point's IP (v4, nothing v6) as a default gateway, and I don't think the client router was running its own DHCP server.

So far, I have tried the settings described athttps://home.wieringafamily.com/projects/ipv6-home/, even though the instructions don't pertain to `wWreless Client` mode:

1. `Basic -> IPv6` tab.
  1. `IPv6 Service Type` as `DHCPv6 with Prefix Delegation`.
  1. Save.
1. Reboot.
1. Cry and give up.

