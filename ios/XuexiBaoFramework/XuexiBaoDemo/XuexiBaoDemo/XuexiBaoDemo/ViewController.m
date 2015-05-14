//
//  ViewController.m
//  XuexiBaoDemo
//
//  Created by 王俊 on 15/5/14.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import <XuexiBaoFramework/LOTLib.h>
#import <XuexiBaoFramework/SCCaptureCameraController.h>
#import <XuexiBaoFramework/SCNavigationController.h>



@interface ViewController ()<SCNavigationControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    
    SCNavigationController *nav = [[SCNavigationController alloc] init];
    nav.scNaigationDelegate = self;
    [nav showCameraWithParentController:self isPro:YES];

}


#pragma mark -
#pragma mark - SCNavigationController delegate
- (void)didEndEditPhoto:(UIImage *)image
{
    NSLog(@"didendeditphoto: %@", NSStringFromCGSize(image.size));
    
//    // 2. 开始实际上传操作
//    [[MDXuexiBaoAPI sharedInstance] uploadSubjectPicture:image success:^(id responseObject) {
//        MDLog(@"didSelectPhoto succeed");
//    } failure:^(NSError *error) {
//        
//    }];
}

@end
