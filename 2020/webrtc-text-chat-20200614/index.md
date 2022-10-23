---
canonical_url: https://grencez.dev/2020/webrtc-text-chat-20200614
date: 2020-06-14
description: A simple WebRTC text chat without a signalling or TURN server.
last_modified_at: 2022-10-23
---

# WebRTC text chat without a signalling or TURN server

Date: 2020-06-14; Update: 2022-10-23

Demo: [main.html](main.html) or [try STUN-less mode](main.html?stun_url=) if both parties have IPv6 addresses.

View [main.html](https://github.com/grencez/grencez.dev/blob/trunk/2020/webrtc-text-chat-20200614/main.html) and [main.js](https://github.com/grencez/grencez.dev/blob/trunk/2020/webrtc-text-chat-20200614/main.js) on GitHub.

Even though WebRTC is touted as peer-to-peer for the web, most tutorials say you also need a STUN server, a signalling server, and a TURN server.
Well if you rely on IPv4 NAT traversal, you will need a STUN server to figure out your own connection info, but plenty of them are available for anyone to use (e.g., the demo above uses`stun:stun.l.google.com:19302`).
But what about signalling and TURN?

Signalling is essential for usability.
For example, open the demo page.
Before actually connecting with each other, you have to give your friend a WebRTC offer and they have to give you back a WebRTC answer.
The most basic signalling server would provide a channel for this exchange, where you might both connect to it with the same key (e.g., meeting code).
Signalling is also where a server can collect/present persistent data.

TURN is a fallback for when the P2P connections fail.
Personally, I'd prefer some apps to just fail, but I can imagine that most companies favor reliability.

True P2P applications only need a rendezvous point, so I'm somewhat surprised that there isn't a standard for it (at least not for WebRTC).
To that end, I'll rewrite this demo to use a [swapping rendezvous server](https://github.com/rendezqueue/rendezqueue) in a future article.
