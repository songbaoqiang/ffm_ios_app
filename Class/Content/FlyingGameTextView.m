//
//  FlyingGameTextView.m
//  FlyingEnglish
//
//  Created by vincent sung on 31/5/2016.
//  Copyright © 2016 BirdEngish. All rights reserved.
//

#import "FlyingGameTextView.h"
#import "shareDefine.h"
#import "D3View.h"

@interface FlyingGameTextView()


@end


@implementation FlyingGameTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareForMagic];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self prepareForMagic];
    }
    return self;
}

- (void)awakeFromNib
{
    [self prepareForMagic];
}

-(void) prepareForMagic
{
    self.userInteractionEnabled=YES;
    self.multipleTouchEnabled=NO;
    self.backgroundColor=[UIColor blackColor];
    self.textColor= [UIColor whiteColor];
    self.textAlignment=NSTextAlignmentCenter;
    
    self.font = [UIFont systemFontOfSize:KNormalFontSize];
    
    self.editable=NO;
    self.selectable=NO;
    
    self.layer.borderWidth = 1.0;

    [self.layer setCornerRadius:10];
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(4, 4);
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowRadius = 2.0;
}

@end
