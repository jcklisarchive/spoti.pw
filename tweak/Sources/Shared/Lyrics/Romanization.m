#import "Lyrics.h"
#import "Core/SGPrefs.h"
#import <CoreFoundation/CoreFoundation.h>

BOOL SGRomanizedLyricsEnabled(void) {
    static BOOL enabled;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ enabled = SGFlag(SGKeyRomanizedLyrics, NO); });
    return enabled;
}

static BOOL matches(NSString *text, NSString *pattern) {
    return text.length && [text rangeOfString:pattern options:NSRegularExpressionSearch].location != NSNotFound;
}

static NSString *languageOf(NSString *text) {
    if (matches(text, @"[\\p{Hiragana}\\p{Katakana}]")) return @"ja";
    if (matches(text, @"\\p{Hangul}")) return @"ko";
    return CFBridgingRelease(CFStringTokenizerCopyBestStringLanguage((__bridge CFStringRef)text,
                                                                   CFRangeMake(0, text.length)));
}

NSString *SGRomanizeText(NSString *text, NSString *language) {
    if (!text.length || !matches(text, @"[\\p{Han}\\p{Hiragana}\\p{Katakana}\\p{Hangul}]")) return nil;
    NSString *reading = nil;
    if ([language hasPrefix:@"zh"] && ![language hasPrefix:@"zh-yue"]) {
        reading = [text stringByApplyingTransform:NSStringTransformMandarinToLatin reverse:NO];
    } else if ([language hasPrefix:@"ko"]) {
        reading = [text stringByApplyingTransform:@"Hangul-Latin" reverse:NO];
    } else if ([language hasPrefix:@"ja"]) {
        CFLocaleRef locale = CFLocaleCreate(NULL, CFSTR("ja"));
        CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(NULL, (__bridge CFStringRef)text,
            CFRangeMake(0, text.length), kCFStringTokenizerUnitWordBoundary | kCFStringTokenizerAttributeLatinTranscription, locale);
        CFRelease(locale);
        if (!tokenizer) return nil;
        NSMutableString *result = [NSMutableString string];
        NSUInteger end = 0;
        BOOL complete = YES;
        BOOL previousReading = NO;
        while (CFStringTokenizerAdvanceToNextToken(tokenizer) != kCFStringTokenizerTokenNone) {
            CFRange range = CFStringTokenizerGetCurrentTokenRange(tokenizer);
            NSString *token = [text substringWithRange:NSMakeRange(range.location, range.length)];
            NSString *gap = [text substringWithRange:NSMakeRange(end, range.location - end)];
            [result appendString:gap];
            NSString *latin = nil;
            BOOL isReading = matches(token, @"[\\p{Han}\\p{Hiragana}\\p{Katakana}]");
            if (matches(token, @"\\p{Han}")) {
                // WordBoundary honors the Japanese locale; UnitWord ignores it and can yield pinyin.
                latin = CFBridgingRelease(CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription));
                if (!latin.length) { complete = NO; break; }
            } else {
                latin = [token stringByApplyingTransform:@"Hiragana-Latin; Katakana-Latin" reverse:NO];
            }
            if (!latin.length) { complete = NO; break; }
            if (previousReading && isReading && !gap.length) [result appendString:@" "];
            [result appendString:latin];
            previousReading = isReading;
            end = range.location + range.length;
        }
        if (complete) [result appendString:[text substringFromIndex:end]];
        CFRelease(tokenizer);
        reading = complete ? result : nil;
    }
    // Mixed-language or unrecognized text remains original rather than showing a partial reading.
    if (!reading.length || [reading isEqualToString:text] || matches(reading, @"[\\p{Han}\\p{Hiragana}\\p{Katakana}\\p{Hangul}]")) return nil;
    return [reading precomposedStringWithCanonicalMapping];
}

