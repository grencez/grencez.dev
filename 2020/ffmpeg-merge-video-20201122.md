---
canonical_url: https://grencez.dev/2020/ffmpeg-merge-video-20201122
date: 2020-11-22
last_modified_at: 2020-11-23
description: How to concatenate videos together and add audio samples using FFmpeg.
---

# Concatenating videos and adding audio samples using FFmpeg

## Concatenating many videos

I was trying to watch a video on a Chromecast, but it kept temporarily pausing/stuttering every 20 seconds.
The weird thing is, it played continuously in the phone browser, so it wasn't a buffering issue.
Well no matter, I can probably just download the video and cast with VLC media player.

To download, I tried the [Video DownloadHelper](https://www.downloadhelper.net/) browser extension.
It shows media on the current page.
In this case, there was a lot of media, roughly 128 different video fragments at sequentially-numbered URLs like `https://cdn.grercez.dev/coolvideo-0128.mp4`.
That explains the pauses: Chromecast had to keep loading new videos, and either the website's casting code didn't handle this well or the machine itself couldn't multitask.
Either way, this became a problem of downloading video fragments and concatenating them into one big video.

The command that eventually worked is mostly taken from the [FFmpeg wiki page](https://trac.ffmpeg.org/wiki/Concatenate) on concatenation:

```shell
ffmpeg -f concat -safe 0 -i fragments.txt -shortest -c copy merged.mp4
```

* `-shortest`: Ensures that the audio and video of each fragment match each other's length.  Without this, the merged video briefly froze every 20 seconds while the audio kept playing.
* `-safe 0 -i fragments.txt`: Allow unsafe characters in the filenames of of `fragments.txt`. In my case, file has lines like `file pathto/video-fragment-X.mp4`, where the slash is considered unsafe.
* `-c copy`: Copy input video rather than re-encoding it.

### Script

The full script goes in a few stages:
1. Generate a list of video URLs.
2. Download video fragments in parallel with `aria2c`. Its default is [5 simultaneous downloads](https://aria2.github.io/manual/en/html/aria2c.html#cmdoption-j).
3. Generate a list of files for `ffmpeg`.
4. Merge videos with `ffmpeg`.
5. Remove the temporary files.

```shell
# Create the list of URLs.
for i in $(seq 1 128); do
  printf "https://cdn.grercez.dev/coolvideo-%04d.mp4\n" $i
done > urls.txt
# Download video fragments to the fragments/ directory.
mkdir -p fragments
aria2c --dir=fragments --input-file=urls.txt

# Create list of downloaded files for ffmpeg.
cat urls.txt |
while read url ; do
  printf "file fragments/%s\n" "$(basename "$url")" >> fragments.txt
done > urls.txt
# Merge video fragments.
ffmpeg -f concat -safe 0 -i fragments.txt -shortest -c copy merged.mp4


# Clean up everything but merged.mp4.
rm -f urls.txt fragments.txt fragments/*
rmdir -f fragments
```

## Adding audio to a video sample

A few days later, I wanted to make a simple meme out of a screen recording.
The basic idea here was to merge audio into a silent video.
But before that, I also needed to crop the video, extract the funny segment, and re-encode it to be a reasonable size.

Let's look at these steps individually.
However, it's best to keep re-encoding to a minimum, so we'll combine all the steps into one command at the end.

**Extract audio**
As a first step, we want to extract audio track from a video obtained with `youtube-dl`.
Since this won't be the final product, we can be a bit sloppy and re-encode it:

```shell
ffmpeg -nostdin -i audio_original.mkv -vn -b:a 128k -y audio_track.m4a
```

* `-nostdin`: Ignore standard input. Without this, copy/pasting the commands doesn't work as expected since parts of them are consumed on stdin.
* `-vn`: No video.
* `-b:a 128k`: (optional) Use a 128k bitrate for audio. This is the default, but it's nice to be explicit.
* `-y`: Allow overwriting the output file.

We could also have been careful and extracted the original audio.
Running `ffprobe audio_original.mkv` shows that the audio codec is `opus`, which is customarily contained in an `.oga` file.
Extracting the original would be:

```shell
ffmpeg -nostdin -i audio_original.mkv -vn -c copy -y audio_original.oga
```

However, we don't go this route!
Our final video will be a `.mp4`, which in not a well-supported container for Opus audio, so we'll have to re-encode the audio anyway.

**Crop video.**
The first step is cropping.
In this case, the original video was 1440x2960 and I ended up removing the top 540 pixels and the bottom 420 pixels (420=2960-2000-540).
Also, it made sense to output a 700x1000 video instead of 1400x2000.
This took some trial and error of course, so previewed various options using `ffplay`.
My final preview command looks a lot like the `ffmpeg` command to encode it:

```shell
ffplay -i video_original.mp4 -vf crop=1400:2000:0:540,scale=700:1000
ffmpeg -nostdin -i video_original.mp4 -vf crop=1400:2000:0:540,scale=700:1000 -an -b:v 1M -y video_track.mp4
```

* `-vf crop=1400:2000:0:540,scale=700:1000`: Video filters to crop and scale.
* `-an`: Remove audio if it exists.
* `-b:v 1M`: (optional) Encode using an average of 1 million bits per second of video.

**Trim audio and video samples.**
Whatever you want to call this operation, it's pretty easy.

```shell
ffmpeg -nostdin -ss 00:03:28.5 -t 00:00:46.5 -i audio_track.m4a -c copy -y audio_sample.m4a
ffmpeg -nostdin -ss 00:03:31.5 -t 00:00:46.5 -i video_track.mp4 -c copy -y video_sample.mp4
```

* `-ss`: Start time.
* `-t`: Duration.

**Merge audio and video.**
Finally the merging of audio and video.
I had trouble keeping the audio and video in sync but eventually found the `+genpts` option.
Unfortunately, I couldn't figure out how to use this without re-encoding the video:

```shell
ffmpeg -nostdin -i audio_sample.m4a -i video_sample.mp4 -fflags +genpts -acodec copy -b:v 1M -y meme.mp4
```

* `-fflags +genpts`: Add timestamps to keep audio and video in sync.
* `-acodec copy`: Copy input audio rather than re-encoding it. This doesn't save much time.

### As one command

In the steps above, the video is re-encoded twice.
To avoid extra artifacts, the final product should be made with one command:

```shell
ffmpeg -nostdin \
  -ss 00:03:28.5 -i audio_original.mkv \
  -ss 00:03:31.5 -i video_original.mp4 \
  -t 00:00:46.5 \
  -map 0:a -map 1:v \
  -vf crop=1400:2000:0:540,scale=700:1000 \
  -fflags +genpts \
  -b:a 128k -b:v 1M -y meme.mp4
```

* `-map 0:a`: Take audio from first input.
* `-map 1:v`: Take video from second input.

Instead of video bitrate `-b:v 1M`, you could play around with the [H.264 Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.264#crf).
For me, the default CRF of 23 yielded a video bitrate of 1236k, but after using slower presets and tuning as an animation, I was able to obtain bitrate of 1008k with a lower (better) CRF of 22.
The final command being:

```shell
ffmpeg -nostdin \
  -ss 00:03:28.5 -i audio_original.mkv \
  -ss 00:03:31.5 -i video_original.mp4 \
  -t 00:00:46.5 \
  -map 0:a -map 1:v \
  -vf crop=1400:2000:0:540,scale=700:1000 \
  -fflags +genpts \
  -b:a 128k -crf 22 -preset veryslow -tune animation -y meme.mp4
```

* `-crf 22`: H.264 constant rate factor.
* `-preset veryslow`: Use the slowest presets to get the best compression.
* `-tune animation`: Specify that the video is an animation-like. For my gameplay screen recording, this gave crisper edges with less bitrate.

