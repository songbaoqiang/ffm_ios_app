//
//  RCDRoomSettingViewController.m
//  RCloudMessage
//
//  Created by Liv on 15/4/8.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCDRoomSettingViewController.h"

@interface RCDRoomSettingViewController()

@end

@implementation RCDRoomSettingViewController

- (id)init
{
    if ((self = [super init]))
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //顶部导航
    if(self.navigationController.viewControllers.count>1)
    {
        UIButton* backButton= [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
        [backButton setBackgroundImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(dismissNavigation) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem* backBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:backButton];
        self.navigationItem.leftBarButtonItem = backBarButtonItem;
    }
    // Do any additional setup after loading the view.
}


- (void) dismissNavigation
{
    [self willDismiss];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) willDismiss
{
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.defaultCells.count - 2 ;
}

@end
