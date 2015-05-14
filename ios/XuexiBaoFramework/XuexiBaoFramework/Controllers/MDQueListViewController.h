//
//  MDQueListViewController.h
//  education
//
//  Created by kimziv on 14-7-15.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

//#import "BaseViewController.h"



typedef NS_ENUM(NSInteger, MDQueListType){
    MDQueListTypeSolved=1,
    MDQueListTypeUnsolved
};



@interface MDQueListViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITableView *tableView;

+(MDQueListViewController *)sharedInstance;

//- (void)showBindMobilePage:(void(^)(id))completion;
- (void)showCameraController;
@end
