//
//  FlyingAccountVC.m
//  FlyingEnglish
//
//  Created by vincent on 5/25/15.
//  Copyright (c) 2015 BirdEngish. All rights reserved.
//

#import "FlyingAccountVC.h"
#import "UIColor+RCColor.h"
#import "iFlyingAppDelegate.h"
#import "FlyingProfileVC.h"
#import "FlyingNavigationController.h"
#import "FlyingHttpTool.h"
#import "UICKeyChainStore.h"
#import "FlyingPickColorVCViewController.h"
#import <RongIMKit/RCIM.h>
#import "shareDefine.h"
#import "NSString+FlyingExtention.h"
#import <UIImageView+AFNetworking.h>
#import "AFHttpTool.h"
#import "FlyingLessonDAO.h"
#import "FlyingLessonData.h"
#import "MKStoreKit.h"
#import "FlyingDataManager.h"
#import "FlyingHttpTool.h"
#import "FlyingConversationListVC.h"
#import "FlyingDataManager.h"
#import "FlyingWebViewController.h"
#import "FlyingUserRightData.h"
#import "FlyingReviewVC.h"
#import "FlyingConversationVC.h"
#import "FlyingTaskWordDAO.h"
#import "FlyingBuyVC.h"
#import "FlyingImageTextCell.h"
#import "FlyingScanViewController.h"
#import "FlyingSearchViewController.h"
#import "FlyingGroupVC.h"
#import "FlyingSoundPlayer.h"
#import <Toast/UIView+Toast.h>
#import "WSCoachMarksView.h"

@interface FlyingAccountVC ()<UITableViewDataSource,
                                UITableViewDelegate>
{
    NSInteger _wordCount;
}

@property (strong, nonatomic) UITableView        *tableView;

@property (strong, nonatomic) FlyingImageTextCell *myProfileCell;
@property (strong, nonatomic) FlyingImageTextCell *myWordsCell;
@property (strong, nonatomic) FlyingImageTextCell *serviceCell;

@property (strong, nonatomic) WSCoachMarksView  *coachMarksView;

@end

@implementation FlyingAccountVC

- (id)init
{
    if ((self = [super init]))
    {
        // Custom initialization
        self.hidesBottomBarWhenPushed = NO;
        
        self.domainID = [FlyingDataManager getAppData].appID;
        self.domainType = BC_Domain_Business;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    //标题
    self.title = NSLocalizedString(@"Account",nil);
    //self.edgesForExtendedLayout = UIRectEdgeAll;
    
    UIButton* sacanButton= [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [sacanButton setBackgroundImage:[UIImage imageNamed:@"scan"] forState:UIControlStateNormal];
    [sacanButton addTarget:self action:@selector(doScan) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* scanBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:sacanButton];

    self.navigationItem.rightBarButtonItem= scanBarButtonItem;
    
    if (!self.tableView)
    {
        self.tableView = [[UITableView alloc] initWithFrame: CGRectMake(0.0f, 0, CGRectGetWidth(self.view.frame),CGRectGetHeight(self.view.frame)-64) style:UITableViewStylePlain];
        
        //必须在设置delegate之前
        [self.tableView registerNib:[UINib nibWithNibName:@"FlyingImageTextCell" bundle:nil]
             forCellReuseIdentifier:@"FlyingImageTextCell"];
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.tableView.backgroundColor = [UIColor clearColor];
        //self.tableView.separatorColor = [UIColor clearColor];
        
        NSInteger bottom = [[NSUserDefaults standardUserDefaults] integerForKey:KTabBarHeight];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, bottom)];
        
        [self.view addSubview:self.tableView];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:KBEAccountChange
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [self updateProflie];
                                                      //[self.tableView reloadData];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:KBELocalCacheClearOK
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note)
     {
         //即时反馈
         iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
         NSString * message = NSLocalizedString(@"Cleanning is ok",nil);
         [appDelegate makeToast:message];
     }];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:2];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KBEAccountChange    object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KBELocalCacheClearOK    object:nil];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    
    // Show coach marks
    BOOL coachMarksShown = [[NSUserDefaults standardUserDefaults] boolForKey:@"FlyingAccountVCMarksShown"];
    
    if (coachMarksShown == NO)
    {
        // Don't show again
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FlyingAccountVCMarksShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Setup coach marks
        NSArray *coachMarks = @[
                                @{
                                    @"rect": [NSValue valueWithCGRect:self.myProfileCell.frame],
                                    @"caption": @"技巧:这里修改头像、昵称！",
                                    @"shape": @"square"
                                    },
                                @{
                                    @"rect": [NSValue valueWithCGRect:self.myWordsCell.frame],
                                    @"caption": @"技巧:系统会自动记录你点击过的英语生词！",
                                    @"shape": @"square"
                                    },
                                @{
                                    @"rect": [NSValue valueWithCGRect:self.serviceCell.frame],
                                    @"caption": @"技巧:所有问题都可以直接咨询客服：）",
                                    @"shape": @"square"
                                    },
                                ];
        
        self.coachMarksView = [[WSCoachMarksView alloc] initWithFrame:self.view.bounds coachMarks:coachMarks];
        self.coachMarksView.enableContinueLabel = NO;
        self.coachMarksView.enableSkipButton = NO;

        [self.view addSubview:self.coachMarksView];
        
        // Show coach marks
        [self.coachMarksView start];
    }
}

- (void) dismissNavigation
{
    [self willDismiss];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) willDismiss
{
}

