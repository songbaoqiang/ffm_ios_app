//
//  UIDevice+SpeedCategory.m
//  FlyingEnglish
//
//  Created by BE_Air on 12/5/13.
//  Copyright (c) 2013 vincent sung. All rights reserved.
//

#import "UIDevice+SpeedCategory.h"
#import <sys/sysctl.h> // for sysctlbyname


@implementation UIDevice (SpeedCategory)

- (int)speedCategory
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    
    NSString *currentMachine = @(answer);
    free(answer);
    
    if ([currentMachine hasPrefix:@"iPhone2"] || [currentMachine hasPrefix:@"iPhone3"] || [currentMachine hasPrefix:@"iPad1"] || [currentMachine hasPrefix:@"iPod3"] || [currentMachine hasPrefix:@"iPod4"]) {
        // iPhone 3GS, iPhone 4, first gen. iPad, 3rd and 4th generation iPod touch
        return 1;
    } else if ([currentMachine hasPrefix:@"iPhone4"] || [currentMachine hasPrefix:@"iPad3,1"] || [currentMachine hasPrefix:@"iPad3,2"] || [currentMachine hasPrefix:@"iPad3,3"] || [currentMachine hasPrefix:@"iPod4"] || [currentMachine hasPrefix:@"iPad2"] || [currentMachine hasPrefix:@"iPod5"]) {
        // iPhone 4S, iPad 2 and 3, iPod 4 and 5
        return 2;
    } else {
        // iPhone 5, iPad 4
        return 3;
    }
}


@end
