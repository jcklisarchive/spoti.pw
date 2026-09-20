# Lyrics checks

## Build on GitHub

Run **Build IPA from your own Spotify IPA** on `main`, using a decrypted Spotify 9.1.78 IPA URL.
Choose `artifacts` and enable **Include FLEX for on-device view-tree capture** for this test build.
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

Native Spotify card/full-screen row integration remains pending a view-tree capture from the
target device. Record the native player, full-screen lyrics, profile drawer and settings root with
`python3 scripts/record-trees.py` from a FLEX-enabled build. The private row classes and sizing
selectors must be verified before adding hooks, as required by `AGENTS.md`.

## Capture the native screens

Turn **Redesigned UI** off in Mod Settings → Appearance, then restart Spotify. On a Mac with the
repo checked out, install the USB tools once with `brew install libimobiledevice libusbmuxd`.
Connect your unlocked iPhone by USB and accept Trust. From the repo root run:

Save any older files from `trees/continuous/` first: continuous capture clears that folder's text files.

```sh
python3 scripts/record-trees.py -C
```

Keep Spotify in the foreground. Open each screen below, then press Enter in the terminal to capture it:

1. The native player scrolled to a visible lyrics card, while a Japanese or Chinese track is playing.
2. That track's full-screen lyrics.
3. The profile drawer showing Mod Settings and adjacent options.
4. Spotify's settings root showing the Mod Settings row.

Exit with `q`. Send the four files from `trees/continuous/`, noting which number is which screen.
Also include the Spotify/iOS versions, track links, and screenshots or a short recording of any
alignment, timing or pronunciation problem. You can start with screenshots if USB capture is
not available; the native row hooks will still need the text captures to finish.
