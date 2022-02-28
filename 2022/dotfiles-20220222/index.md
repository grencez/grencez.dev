---
canonical_url: https://grencez.dev/2022/dotfiles-20220222
date: 2022-02-22
last_modified_at: 2022-02-27
description: Various configuration files.
---

# Grencez' Dotfiles

Date: 2022-02-22

* [Vim Colorscheme](vim_colors_grencez.txt)

```shell
url=https://grencez.dev/2022/dotfiles-20220222
dst="$HOME"

mkdir -p "$dst/.vim/colors"
curl -o "$dst/.vim/colors/grencez.vim" $url/vim_colors_grencez.txt"
```

