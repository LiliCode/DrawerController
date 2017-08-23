//
//  ViewController.m
//  抽屉侧滑更改
//
//  Created by 圈圈科技 on 16/5/20.
//  Copyright © 2016年 圈圈科技. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
@property (strong , nonatomic) AppDelegate *appDelegate;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.appDelegate = [UIApplication sharedApplication].delegate;
}

- (IBAction)open_left:(UIBarButtonItem *)sender
{
    [self.appDelegate.drawer performDrawer];
}


- (IBAction)open_right:(UIBarButtonItem *)sender
{
    [self.appDelegate.drawer performDrawer];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