-(void) doScan
{
    
    [self.navigationController pushViewController:[[FlyingScanViewController alloc] init]
                                         animated:YES];
}

//////////////////////////////////////////////////////////////
#pragma mark - Loading data and setup view
//////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////
#pragma mark - UITableView Datasource
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    }
    else if (section == 1)
    {
        return 1;
    }
    else if (section == 2)
    {
        return 2;
    }
    else if (section == 3)
    {
        return 2;
    }
    else if (section == 4)
    {
        return 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;
    
    FlyingImageTextCell *profileTabelViewCell = [tableView dequeueReusableCellWithIdentifier:@"FlyingImageTextCell"];
    
    if(profileTabelViewCell == nil)
        profileTabelViewCell = [FlyingImageTextCell imageTextCell];
    
    [self configureCell:profileTabelViewCell atIndexPath:indexPath];
    
    cell = profileTabelViewCell;
    
    switch (indexPath.section) {
        case 0:
        {
            self.myProfileCell = cell;
            break;
        }
            
        case 2:
        {
            if (indexPath.row==0) {
                
                self.myWordsCell = cell;
            }
            break;
        }
            
        case 4:
        {
            self.serviceCell = cell;
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 47.5;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        FlyingUserData *userData=[FlyingDataManager getUserData:nil];
        
        if (![NSString isBlankString:userData.portraitUri]){
            [(FlyingImageTextCell *)cell setImageIconURL:userData.portraitUri];
        }
        else{
            
            if (![FlyingDataManager getOpenUDID]) {
                
                return;
            }
            
            [FlyingHttpTool getUserInfoByopenID:[FlyingDataManager getOpenUDID]
                                     completion:^(FlyingUserData *userData, RCUserInfo *userInfo) {
                                         //
                                         if ([NSString isBlankString:userData.portraitUri])
                                         {
                                             //
                                         }
                                         else
                                         {
                                             [(FlyingImageTextCell *)cell setImageIconURL:userData.portraitUri];
                                             [(FlyingImageTextCell *)cell setCellText:userData.name];
                                         }
                                         
                                     }];
        }
        
        if (![NSString isBlankString:userData.name]){
            
            [(FlyingImageTextCell *)cell setCellText:userData.name];
        }
        else{
            
            [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Touch nickName to update it!", nil)];
        }
    }
    
    else if (indexPath.section == 1)
    {
        [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"Price"]];
        [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"My Service",nil)];
    }
    
    else if (indexPath.section == 2)
    {
        
        if (indexPath.row == 0)
        {
            NSString * englishLabel = NSLocalizedString(@"English Tool",nil);
            
            NSArray *wordArray =  [[[FlyingTaskWordDAO alloc] init] selectWithUserID:[FlyingDataManager getOpenUDID]];
            _wordCount = wordArray.count;
            if (_wordCount>0) {
                
                englishLabel= [NSString stringWithFormat:NSLocalizedString(@"My Dictionary[%@]", nil) , @(_wordCount)];
            }
            
            [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"Word"]];
            [(FlyingImageTextCell *)cell setCellText:englishLabel];
        }
        else
        {
            [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"dictionary"]];
            [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Dictionary",nil)];
        }
    }
    
    else if (indexPath.section == 3)
    {
        
        switch (indexPath.row) {
            case 0:
            {
                [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"close"]];
                [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Clear Cache",nil)];
                break;
            }
                
            case 1:
            {
                [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"colorWheel"]];
                [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Style Setting",nil)];
                break;
            }
                
            default:
                break;
        }
    }
    else if (indexPath.section == 4)
    {
        [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"Help"]];
        [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Service Online",nil)];
    }
}

- (void) updateProflie
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            FlyingProfileVC* profileVC = [[FlyingProfileVC alloc] init];
            
            profileVC.openUDID = [FlyingDataManager getOpenUDID];
            
            [self.navigationController pushViewController:profileVC animated:YES];

            break;
        }
            
        case 1:
        {
            FlyingBuyVC * buyVC = [[FlyingBuyVC alloc] init];
            
            [self.navigationController pushViewController:buyVC animated:YES];

            break;
        }
            
        case 2:
        {
            
            if (indexPath.row == 0)
            {
                if (_wordCount>0) {
                    
                    FlyingReviewVC * reviewVC = [[FlyingReviewVC alloc] init];
                    reviewVC.hidesBottomBarWhenPushed = YES;
                    
                    [self.navigationController pushViewController:reviewVC animated:YES];
                }
                else
                {
                    //即时反馈
                    NSString * message = NSLocalizedString(@"Click the words in the subtitles for translation", nil);
                    [self.view makeToast:message
                                duration:3.0
                                position: CSToastPositionCenter];
                }
            }
            else
            {
                FlyingSearchViewController* search = [[FlyingSearchViewController alloc] init];
                [search setSearchType:BC_Search_Word];
                
                [self.navigationController pushViewController:search animated:YES];
            }

            break;
        }
            
        case 3:
        {
            if (indexPath.row == 0) {
                
                [self clearCache];
            }
            else if (indexPath.row == 1) {
                
                
                FlyingPickColorVCViewController * vc= [[FlyingPickColorVCViewController alloc] init];
                
                //定制导航条背景颜色
                [self.navigationController pushViewController:vc animated:YES];
            }

            break;
        }
            
        case 4:
        {
            [FlyingGroupVC contactAppServiceWithMessage:NSLocalizedString(@"Service Online",nil)
                                                   inVC:self];
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


//清理缓存
-(void) clearCache
{
    [FlyingDataManager clearCache];
}


@end
