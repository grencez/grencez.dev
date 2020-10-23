
# Installing the "dvorak-grencez" custom keyboard layout

Date: 2020-10-22

## Background

Sometime in October 2008 when I was just getting into fall courses at Michigan Tech, my fingers were getting tired of programming.
Particularly, my right ring and pinky fingers were tired of reaching for dots, dashes, slashes, braces, brackets, quotes, etc.
It's a lot for two fingers to handle, so I decided to switch keyboard layouts.
None were quite right, and I figured that if I was going to break years of muscle memory, it was probably worth striving for perfection.
So I made my own layout using some guiding principles:

* The Dvorak layout should have pretty optimal placement of letters and common punctuation.
* The Programmer Dvorak layout probably has some good symbol locations.
* Symmetry of balanced delimiters (e.g., parentheses) guarantees that they won't use one hand more than the other.

This was the resulting "dvorak-grencez" layout (first normal, then with "Shift" held):

```
|---------------------------------------------------------|
| $ | & | [ | { | ( | + | = | * | ) | } | ] | ! | # |  BS |
|---------------------------------------------------------|
| Tab | ; | , | . | p | y | f | g | c | r | l | / | \ | @ |
|---------------------------------------------------------|
| ENTR | a | o | e | u | i | d | h | t | n | s | - | ENTR |
|---------------------------------------------------------|
| SHIFT  | ' | q | j | k | x | b | m | w | v | z |  SHIFT |
|---------------------------------------------------------|
| Ctl | Sup | Alt |      SPACE BAR      | Alt | Sup | Ctl |
|---------------------------------------------------------|

|---------------------------------------------------------|
| ~ | 9 | 7 | 5 | 3 | 1 | % | 0 | 2 | 4 | 6 | 8 | ` |  BS |
|---------------------------------------------------------|
| Tab | : | < | > | P | Y | F | G | C | R | L | ? | | | ^ |
|---------------------------------------------------------|
| ENTR | A | O | E | U | I | D | H | T | N | S | _ | ENTR |
|---------------------------------------------------------|
| SHIFT  | " | Q | J | K | X | B | M | W | V | Z |  SHIFT |
|---------------------------------------------------------|
| Ctl | Sup | Alt |      SPACE BAR      | Alt | Sup | Ctl |
|---------------------------------------------------------|
```

## Simple config (Xmodmap and loadkeys)

Using it has been pretty easy so far.
I have a [dvorak-grencez.map](dvorak-grencez.map) config for `loadkeys` to set the console layout and a [dvorak-grencez.xmodmap](dvorak-grencez.xmodmap) config for `xmodmap` to set the layout when X is running.
The following commands download both files (for completeness), resets the keyboard layout in X (for sanity), then uses `xmodmap` to swap keys around:

```shell
mkdir -p $HOME/local/opt/dvorak-grencez/
cd $HOME/local/opt/dvorak-grencez/
wget http://grencez.dev/2020/dvorak-grencez-20201022/dvorak-grencez.map
wget http://grencez.dev/2020/dvorak-grencez-20201022/dvorak-grencez.xmodmap
setxkbmap us
xmodmap dvorak-grencez.xmodmap
# setxkbmap us  # Reset to qwerty
```

I have a script called `amasdf` to run those last 2 commands and another script called `amaoeu` that runs `setxkbmap us` to quickly let someone else the keyboard.

The `loadkeys` config can similarly be used without installing it:

```shell
sudo loadkeys dvorak-grencez.map
# sudo loadkeys us  # This resets to qwerty.
# sudo loadkeys --default  # This resets to the system default, if you were using something else.
```

But this needs root permission, and I never need to swap to qwerty, so I install it as a system default.
In Gentoo Linux (with OpenRC instead of systemd), this is a matter of adding a compressed config to a standard location in `/usr/share/keymaps/` and then setting `keymap="dvorak-grencez"` in `/etc/conf.d/keymaps`:

```shell
gzip --keep dvorak-grencez.map
sudo install -D -m 644 dvorak-grencez.map.gz /usr/share/keymaps/i386/dvorak/dvorak-grencez.map.gz
rm dvorak-grencez.map.gz
sudo sed -i -E -e "s/^keymap=.*/keymap=\"dvorak-grencez\"/" /etc/conf.d/keymaps
```

## Problems with Xmodmap

The simplicity of Xmodmap is fantastic, but it doesn't seem low-level enough in some cases.
For example, after recent update (of X?), `xmodmap` does not affect keyboard shortcuts of some programs (e.g., "new tab" in Chromium) until they restart.
Perhaps that example has a solution, but I'd also like to set a system default instead of typing a command after rebooting or plugging in new keyboard.

## Native X config (XKB)

The X keyboard extension (XKB) defines how X handles keyboard input.
Running `setxkbmap us` is actually loading the first entry of `/usr/share/X11/xkb/symbols/us`.
The other subdirectories of `/usr/share/X11/xkb/` have configs that feed into it, but I only care about the symbols.

Xmodmap can be loaded and [dumped as an XKB config](https://unix.stackexchange.com/questions/202883/create-xkb-configuration-from-xmodmap).
The following commands do that, trims the config to just the `xkb_symbols` section, then installs the file as `/usr/share/X11/xkb/symbols/us_dvorak_grencez`:

```
setxkbmap us  # Reset.
xmodmap dvorak-grencez.xmodmap  # Apply Xmodmap config.
xkbcomp -xkb $DISPLAY -o us_dvorak_grencez

sed -i -n -E -e "/^xkb_symbols /,/^}/p" us_dvorak_grencez
sed -i -E -e "s/^xkb_symbols \".*\"/xkb_symbols \"us_dvorak_grencez\"/" us_dvorak_grencez

sudo install -m 644 us_dvorak_grencez /usr/share/X11/xkb/symbols/us_dvorak_grencez
rm us_dvorak_grencez
```

Now `setxkbmap -query` reports `us_dvorak_grencez` as the layout and `pc105` as the model.
Great!
The system default is changed by creating a `/etc/X11/xorg.conf.d/00-keyboard.conf` file containing:

```
Section "InputClass"
  Identifier "system-keyboard"
  MatchIsKeyboard "on"
  Option "XkbLayout" "us_dvorak_grencez"
  Option "XkbModel" "pc105"
  Option "XkbVariant" ""
  Option "XkbOptions" ""
EndSection
```
