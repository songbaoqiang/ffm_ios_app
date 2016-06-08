//
//  FlyingMediaVC.h
//  FlyingEnglish
//
//  Created by vincent sung on 11/26/15.
//  Copyright © 2015 BirdEngish. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FlyingAILearningView.h"
#import "FlyingSubTitle.h"


@protocol FlyingMediaVCDelegate<NSObject>

@required
- (void)doSwitchToFullScreen:(BOOL) toFullScreen;
- (void)playGameForSub:(FlyingSubTitle*)subtitle GameIndex:(NSInteger) gameIndex;
- (void)endMagicGameByPlayer:(BOOL) byPlayer;

@end

@class FlyingPubLessonData;

@interface FlyingMediaVC : UIViewController<FlyingAILearningViewDelegate,UIWebViewDelegate>

@property (strong, nonatomic) FlyingPubLessonData * thePubLesson;

@property (nonatomic,weak,readwrite) id <FlyingMediaVCDelegate> delegate;

@property (assign,nonatomic) NSTimeInterval  initialPlaybackTime;

- (void) play;
- (void) pause;

- (void) updateSubtitleWith:(NSMutableAttributedString *) styleSentence;
- (void) setMagicGameAt:(NSInteger) index;
- (void) endMagicGame;


- (void) dismiss;

+ (UIImage*) thumbnailImageForMp3:(NSURL *)mp3fURL;
+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;


@end
