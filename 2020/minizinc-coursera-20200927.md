
# Submitting a MiniZinc Coursera assignment

Date: 2020-09-27

I'm taking a [Basic Modeling for Discrete Optimization](https://www.coursera.org/learn/basic-modeling) course through Coursera, and the first assignment is due today.
It was a challenge to run MiniZinc and also submit the assignment.

To summarize the problems:

* Gecode and MiniZinc would not easily build from source.
  * It looks like `bison` generates a `parser.tab.cpp` that references a `parser.tab.hpp`, but these projects have build rules to rename the file to have a `.hh` extension.
  * I couldn't figure out an easy fix.
  * **Fix:** Use the binary AppImage.
* The assignment came with a `submit.py` file for Coursera that didn't work with Python >= 3.8.
  * Error: `AttributeError: module 'time' has no attribute 'clock'`
  * I could submit by running it with Python 3.7, but the submission didn't pass Coursera checks.
    * Error: `Check your output statement and make sure it meets the requirements of the assignment.`
  * **Fix:** Submit from the MiniZinc IDE.
* MiniZinc IDE failed to submit due to an old OpenSSL 1.0 dependency.
  * Error: `qt.network.ssl: QSslSocket: cannot resolve SSL_library_init`
  * Error: `Error creating SSL context (error:140A90C4:SSL routines:func(169):reason(196))`
  * **Fix:** Build a shared OpenSSL 1.0.2 library.


## Installing MiniZinc

MiniZinc couldn't build from source, so I installed the binary AppImage.
Since it's untrusted, I set it up to run as separate user named `grencez-for-games`, which was created in [a previous article](steam-linux-20200906.md).
The username does make some sense as MiniZinc will be solving puzzles.

Installation was fairly straightforward.
I placed the AppImage in an `Applications` directory, and the installation step just creates some symlinks to it.

```shell
sudo -u grencez-for-games -- bash
cd ~/
mkdir -p Applications
wget -P Applications/ https://github.com/MiniZinc/MiniZincIDE/releases/download/2.4.3/MiniZincIDE-2.4.3-x86_64.AppImage
chmod u=rwx,go= Applications/MiniZincIDE-2.4.3-x86_64.AppImage
mkdir -p bin
BIN_LOCATION=$HOME/bin ./Applications/MiniZincIDE-2.4.3-x86_64.AppImage install
```

To quickly run `minizinc` as my normal user, I made a script `/home/grencez/bin/minizinc`:

```shell
#!/bin/sh

exec sudo -u grencez-for-games -- /home/grencez-for-games/bin/minizinc "$@"
```

## Running MiniZincIDE with OpenSSL 1.0.2 library

I built the shared library for OpenSSL in `/home/grencez-for-games/local/opt/openssl-1.0.2/`:

```shell
sudo -u grencez-for-games -- bash
# Download and put in ~/local/opt/.
wget -O - https://ftp.openssl.org/source/old/1.0.2/openssl-1.0.2.tar.gz |
tar -x -z -f - -C ~/local/opt/

cd ~/local/opt/openssl-1.0.2/
make clean
# Configure to build shared libraries.
./config shared
make
```

Now we can invoke `MiniZincIDE` with `LD_LIBRARY_PATH` set so it finds the OpenSSL shared library.
Here is my `/home/grencez/bin/MiniZincIDE` script:

```shell
#!/bin/sh

role=grencez-for-games

exec sudo -u "$role" \
  LD_LIBRARY_PATH="/home/$role/local/opt/openssl-1.0.2" \
  -- "/home/$role/bin/MiniZincIDE" "$@"
```
