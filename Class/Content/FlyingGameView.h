//
//  FlyingGameView.h
//  FlyingEnglish
//
//  Created by vincent sung on 29/5/2016.
//  Copyright © 2016 BirdEngish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlyingSubTitle.h"
#import "FlyingGameTextView.h"

@protocol FlyingGameViewDelegate <NSObject>

@optional
- (void)setMagicGameAt:(NSInteger) index;
- (void)endMagicGameByPlayer:(BOOL) byPlayer;

@end

@interface FlyingGameView : UIView

@property (strong, nonatomic) IBOutlet FlyingGameTextView *topTextView;
@property (strong, nonatomic) IBOutlet FlyingGameTextView *bottomTextView;

@property(nonatomic,assign) id<FlyingGameViewDelegate> delegate;

+ (FlyingGameView*) gameView;

-(void) loadSubtitle:(FlyingSubTitle *) subtitle;

-(void) beginGameAtIndex:(NSInteger) index;

@end
