#include <assert.h>
#include "../../tweak/Sources/Redesigned/Lyrics/SGRLyricsRendering.h"

int main(void) {
    assert(SGRLyricsFrameRate(1, 1, 1, 1, 0, 0) == 60);
    assert(SGRLyricsFrameRate(1, 1, 1, 1, 0, 1) == 30);
    assert(SGRLyricsFrameRate(0, 1, 1, 1, 0, 0) == 0);
    assert(SGRLyricsFrameRate(1, 0, 1, 1, 0, 0) == 0);
    assert(SGRLyricsFrameRate(1, 1, 0, 1, 0, 0) == 0);
    assert(SGRLyricsFrameRate(1, 1, 1, 0, 0, 0) == 0);
    assert(SGRLyricsFrameRate(1, 1, 1, 0, 1, 0) == 60);
    return 0;
}
