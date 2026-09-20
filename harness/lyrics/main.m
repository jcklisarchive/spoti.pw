#import <Foundation/Foundation.h>
#import "Shared/Lyrics/Lyrics.h"
#import "Shared/LyricsSources/LyricsSources.h"

static BOOL enabled = YES;
BOOL SGFlag(NSString *key, BOOL fallback) { return enabled; }

static void check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}

int main(int argc, const char **argv) {
    @autoreleasepool {
        enabled = argc < 2 || strcmp(argv[1], "--off") != 0;
        check([SGRomanizeText(@"你好", @"zh-Hans") isEqualToString:@"nǐ hǎo"], @"Mandarin keeps tone marks");
        check([SGRomanizeText(@"愛", @"zh-Hant") isEqualToString:@"ài"], @"Traditional Mandarin");
        check([SGRomanizeText(@"안녕", @"ko") isEqualToString:@"annyeong"], @"Korean");
        check([SGRomanizeText(@"さよなら", @"ja") isEqualToString:@"sayonara"], @"Japanese kana");
        check([SGRomanizeText(@"你好 Hello!", @"zh") containsString:@"Hello!"], @"Preserve English and punctuation");
        check(!SGRomanizeText(@"Hello! ♪", @"en"), @"No duplicate Latin-only line");
        check(!SGRomanizeText(@"你好", @"unknown"), @"Unknown language is not guessed");
        check(!SGRomanizeText(@"你好", @"yue"), @"Do not apply Mandarin to Cantonese");
        NSString *japanese = SGRomanizeText(@"世界", @"ja");
        check(!japanese || ![japanese containsString:@"shì"], @"Kanji must not become Mandarin");

        NSString *xml = @"<tt xmlns:ttm='http://www.w3.org/ns/ttml#metadata' xmlns:tts='http://www.w3.org/ns/ttml#styling' xml:lang='ja'><body>"
            "<p begin='1s' end='3s'><span begin='1s' end='2s'>君<span tts:ruby='text'>きみ</span></span><span begin='2s' end='3s'>へ</span>"
            "<span ttm:role='x-translation'>To you</span><span ttm:role='x-roman'><span begin='1s' end='2s'>kimi</span> <span begin='2s' end='3s'>e</span></span></p>"
            "<p begin='4s' end='6s'>さよなら<span ttm:role='x-translation'>Goodbye</span><span ttm:role='x-roman'>sayonara</span></p>"
            "<p begin='7s' end='9s'><span begin='7s' end='8s'>君</span><span ttm:role='x-roman'>kimi</span>"
            "<span ttm:role='x-bg'><span begin='8s' end='9s'>ああ</span><span ttm:role='x-roman'>aa</span></span></p>"
            "</body></tt>";
        NSArray<SGKaraokeLine *> *lines = SGTTMLLines(xml);
        check(lines.count == 3, @"Parse fixture lines");
        check([SGKaraokeLineText(lines[0]) isEqualToString:@"君へ"], @"Ruby and translations do not contaminate originals");
        check([lines[0].language isEqualToString:@"ja"], @"Inherit XML language");
        check([SGKaraokeLineText(lines[0].pronunciation) isEqualToString:@"kimi e"], @"Provider pronunciation");
        check(lines[0].pronunciation.words[1].start == 2000, @"Preserve provider word timing");
        check([SGKaraokeLineText(lines[1]) isEqualToString:@"さよなら"], @"Line-timed annotations stay separate");
        check([SGKaraokeLineText(lines[2].backing.pronunciation) isEqualToString:@"aa"], @"Backing pronunciation stays separate");
        check(!SGTTMLLines(@"<tt><p begin='1s'>broken"), @"Reject incomplete XML");
        NSArray *snapshot = SGRomanizedLines(lines);
        check(snapshot[0] != lines[0] && ((SGKaraokeLine *)snapshot[0]).words == lines[0].words, @"Publish a new snapshot, preserve source words");
        check([SGKaraokeLineText(((SGKaraokeLine *)snapshot[0]).pronunciation) isEqualToString:@"kimi e"], @"Provider reading wins over generation");
        check(((SGKaraokeLine *)snapshot[0]).pronunciation.words[1].start == 2000, @"Supplied timing survives normalization");
        SGKaraokeLine *chinese = SGKaraokeEstimatedLines(@[@0, @4000], @[@"你好", @""]).firstObject;
        chinese.language = @"zh-Hans";
        SGKaraokeLine *converted = SGRomanizedLines(@[chinese]).firstObject;
        check([SGKaraokeLineText(converted.pronunciation) isEqualToString:@"nǐ hǎo"] && !chinese.pronunciation,
            @"Generation does not mutate the published source");
        check(converted.start == chinese.start && converted.end == chinese.end, @"Keep original line timing");
        check([SGKaraokeDisplayText(lines[0]) isEqualToString:enabled ? @"kimi e" : @"君へ"], @"Display respects launch setting");

        SGKaraokeLine *longLine = SGPronunciationLine(@"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz e\u0301 😀", 1000, 5000);
        check(longLine.words.count == 4 && longLine.words[1].joined, @"Split long tokens for artist replacement");
        check([SGKaraokeLineText(longLine) isEqualToString:@"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz e\u0301 😀"], @"Do not break combining marks or emoji");
        NSInteger end = 1000;
        for (SGKaraokeWord *word in longLine.words) {
            check(word.start >= end && word.end >= word.start && word.end <= 5000, @"Generated timing stays inside the line");
            end = word.end;
        }
        check(end == 5000, @"Last segment reaches original line end");
        NSLog(@"Lyrics checks passed (%@)", enabled ? @"on" : @"off");
    }
    return 0;
}
