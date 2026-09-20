# Lyrics checks

## Build on GitHub

Run **Build IPA from your own Spotify IPA** on `main`, using a decrypted Spotify 9.1.78 IPA URL.
Choose `artifacts` and leave **Include FLEX for on-device view-tree capture** unchecked.
The **Test lyrics** step runs the checks below on the Mac runner before packaging. If it fails,
send the failed step's log. Otherwise download the `spoti.ipa` artifact, extract its IPA and sideload it.

On macOS with Xcode command-line tools, run `sh harness/lyrics/build.sh` from the repo root.
This compiles the production parser and romanization code against Apple's Foundation APIs and
runs it with romanization both on and off. No Spotify IPA or test framework is needed.

Fixtures cover Japanese, Mandarin (both scripts), Korean, mixed English, provider readings,
timed pronunciation, ruby/translation separation, backing vocals, malformed XML, immutable
snapshots, and long pronunciation segments with combining characters and emoji.

Device checks on Spotify 9.1.78:

- Enable Romanized lyrics under Player → Lyrics and restart. Test Japanese, Mandarin, Korean,
  mixed-language, and English tracks with both supplied and generated readings.
- Check original and smaller pronunciation text in the redesigned player and full-screen page;
  check long wrapping, duet alignment, backing vocals, seeking and rapid track changes.
- With artist replacement enabled, verify pronunciation chunks, pause/resume, seeking, and
  restoration of the artist between verses, in the background and on CarPlay.
- Check pronunciation-only current/next lyrics in Live Activity and Dynamic Island.
- Disable romanization and restart: all lyric surfaces should show their original text.
- Open the drawer and settings root repeatedly, scroll and rotate: compare Mod Settings with
  neighboring rows, and confirm no duplicate row, clipped title or growing inset.

Generated pronunciation is approximate. Ambiguous Japanese tokens are left original if Apple's
tokenizer cannot identify a Japanese reading; it must never silently supply a Chinese reading.

Native Spotify bilingual lyrics are outside scope. No FLEX logs, USB capture or Mac are required
for the phone tests; GitHub runs the Apple-runtime checks.

## Heat and SingAlong regression checks

1. Build without FLEX. Compare 10–15 minutes of playback with the prior build under the same
   brightness, connection and charging conditions. Note the iPhone/iOS version and battery drop.
2. Test Home with lyrics closed, visible redesigned lyrics, and locked playback in the car.
   Check that artist-replacement lyrics still advance, pause and seek correctly.
3. Pause while lyrics are visible, scroll them, resume, then repeatedly open/close the player.
   Lyrics should resume smoothly; opening/closing animations should retain ProMotion smoothness.
4. Turn Low Power Mode on and off while viewing lyrics. Expect reduced animation rate while on.
5. Confirm the player footer has only Lyrics, Connect and Queue, in their original positions,
   including landscape. Lyrics must open the inline redesigned lyrics, not a separate page.
6. Close Lyrics and reopen it; pronunciation and seeking should still work.

SingAlong vocal reduction is not implemented in the redesigned lyrics view yet. The previous
microphone was only a navigation shortcut and has been removed. A replacement must invoke
Spotify's actual vocal-reduction action from inside the lyrics view, preserve account/track
eligibility, and reflect Spotify's state. Finding a lyrics URL in the binary does not verify that
action. Device acceptance requires hearing vocals reduce and return without leaving inline lyrics.

`cc harness/lyrics/rendering.c -o /tmp/spoti-rendering-check && /tmp/spoti-rendering-check`
runs the rendering-rate regression checks on Linux as well as macOS.

## Upstream visual harness

# Lyrics harness

The redesign's lyrics view (`Redesigned/Lyrics/SGRKaraokeView.m`) playing a song on a clock of the
harness's own, so lines sung over each other, instrumental breaks, pronunciations and translations can
be looked at on the Mac without the phone. The songs are TTML read by the real `SGTTML.m`, or LRC timed
by the real estimate in `KaraokeTiming.m`.

    ./build-sim.sh                  # this checkout; ./build-sim.sh old builds HEAD's for a before and after, OPT=-O2 optimised
    xcrun simctl install <udid> build/new/LyricsHarness.app
    xcrun simctl launch <udid> com.vojta.lyricsharness.new -song duet -at 114000 -pauseAt 117600
    xcrun simctl io <udid> screenshot shot.png

`stubs.m` stands in for the player and the store: the position runs from `-at` at `-rate` and holds at
`-pauseAt` (for `-holdFor` seconds, then runs on). `main.m` lists every launch argument; the lyrics'
own settings are taken by their keys, e.g. `-spotifyglass.redesign.lyricsPronunciation 1`.

The fixtures are real TTML and LRC with every word swapped for filler of the same script and length
(`fixtures/anonymise.py`), so each keeps its song's timing and structure without its lyrics:

- `duet` two voices and a group over each other, three at once in places (from about 99 s)
- `romanised` Japanese with Apple's word timed pronunciation, backing rows, an 11 s break at 114.7 s
- `translated` Spanish with Apple's English translation and backing rows carried into it
- `both` Korean with both, and English lines the pronunciation leaves out
- `plain` line timed LRC, the words estimated, with a 13 s intro and a break after the first line
- `rtl` (built in) right to left lines among left to right ones, a second voice, a break before the
  last line; `rtlx` the same with translations and a romanization

A real file goes in with `-file /path/song.ttml`: the simulator reads the Mac's paths.

`-perf LABEL` logs the view's per frame cost (its display link's `tick`) every 240 frames; run with
`simctl launch --console` to read it. `-dump 1` prints the lines as read, with their pronunciations and
translations, and quits. `-openMenu 3` opens the pronunciation and translation menu three seconds in,
`-toggleAt 3` switches both over as the menu would, and `-light 1` puts the window in light mode.

A screen recording catches the motion: `simctl io <udid> recordVideo -f run.mp4`, then e.g.
`ffmpeg -i run.mp4 -vf "fps=10,crop=1206:520:0:560,scale=233:-1,tile=12x1" -frames:v 1 strip.png`.

What it does not cover: Spotify's pages around the view (the player's stage is only its size, `-player 1`),
the lyrics arriving late or changing track, and the device's frame pacing.
