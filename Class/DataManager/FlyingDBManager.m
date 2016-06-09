//
//  FlyingDBManager.m
//  FlyingEnglish
//
//  Created by vincent sung on 12/22/15.
//  Copyright © 2015 BirdEngish. All rights reserved.
//

#import "FlyingDBManager.h"

#import "shareDefine.h"

#import "FlyingLessonDAO.h"
#import "FlyingLessonData.h"
#import "FlyingItemData.h"
#import "FlyingItemDao.h"
#import "FlyingItemParser.h"

#import "FileHash.h"
#import "FlyingMediaVC.h"
#import "ReaderViewController.h"

#import "NSString+FlyingExtention.h"
#import "FlyingDataManager.h"
#import "FlyingFileManager.h"
#import "FlyingDownloadManager.h"


@interface FlyingDBManager ()
{
    //loacal DB managemnet
    FMDatabaseQueue *_userDBQueue;
    FMDatabaseQueue *_dicDBQueue;
}
@end

@implementation FlyingDBManager

+ (FlyingDBManager*)shareInstance
{
    static FlyingDBManager* instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

+(void) prepareDB
{
    // 准备英文字典数据库
    [FlyingDBManager prepareDictionary];
    
    //准备用户数据库
//    [FlyingDBManager prepareUserDataBase];
}

// 准备英文字典
+ (void)prepareDictionary
{
    //判断是否后台加载基础字典（MP3+DB）
    NSString  * newDicpath = [[FlyingFileManager getMyDictionaryDir] stringByAppendingPathComponent:BC_FileName_DicBase];
    
    //分享目录如果没有就创建一个
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:newDicpath])
    {
        [[FlyingDownloadManager shareInstance] startDownloadShareData];
    }
}

//准备用户数据库
//+ (void)prepareUserDataBase
//{
//    //dbPath： 数据库路径，在dbDir中。
//    NSString *dbPath = [[FlyingFileManager getMyUserDataDir] stringByAppendingPathComponent:BC_FileName_userBase];
//    
//    //如果有直接打开，没有用户纪录文件就从安装文件复制一个用户模板
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if (![fileManager fileExistsAtPath:dbPath]){
//        
//        NSString *soureDbpath = [[NSBundle mainBundle] pathForResource:KUserDBResource ofType:KDBType];
//        NSError* error=nil;
//        [fileManager copyItemAtPath:soureDbpath toPath:dbPath error:&error ];
//        if (error!=nil) {
//            NSLog(@"%@", error);
//            NSLog(@"%@", [error userInfo]);
//        }
//    }
//}

//根据课程更新字典
+ (void) updateBaseDic:(NSString *) lessonID
{
    NSString * lessonDir = [FlyingFileManager getMyLessonDir:lessonID];
    
    NSString * fileName = [lessonDir stringByAppendingPathComponent:KLessonDicXMLFile];
    
    FlyingItemParser * parser= [FlyingItemParser alloc];
    [parser SetData:[NSData dataWithContentsOfFile:fileName]];
    
    FlyingItemDao * dao= [[FlyingItemDao alloc] init];
    parser.completionBlock = ^(NSArray *itemList, NSInteger allRecordCount)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [itemList enumerateObjectsUsingBlock:^(FlyingItemData  *item, NSUInteger idx, BOOL *stop) {
                
                [dao insertWithData:item];
            }];
        });
    };
    
    parser.failureBlock = ^(NSError *error)
    {
        
        NSLog(@"word xml  失败！");
    };
    
    [parser parse];
}

