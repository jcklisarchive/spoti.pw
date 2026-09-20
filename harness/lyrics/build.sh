#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p build
cc rendering.c -o build/rendering
build/rendering
xcrun clang -fobjc-arc -fblocks -O2 -I ../../tweak/Sources -framework Foundation -framework CoreFoundation \
    pronunciation.m ../../tweak/Sources/Shared/Lyrics/KaraokeTiming.m \
    ../../tweak/Sources/Shared/Lyrics/Romanization.m \
    ../../tweak/Sources/Shared/LyricsSources/SGTTML.m \
    ../../tweak/Sources/Shared/AdBlock/Protobuf.m -o build/lyrics
build/lyrics
build/lyrics --off
