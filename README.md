SoundDart
=========
SoundDart is Command-line SoundSprite generator for [Dart](https://www.dartlang.org/)

It requires the wonderful [ffmpeg](http://www.ffmpeg.org/download.html) to be in your [PATH](http://en.wikipedia.org/wiki/PATH_(variable\)).

##What's a SoundSprite?##
Just like sprite sheets for graphics, a SoundSprite is comprised of several sounds, stitched together in a single compressed file. This allows for fewer HTTP Requests / deployed assets in your project. A configurable silence gap is placed between each sound (to help prevent loose Audio APIs from running into other sounds) and since Variable Bit Rate (VBR) encoding is available for most formats, there is little file size penalty.

##How do I use SoundDart?##
SoundDart is run on the command-line, using the [DartVM](https://www.dartlang.org/tools/dart-vm/) like so:

`dart path/to/soundart.dart`

Passing no options will provide a familiar help block:

```
Combines uncompressed sound files, encodes to popular formats, and generates json atlas.

Usage:

dart sounddart.dart [options] files...

Options:

-h, --help          Print this usage information.
-o, --output        Filename for the output file(s), without extension.
                    (defaults to "output")

-e, --export        Limit exported file types. eg "mp3,ogg"
                    (defaults to "")

-r, --samplerate    Sample rate.
                    (defaults to "44100")

-c, --channels      Number of channels (1=mono, 2=stereo).
                    (defaults to "1")

-g, --gap           Length of gap in seconds.
                    (defaults to ".25")

-v, --verbose       Be super chatty.

Examples:

dart sounddart.dart -o audio *.wav # wildcard expansion supported even if your shell doesn't
dart sounddart.dart -e "mp3,ogg" *.wav # only export mp3 and ogg formats
```

SoundDart will then chain all of your sounds together and output SoundSprites in several formats (mp3, ogg, opus, m4a) and a .json atlas (currently supports the format used by [StageXL](http://www.stagexl.org) and [Howler.js](http://goldfirestudios.com/blog/104/howler.js-Modern-Web-Audio-Javascript-Library) in your current working directory:

```
Bomb0 added at 0.00 seconds, length 0.84 seconds
Bomb1 added at 1.09 seconds, length 0.84 seconds
Bomb2 added at 2.19 seconds, length 0.85 seconds
Bomb3 added at 3.28 seconds, length 0.84 seconds
Bomb4 added at 4.37 seconds, length 0.82 seconds
click added at 5.45 seconds, length 0.60 seconds
flag added at 6.30 seconds, length 0.16 seconds
Pop0 added at 6.70 seconds, length 0.20 seconds
Pop1 added at 7.16 seconds, length 0.21 seconds
Pop2 added at 7.61 seconds, length 0.20 seconds
Pop3 added at 8.07 seconds, length 0.19 seconds
Pop4 added at 8.50 seconds, length 0.21 seconds
Pop5 added at 8.96 seconds, length 0.23 seconds
Pop6 added at 9.44 seconds, length 0.19 seconds
Pop7 added at 9.89 seconds, length 0.19 seconds
Pop8 added at 10.33 seconds, length 0.21 seconds
throw added at 10.79 seconds, length 0.14 seconds
unflag added at 11.18 seconds, length 0.31 seconds
win added at 11.75 seconds, length 3.83 seconds
Total sprite length 15.58 seconds, uncompressed size 1342 KB
output.opus created, compressed size 121 KB
output.mp3 created, compressed size 128 KB
output.m4a created, compressed size 248 KB
output.ogg created, compressed size 109 KB
all done - kthxbye!
```
