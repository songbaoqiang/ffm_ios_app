//
//  FlyingDBManager.h
//  FlyingEnglish
//
//  Created by vincent sung on 12/22/15.
//  Copyright © 2015 BirdEngish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@interface FlyingDBManager : NSObject

+ (FlyingDBManager*)shareInstance;

//初始化
+(void) prepareDB;

//根据课程更新字典
+ (void) updateBaseDic:(NSString *) lessonID;

//个人数据库用户管理
- (FMDatabaseQueue *) shareUserDBQueue;

//大字典数据库用户管理
- (FMDatabaseQueue *) shareDicDBQueue;

- (void) closeDBQueue;

@end
