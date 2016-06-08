//
//  FlyingNavigationController.m
//  FlyingEnglish
//
//  Created by vincent on 3/15/15.
//  Copyright (c) 2015 vincent sung. All rights reserved.
//

#import "FlyingNavigationController.h"
#import "shareDefine.h"


@interface FlyingNavigationController()
@end

@implementation FlyingNavigationController

- (id)init
{
    if ((self = [super init]))
    {
        // Custom initialization
    }
    return self;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
