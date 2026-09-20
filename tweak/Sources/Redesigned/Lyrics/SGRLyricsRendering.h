// A still, covered or background lyrics page does not need a display link.
static inline int SGRLyricsFrameRate(int foreground, int visible, int hasLyrics, int playing, int scrolling, int constrained) {
    if (!foreground || !visible || !hasLyrics || (!playing && !scrolling)) return 0;
    return constrained ? 30 : 60;
}
