---
canonical_url: https://grencez.dev/2016/stow-tutorial-20160505
date: 2016-05-05
last_modified_at: 2020-10-26
description: How to install programs from source in Linux as a normal user with GNU Stow.
---

# Install programs as a normal user with GNU Stow

Date: 2016-05-05

Update: 2020-10-26, Stow is still great!

If you are a user on a Linux/Unix system without root privileges, you'll probably run into a scenario where you want to install a program that the administrator does not care to install system-wide.
Continue reading to learn how to do such an installation yourself.

## Initial Setup

### Create Directories

Run the following command.

```shell
mkdir -p ~/bin ~/local/opt ~/local/src ~/local/stow
```

For project releases that have sensible installation steps (e.g., `release=curl-7.48.0`), we can download and build in `~/local/src/$release/`, install to `~/local/stow/$release/`, then use `stow` to symbolically link the installed files to their various locations in `~/local/bin/`, `~/local/lib/`, etc.
In this way, we can remove `~/local/src/$release/` without forgetting which files were installed, since they all reside in `~/local/stow/$release/`.

If `$release` does not have a standard installation structure, then `stow` isn't very helpful.
We just install it in `~/local/opt/$release/` and symbolically link to its executable from `~/bin/`.
This procedure works well enough for me anyway.

### Set the PATH Environment Variable {#sec:PATH}

The `${PATH}` environment variable holds a colon-delimited list of directories where executables should be found.
See what it is now by typing `echo ${PATH}`.
We want to make sure that `~/bin/` and `~/local/bin/` are there.

If you use the `bash` shell (find out using `echo ${SHELL}`), then run the following:
```shell
printf '%s\n' 'export PATH="${HOME}/bin:${HOME}:/local/bin:${PATH}"' >> ~/.bashrc
```
The changes may not take effect unless you log out and log in again.
To check, remember to `echo ${PATH}`.

If you use a `csh`-based shell like `tcsh`, then run the following (or preferably switch to something less terrible):
```shell
bash
printf '%s\n' 'setenv PATH "${HOME}/bin:${HOME}/local/bin:${PATH}"' >> "${HOME}/.cshrc"
exit
```
Note that the other steps of this tutorial require `bash` or some other POSIX-compliant shell.

### Install Stow with Stow

The `stow` (or `xstow`) program may already be installed, check by running `which stow`.
If it is missing, let's install it:

```shell
cd ~/local/src
curl -O http://ftp.gnu.org/gnu/stow/stow-latest.tar.gz
tar xf stow-latest.tar.gz
release=$(ls -Avr | grep -m1 -axEe 'stow-[0-9.]+')
cd $release

./configure --prefix ~/local/stow/$release
make
make install

cd ~/local/stow
./$release/bin/stow $release
cd ~/local/src && rm -fr $release stow-latest.tar.gz
```

## Normal Procedure

### Build/Install

The idea for build/install is basically what you're used to, but we have to specify an installation path of `~/local/stow/$release`, rather than the default `/usr/local`.

**Using Configure Script.**
A project that uses a standard `./configure && make && make install` process can be installed using the following steps.

```shell
./configure --prefix ~/local/stow/$release
make && make install
cd ~/local/stow
stow $release
```
See [this full example](#sec:eg:configure).

**Using CMake.**
For projects using `cmake`, follow this pattern.

```shell
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX="${HOME}/local/stow/$release" ..
make && make install
cd ~/local/stow
stow $release
```
See [this full example](#sec:eg:cmake).

### Uninstall

To uninstall a package, we simply invoke the `stow -D` command to remove symlinks from `~/local/`, then we manually remove the installed files.
It looks like this:

```shell
cd ~/local/stow
stow -D $release
rm -fr $release
```

### Example Using Configure Script {#sec:eg:configure}

Here is an example of installing the `espresso` logic minimization tool.

```shell
cd ~/local/src
release=espresso-ab-1.0
curl -O https://eqntott.googlecode.com/files/$release.tar.gz
tar xf $release.tar.gz
cd $release

./configure --prefix ~/local/stow/$release
make
make install

cd ~/local/stow
stow $release
cd ~/local/src && rm -fr $release $release.tar.gz
```

### Example Using CMake {#sec:eg:cmake}

Here is an example of installing the `curl` tool that we have used to download files.

```shell
cd ~/local/src
release=curl-7.48.0
curl -O https://curl.haxx.se/download/$release.tar.gz
tar xf $release.tar.gz
cd $release

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX="${HOME}/local/stow/$release" ..
make -j4
make install

cd ~/local/stow
stow $release
cd ~/local/src && rm -fr release $release.tar.gz
```