SGKaraokeLine *SGPronunciationLine(NSString *text, NSInteger start, NSInteger end) {
    if (!text.length) return nil;
    SGKaraokeLine *line = [SGKaraokeLine new];
    line.start = start;
    line.end = MAX(start, end);
    NSMutableArray<SGKaraokeWord *> *words = [NSMutableArray array];
    // Keep punctuation and long unbroken words, but cap each piece at 30 composed characters so
    // the system artist field can cycle through it without splitting a tone mark or an emoji.
    for (NSString *token in [text componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]) {
        __block NSMutableString *piece = [NSMutableString string];
        __block NSUInteger length = 0;
        __block BOOL joined = NO;
        [token enumerateSubstringsInRange:NSMakeRange(0, token.length) options:NSStringEnumerationByComposedCharacterSequences
            usingBlock:^(NSString *part, NSRange a, NSRange b, BOOL *stop) {
                if (length == 30) {
                    SGKaraokeWord *word = [SGKaraokeWord new];
                    word.text = piece; word.joined = joined;
                    [words addObject:word];
                    piece = [NSMutableString string]; length = 0; joined = YES;
                }
                [piece appendString:part]; length++;
            }];
        if (piece.length) {
            SGKaraokeWord *word = [SGKaraokeWord new];
            word.text = piece; word.joined = joined;
            [words addObject:word];
        }
    }
    NSUInteger total = 0, offset = 0;
    for (SGKaraokeWord *word in words) total += word.text.length;
    // ponytail: generated pronunciation has line timing only; use provider word timings when supplied.
    for (SGKaraokeWord *word in words) {
        word.start = start + (NSInteger)((double)(line.end - start) * offset / MAX(total, 1));
        offset += word.text.length;
        word.end = start + (NSInteger)((double)(line.end - start) * offset / MAX(total, 1));
    }
    line.words = words;
    return words.count ? line : nil;
}

static SGKaraokeLine *convertLine(SGKaraokeLine *source, NSString *language) {
    SGKaraokeLine *line = [SGKaraokeLine new];
    line.words = source.words;
    line.start = source.start; line.end = source.end;
    line.voice = source.voice; line.align = source.align;
    NSString *text = SGKaraokeLineText(source);
    NSString *local = matches(text, @"[\\p{Hiragana}\\p{Katakana}\\p{Hangul}]") ? languageOf(text) : language;
    line.language = source.language ?: local;
    if (source.pronunciation.words.count) {
        // Keep supplied word times, splitting only overlong words for the system artist field.
        SGKaraokeLine *reading = [SGKaraokeLine new];
        reading.start = source.pronunciation.start; reading.end = source.pronunciation.end;
        NSMutableArray *words = [NSMutableArray array];
        for (SGKaraokeWord *word in source.pronunciation.words) {
            SGKaraokeLine *pieces = SGPronunciationLine(word.text, word.start, word.end);
            pieces.words.firstObject.joined = word.joined;
            [words addObjectsFromArray:pieces.words ?: @[]];
        }
        reading.words = words;
        line.pronunciation = reading;
    } else {
        line.pronunciation = SGPronunciationLine(SGRomanizeText(text, line.language), line.start, line.end);
    }
    if ([SGKaraokeLineText(line.pronunciation) isEqualToString:text]) line.pronunciation = nil;
    if (source.backing) line.backing = convertLine(source.backing, line.language);
    return line;
}

NSArray<SGKaraokeLine *> *SGRomanizedLines(NSArray<SGKaraokeLine *> *lines) {
    NSMutableString *song = [NSMutableString string];
    for (SGKaraokeLine *line in lines) [song appendFormat:@"%@\n", SGKaraokeLineText(line)];
    NSString *language = languageOf(song);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:lines.count];
    BOOL hasReading = NO;
    for (SGKaraokeLine *line in lines) {
        SGKaraokeLine *converted = convertLine(line, language);
        hasReading |= line.pronunciation != nil || line.backing.pronunciation != nil ||
            converted.pronunciation.words.count > 0 || converted.backing.pronunciation.words.count > 0;
        [result addObject:converted];
    }
    return hasReading ? result : lines;
}

SGKaraokeLine *SGKaraokeDisplayLine(SGKaraokeLine *line) {
    return SGRomanizedLyricsEnabled() && line.pronunciation.words.count ? line.pronunciation : line;
}

NSString *SGKaraokeDisplayText(SGKaraokeLine *line) {
    return SGKaraokeLineText(SGKaraokeDisplayLine(line));
}
