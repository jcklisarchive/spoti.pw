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
