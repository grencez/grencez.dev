---
canonical_url: https://grencez.dev/2022/dotfiles-20220222
date: 2022-02-22
last_modified_at: 2023-07-22
description: Various configuration files.
---

# Grencez' Dotfiles

Date: 2022-02-22

* [tmux](tmux_conf.txt)
* [urxvt](urxvt.txt)
* [Vim Colorscheme](vim_colors_grencez.txt)
* [Vim](vimrc.txt)

```shell
url=https://grencez.dev/2022/dotfiles-20220222
dst="$HOME"

curl -o "$dst/.tmux.conf" "$url/tmux_conf.txt"
curl -o "$dst/.Xresources" "$url/urxvt.txt"
mkdir -p "$dst/.vim/colors"
curl -o "$dst/.vim/colors/grencez.vim" "$url/vim_colors_grencez.txt"
curl -o "$dst/.vimrc" "$url/vimrc.txt"
```

