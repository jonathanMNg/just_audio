#import "./include/just_audio/WebMVlcAudioSource.h"
#import "./include/just_audio/AudioPlayer.h"
#import "./include/just_audio/IndexedPlayerItem.h"

@implementation WebMVlcAudioSource {
    NSString *_uri;
    NSDictionary *_headers;
    VLCMediaPlayer *_vlcPlayer;
    AudioPlayer *_audioPlayer;
    BOOL _isPreapred;
    CMTime _duration;
}

- (instancetype)initWithId:(NSString *)sid uri:(NSString *)uri headers:(NSDictionary *)headers audioPlayer:(AudioPlayer *)audioPlayer {
    self = [super initWithId:sid];
    NSAssert(self, @"super init cannot be nil");
    _uri = uri;
    _headers = headers != (id)[NSNull null] ? headers : nil;
    _audioPlayer = audioPlayer;
    _isPreapred = NO;
    _duration = kCMTimeInvalid;
    
    // Create VLC player
    _vlcPlayer = [[VLCMediaPlayer alloc] init];
    _vlcPlayer.delegate = self;
    
    // Configure for audio-only playback
    _vlcPlayer.videoAspectRatio = nil;
    
    return self;
}

- (NSString *)uri {
    return _uri;
}

- (NSDictionary *)headers {
    return _headers;
}

- (VLCMediaPlayer *)vlcPlayer {
    return _vlcPlayer;
}

- (void)prepare {
    if (_isPreapred) return;
    
    VLCMedia *media;
    
    if ([_uri hasPrefix:@"http://"] || [_uri hasPrefix:@"https://"]) {
        // URL-based media
        NSURL *url = [NSURL URLWithString:_uri];
        media = [VLCMedia mediaWithURL:url];
        
        // Add headers if provided
        if (_headers && _headers.count > 0) {
            NSMutableArray *options = [NSMutableArray array];
            for (NSString *key in _headers) {
                NSString *value = _headers[key];
                [options addObject:[NSString stringWithFormat:@":http-user-agent=%@", value]];
            }
            [media addOptions:options];
        }
    } else if ([_uri hasPrefix:@"file://"]) {
        // File-based media
        NSURL *url = [NSURL URLWithString:_uri];
        media = [VLCMedia mediaWithURL:url];
    } else {
        // Local file path
        media = [VLCMedia mediaWithPath:_uri];
    }
    
    _vlcPlayer.media = media;
    _isPreapred = YES;
}

- (void)play {
    [self prepare];
    [_vlcPlayer play];
}

- (void)pause {
    [_vlcPlayer pause];
}

- (void)stop {
    [_vlcPlayer stop];
}

- (void)seekToTime:(CMTime)time {
    if (CMTIME_IS_VALID(_duration) && CMTIME_IS_VALID(time)) {
        float position = CMTimeGetSeconds(time) / CMTimeGetSeconds(_duration);
        _vlcPlayer.position = position;
    }
}

- (void)setVolume:(float)volume {
    _vlcPlayer.audio.volume = (int)(volume * 100);
}

- (void)setRate:(float)rate {
    _vlcPlayer.rate = rate;
}

- (CMTime)currentTime {
    VLCTime *vlcTime = _vlcPlayer.time;
    if (vlcTime && vlcTime.intValue > 0) {
        return CMTimeMake(vlcTime.intValue * 1000, 1000000); // Convert ms to CMTime
    }
    return kCMTimeZero;
}

- (CMTime)duration {
    if (CMTIME_IS_VALID(_duration)) {
        return _duration;
    }
    
    VLCTime *vlcDuration = _vlcPlayer.media.length;
    if (vlcDuration && vlcDuration.intValue > 0) {
        _duration = CMTimeMake(vlcDuration.intValue * 1000, 1000000); // Convert ms to CMTime
        return _duration;
    }
    
    return kCMTimeInvalid;
}

// MARK: - AudioSource protocol methods

- (int)buildSequence:(NSMutableArray *)sequence treeIndex:(int)treeIndex {
    [sequence addObject:self];
    return treeIndex + 1;
}

- (void)findById:(NSString *)sourceId matches:(NSMutableArray<AudioSource *> *)matches {
    [super findById:sourceId matches:matches];
}

- (IndexedPlayerItem *)playerItem {
    // WebM sources don't use AVPlayerItem, but we need to return something
    // for compatibility. Return a dummy item that won't be used.
    static IndexedPlayerItem *dummyItem = nil;
    if (!dummyItem) {
        NSURL *silentURL = [NSURL URLWithString:@"data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhEkOJ1/ZvK0cEFlCNZQIaZ4QkMi1p1IU3iVUaJHJJSkmL8x4bz1r1r/tQaXqA6Wk+9ELCyE6W2/DBWkjN3CaNeU5Ks1Lmf7UXZ9aqmPg="];
        dummyItem = [[IndexedPlayerItem alloc] initWithURL:silentURL];
    }
    return dummyItem;
}

// MARK: - VLCMediaPlayerDelegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification {
    VLCMediaPlayer *player = (VLCMediaPlayer *)aNotification.object;
    if (player != _vlcPlayer) return;
    
    // Notify the AudioPlayer about state changes
    if ([_audioPlayer respondsToSelector:@selector(onVlcPlayerStateChanged:)]) {
        [_audioPlayer performSelector:@selector(onVlcPlayerStateChanged:) withObject:self];
    }
}

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    VLCMediaPlayer *player = (VLCMediaPlayer *)aNotification.object;
    if (player != _vlcPlayer) return;
    
    // Notify the AudioPlayer about time changes
    if ([_audioPlayer respondsToSelector:@selector(onVlcPlayerTimeChanged:)]) {
        [_audioPlayer performSelector:@selector(onVlcPlayerTimeChanged:) withObject:self];
    }
}

- (void)dealloc {
    [_vlcPlayer stop];
    _vlcPlayer.delegate = nil;
    _vlcPlayer = nil;
}

@end
