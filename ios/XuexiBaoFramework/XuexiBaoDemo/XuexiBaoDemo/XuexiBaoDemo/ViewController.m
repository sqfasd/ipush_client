//
//  ViewController.m
//  XuexiBaoDemo
//
//  Created by 王俊 on 15/5/14.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import <XuexiBaoFramework/XuexiBaoFramework.h>



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    // 教师端
//    [[LOTLib sharedInstance] startWithAppKey:@"5554527E474347F01EDB267A" secret:@"BDECB2E9C8F6887FF31D5AC6DA312D85"];
    
    // 对外SDK
    [[LOTLib sharedInstance] startWithAppKey:@"5577E6CCE4B0CDD74AE31C7E" secret:@"64F682C06F2A719D1902CE7C8E5CAA07"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openCameraClicked:(id)sender {
    BOOL isCamrma = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    if (!isCamrma) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title", @"alert_title") message:NSLocalizedString(@"alert_no_backcamera", @"alert_no_backcamera") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    
    [self.navigationController pushViewController:[MDQueListViewController sharedInstance] animated:YES];
    
//    SCNavigationController *nav = [[SCNavigationController alloc] init];
//    nav.scNaigationDelegate = self;
//    [nav showCameraWithParentController:self isPro:YES];

}


//#pragma mark -
//#pragma mark - SCNavigationController delegate
//- (void)didEndEditPhoto:(UIImage *)image
//{
//    NSLog(@"didendeditphoto: %@", NSStringFromCGSize(image.size));
//}

@end