+ (BOOL) isTableOK:(NSString *)tableName withDB:(FMDatabase *)db
{
    BOOL isOK = NO;
    
    FMResultSet *rs = [db executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
    while ([rs next])
    {
        NSInteger count = [rs intForColumn:@"count"];
        
        if (0 == count)
        {
            isOK =  NO;
        }
        else
        {
            isOK = YES;
        }
    }
    [rs close];
    
    return isOK;
}


- (FMDatabaseQueue *) shareUserDBQueue
{
    if (!_userDBQueue) {
        
        //dbPath： 数据库路径，在dbDir中。
        NSString *dbPath = [[FlyingFileManager getMyUserDataDir] stringByAppendingPathComponent:BC_FileName_userBase];
        
        //如果有直接打开，没有用户纪录文件就从安装文件复制一个用户模板
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:dbPath]){
            
//            [FlyingDBManager prepareUserDataBase];
        }
        
        _userDBQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [self CreateUserTable];
    }
    
    return _userDBQueue;
}

//创建用户存储表
-(void)CreateUserTable
{
    if (_userDBQueue)
    {
        [_userDBQueue inDatabase:^(FMDatabase *db){
            
            if (![FlyingDBManager isTableOK:BC_lesson_TableName withDB:db])
            {
                NSString *createTableSQL = @"CREATE TABLE FFM_PUB_LESSON (BELESSONID VARCHAR(32) PRIMARY KEY  NOT NULL ,BETITLE varchar(20),BEDESC varchar(1600),BEIMAGEURL varchar(100),BECONTENTURL varchar(100),BESUBURL varchar(100),BEDURATION DOUBLE,BESTARTTIME DOUBLE,BEPRICE INTEGER,BEDLPERCENT DOUBLE,BEDLSTATE BOOLEAN,BEOFFICIAL BOOLEAN,BEPROURL VARCHAR(100),BESHAREURL VARCHAR(100), BECONTENTTYPE VARCHAR(10), BEDOWNLOADTYPE VARCHAR(10), BETAG VARCHAR(100), BEWEBURL VARCHAR(100), BEISBN VARCHAR(32), BERELATIVEURL VARCHAR(100))";
                [db executeUpdate:createTableSQL];
            }
            if (![FlyingDBManager isTableOK:BC_statistic_TableName withDB:db])
            {
                NSString *createTableSQL = @"CREATE TABLE FFM_STATISTIC (BEUSERID varchar(40) PRIMARY KEY  NOT NULL ,BETOUCHCOUNT INTEGER NOT NULL  DEFAULT (0) ,BEMONEYCOUNT INTEGER NOT NULL  DEFAULT (0) ,BEGIFTCOUNT INTEGER NOT NULL  DEFAULT (0) ,BETIMES INTEGER,BEQRCOUNT INTEGER NOT NULL  DEFAULT (0) ,BETIMESTAMP VARCHAR(50) NOT NULL  DEFAULT (0) )";
                [db executeUpdate:createTableSQL];
            }
            
            if (![FlyingDBManager isTableOK:BC_taskword_TableName withDB:db])
            {
                NSString *createTableSQL = @"CREATE TABLE FFM_TASK_WORD (BEUSERID varchar(40) NOT NULL ,BEWORD VARCHAR(32) NOT NULL  DEFAULT (null) ,BESENTENCEID VARCHAR(32),BELESSONID VARCHAR(32),BETIME INTEGER,PRIMARY KEY (BEUSERID,BEWORD) )";
                [db executeUpdate:createTableSQL];
            }
        }];
    }
}


- (void) closeUserDBQueue
{
    if (_userDBQueue) {
        
        [_userDBQueue close];
        _userDBQueue=nil;
    }
}

- (FMDatabaseQueue *) shareDicDBQueue
{
    if (!_dicDBQueue) {
        
        NSString * path        =  [[FlyingFileManager getMyDictionaryDir] stringByAppendingPathComponent:BC_FileName_DicBase];
        
        //如果没有
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path]){
            
            [FlyingDBManager prepareDictionary];
            
            return nil;
        }
        else{
            
            _dicDBQueue = [FMDatabaseQueue databaseQueueWithPath:path];
        }
    }
    
    return _dicDBQueue;
}

- (void) closeDicDBQueue
{
    if (_dicDBQueue) {
        
        [_dicDBQueue close];
        _dicDBQueue=nil;
    }
}

- (void) closeDBQueue
{
    [self closeUserDBQueue];
    [self closeDicDBQueue];
}

@end
