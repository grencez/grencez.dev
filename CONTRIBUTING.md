# Development

## Preview

This site is hosted with GitHub Pages, which uses [Jekyll](https://jekyllrb.com/).
With the help of minimal `Gemfile` and `_config.yml` files, we can also preview it locally.
Docker simplifies the process:

```shell
docker run --rm -it -v "$PWD:/srv/jekyll" -p 4000:4000 jekyll/jekyll jekyll serve
```
