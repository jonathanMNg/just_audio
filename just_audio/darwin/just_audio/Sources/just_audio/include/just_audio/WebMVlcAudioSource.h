#import "IndexedAudioSource.h"
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <MobileVLCKit/MobileVLCKit.h>
#else
#import <VLCKit/VLCKit.h>
#endif

@class AudioPlayer;

@interface WebMVlcAudioSource : IndexedAudioSource <VLCMediaPlayerDelegate>

@property (readonly, nonatomic) NSString *uri;
@property (readonly, nonatomic) NSDictionary *headers;
@property (readonly, nonatomic) VLCMediaPlayer *vlcPlayer;

- (instancetype)initWithId:(NSString *)sid uri:(NSString *)uri headers:(NSDictionary *)headers audioPlayer:(AudioPlayer *)audioPlayer;
- (void)prepare;
- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(CMTime)time;
- (void)setVolume:(float)volume;
- (void)setRate:(float)rate;
- (CMTime)currentTime;
- (CMTime)duration;

@end
