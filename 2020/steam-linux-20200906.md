---
canonical_url: https://grencez.dev/2020/steam-linux-20200906
date: 2020-09-06
description: How to run Hades' Star on Linux in Steam as different user.
last_modified_at: 2020-11-16
---

# Running Hades' Star on Linux in Steam

Date: 2020-09-06

This seemed harder than it should be.

## Steps

First I created a new user for Steam with appropriate permissions.

```shell
sudo useradd --user-group --create-home --shell /bin/false grencez-for-games
# Give permission to play sound.
sudo usermod -a -G audio grencez-for-games
```

Next create a `/etc/sudoers.d/grencez-for-games` file with the line:

```
grencez ALL=(grencez-for-games) NOPASSWD: ALL
```

This allows me to run Steam as that user without entering a password:

```shell
sudo -u grencez-for-games -- steam
```

Though, you may need to add the new user to xhost permission for that to work:

```shell
# Show authorized clients.
xhost
# Add local grencez-for-games user as authorized client.
xhost +SI:localuser:grencez-for-games
```

Then I enabled Proton in Steam Play.

It gives a lot of errors, but I eventually realized that it requires Vulkan, which was just a matter of installing `media-libs/vulkan-loader` and `media-libs/mesa` with the `vulkan` USE flag.
I configured both packages to support 32-bit for good measure.

Instead of Vulkan, I could have probably just enabled `PROTON_USE_WINED3D` in `$HOME/.steam/steam/steamapps/common/Proton\ 5.0/user_settings.py`, which I tried but forgot to rename the `user_settings.sample.py` file to `user_settings.py`.

## Extra: Controller Support

You may want to use a game controller in other games.
I use a Microsoft Xbox 360 controller, which is supported via the `xpad` kernel module.
To use it with Steam, give the games user `input` permission:

```
sudo usermod -a -G input grencez-for-games
```

Kudos to [myersguy](https://reddit.com/user/myersguy) for posting [this info](https://www.reddit.com/r/archlinux/comments/b9wsy2/wireless_xbox_360_controller_and_steam/ek83wmp).

In Steam's general controller settings, you can also disable `Xbox Configuration Support`.
This option seems to unnecessarily require Big Picture mode.
