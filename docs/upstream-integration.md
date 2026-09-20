# Upstream integration — 2026-09-20

## Full audio and lyrics integration

The feature set reviewed through `ac3c4b7` is now merged, including JamesDSP, its effects page,
expanded haptics, timed pronunciation/translation, overlapping voices and instrumental-break dots.
The fixes-only notes below describe the earlier checkpoint, not the current feature set.

Your generated Japanese/Mandarin/Korean pronunciation remains available with Romanized lyrics on.
Existing users with that setting enabled see pronunciation by default unless they explicitly hide it
in the new in-lyrics pronunciation/translation menu. Provider readings take precedence over generated
readings. Original lyrics and the Lyrics/Connect/Queue footer remain in place; settings-row alignment,
lock-screen pronunciation, and background/paused rendering limits are retained.

JamesDSP remains off by default. Turn it on under Mod Settings → Audio effects to test effects;
audio processing consumes additional power while enabled. The actual Japanese Spotify SingAlong
vocal-reduction action is still unimplemented: JamesDSP is not a substitute for Spotify's karaoke
service, and no microphone navigation shortcut has been added.

The pre-feature-merge checkpoint is `9359e34`, also kept locally as
`backup/pre-full-upstream-2026-09-20`. Build without FLEX and retain your previous IPA.
In addition to the checks below, test the in-lyrics pronunciation/translation menu and text-size
ordering, simultaneous duet lines, break dots, pause/seek/track changes, and Audio effects on/off.
Check an audible effect such as EQ at moderate volume, then disable the master switch and confirm
normal sound, including after connecting and disconnecting CarPlay.

`Check lyrics and audio integration` runs the Foundation parser/pronunciation tests, renderer syntax
check with the current iOS SDK, and JamesDSP's asset-free bypass/restart/sample-rate/reset checks
on GitHub's Mac runner. These do not replace device testing or a full IPA build.

## Earlier fixes-only checkpoint

Selectively integrated from `skopevoj/spoti.pw`, reviewed through `ac3c4b7`:

- `61bd8ee`: right-to-left lyrics and Live Activity alignment.
- `4e5c576`: Library header controls no longer overlap its title on first open.
- `4ae246f`: album and playlist Add buttons appear on first open.
- `1b83288`: mod glass stays dark when iOS uses Light Mode.
- `927b1c6`: bottom-bar spacing under Offline/Private Session and on home-button phones.

The pre-integration version is `49174ae`, also retained locally as
`backup/pre-upstream-fixes-2026-09-20`. This is a fixes-only integration, not a full upstream sync.
JamesDSP, expanded haptics, the larger lyrics/translation rewrite, and funding changes were not
included. Existing pronunciation, lock-screen lyrics, reduced rendering work, Mod Settings
alignment, and the three-button player footer are preserved. The lyrics conflict was resolved
by retaining accessibility activation alongside upstream's updated initializer documentation.

## Phone checks

Build `main` using the existing GitHub IPA workflow with FLEX unchecked. Keep your old IPA to
reinstall if needed; do not delete the app or reset its settings for this test.

1. On first opening Library, check the title and search/add/avatar controls do not overlap.
2. Open an album and playlist you have not opened this session; check Add appears and works.
3. Switch iOS between Light and Dark Mode; check the tabs, mini-player and lyrics glass stay dark.
4. Enable Offline or Private Session; check the mini-player and tab bar do not overlap, then disable it.
5. Check Japanese romaji and Chinese pinyin, seeking, pause/resume, and the original Lyrics/Connect/Queue
   footer. If available, check Arabic/Hebrew lyrics align and highlight right-to-left.
6. Check lock-screen lyrics and background/CarPlay playback as before; compare warmth under the same conditions.

Linux checks: layer boundaries, rendering policy regression, diff whitespace, and available iOS SDK
syntax checks. Full Apple builds and simulator/device behavior still need verification. The local
iOS 16.5 SDK cannot check the existing iOS 26 APIs in `BarTransition.x` and `SearchCards.x`;
the same errors occur before integration. Upstream's Library, tab-bar, album and playlist simulator
harnesses are included but were not run here. The existing GitHub workflow runs the pronunciation/parser tests.
