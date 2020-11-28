---
canonical_url: https://grencez.dev/2020/webgl-texture-ping-pong-20200607
date: 2020-06-07
description: Ping-pong texturing with WebGL.
last_modified_at: 2020-11-28
---

# WebGL ping-pong shading

Date: 2020-06-07

Demo: [main.html](main.html)

View [main.html](https://github.com/grencez/grencez.dev/blob/trunk/2020/webgl-texture-ping-pong-20200607/main.html) and [main.js](https://github.com/grencez/grencez.dev/blob/trunk/2020/webgl-texture-ping-pong-20200607/main.js) on GitHub.

Check the demo.
You should see a prominent ring of colors surrounding 2 grey squares.
Blank rows separate those colors, and you may notice some rather feint colors to the left of the prominent ones.
Every time you click, the prominent colors rotate clockwise around the greys.

The 6x8 texture being displayed is actually a 3x4 grid of point sprites, where each sprite is 2x2 pixels.
The feint color at the bottom left of each sprite encodes the texture coordinates of its *next* color.
Upon clicking, each sprite's bottom right color is updated accordingly.
Since we can't read and write the same texture, there are 2 copies of the 6x8 texture, and rendering "ping-pongs" from one to the other.

A separate rendering pass displays the texture.
Each sprite's texture data is mapped onto a separate quad, so it would be fairly simple to manipulate those quads using the sprite data.
For example, we could move a quads over time while drawing frames of a "walking" animation.
