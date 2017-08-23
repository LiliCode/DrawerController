//
//  AppDelegate.h
//  抽屉侧滑更改
//
//  Created by 圈圈科技 on 16/5/20.
//  Copyright © 2016年 圈圈科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ICSDrawerController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong , nonatomic) ICSDrawerController *drawer;

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

