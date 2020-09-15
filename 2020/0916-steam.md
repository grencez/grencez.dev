
# Running Hades' Star on Linux in Steam

Date: 2020-09-06

This seemed harder than it should be.
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

Then I enabled Proton in Steam Play.

It gives a lot of errors, but I eventually realized that it requires Vulkan, which was just a matter of installing `media-libs/vulkan-loader` and `media-libs/mesa` with the `vulkan` USE flag.
I configured both packages to support 32-bit for good measure.

Instead of Vulkan, I could have probably just enabled `PROTON_USE_WINED3D` in `$HOME/.steam/steam/steamapps/common/Proton\ 5.0/user_settings.py`, which I tried but forgot to rename the `user_settings.sample.py` file to `user_settings.py`.
