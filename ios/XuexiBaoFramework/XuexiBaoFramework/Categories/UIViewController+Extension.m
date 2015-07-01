//
//  UIViewController+Extension.m
//  education
//
//  Created by kimziv on 14-5-5.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "UIViewController+Extension.h"
#import "UIImage+Extension.h"
#import "NSString+Additions.h"
#import <objc/runtime.h>



static NSString *kParamsAssociatedKey = @"kParamsAssociatedKey";
static NSString *kHandlerAssociatedKey = @"kHandlerAssociatedKey";
@implementation UIViewController (Extension)


-(void)initLeftNavBtn{
    if (self!=[self.navigationController.viewControllers objectAtIndex:0]) {
        NavBarItemInfo info={.type=NavBarItemTypeBack, .title=nil};
        //self.navigationItem.leftBarButtonItem=[self makeNavBtn:info location:NavBarLocationLeft];
        
        //重设回退按钮左侧距离
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSpacer.width = -16;         // 默认左侧为16个像素
        
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [view addSubview:[[self makeNavBtn:info location:NavBarLocationLeft] customView]];
        
        [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:negativeSpacer,[[UIBarButtonItem alloc] initWithCustomView:view] , nil] animated:NO];
    }
}

-(void)initRightNavBtn{
    
}

-(UIBarButtonItem*)makeNavBtn:(NavBarItemInfo)info location:(NavBarLocation)location{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame=CGRectMake(0,0, 44, 44);
   // UIImage *bgImg=[UIImage imageNamed:@"nav_btn_bg"];
    UIImage *btnImg=nil;
    UIImage *btnHiImg = nil;
    UIImage *btnSelImg = nil;

    switch (info.type) {
        case NavBarItemTypeNone:{
            // button.titleLabel.text=@"发布";//info.title;
            [button.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
            [button setTitle:info.title forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithHex:0xffffff] forState:UIControlStateNormal];
            CGRect btnFrame=button.frame;
            btnFrame.size.width=[button.titleLabel.text sizeWithFont7:button.titleLabel.font].width;
            button.frame=btnFrame;
        }
            break;
        case NavBarItemTypeBack:
        {
            btnImg=[UIImage imageNamed:XXBRSRC_NAME(@"nav_btn_back")];
            btnHiImg = btnSelImg = [UIImage imageNamed:XXBRSRC_NAME(@"nav_btn_back_h")];
        }
            break;
        case NavBarItemTypeCancel:
        {
            btnImg=[UIImage imageNamed:XXBRSRC_NAME(@"nav_btn_close")];
            btnHiImg = btnSelImg = [UIImage imageNamed:XXBRSRC_NAME(@"nav_btn_close_h")];
        }
            break;
        case NavBarItemTypeDelete:
        {
            btnImg = [UIImage imageNamed:XXBRSRC_NAME(@"nav_btn_delete")];
            btnHiImg = btnSelImg = [UIImage imageNamed:XXBRSRC_NAME(@"nav_btn_delete_h")];
        }
            break;
        case NavBarItemTypeSubject:
        {
            btnImg=[UIImage imageNamed:@"ic_nav_subject"];
            btnHiImg = [UIImage imageNamed:@"ic_nav_subject"];
        }
            break;
        case NavBarItemTypeMe:
        {
            btnImg = [UIImage imageNamed:@"defaultAvatar"];
        }
            break;
        case NavBarItemTypeSearch:
        {
            btnImg=[UIImage imageNamed:@"ic_nav_search"];
        }
            break;
        case NavBarItemTypeWonder:
        {
            btnImg = [UIImage imageNamed:@"nav_btn_stroll"];
        }
            break;
        case NavBarItemTypeAction:
        {
            btnImg =[UIImage imageNamed:@"ic_nav_action"];
        }
            break;
        case NavBarItemTypeSetting:
        {
            btnImg =[UIImage imageNamed:@"ic_tab_setting_nor"];
        }
            break;
        case NavBarItemTypeFilter:
        {
            btnImg = [UIImage imageNamed:@"nav_btn_screen"];
            btnHiImg = [UIImage imageNamed:@"nav_btn_screen_h"];
            btnSelImg = [UIImage imageNamed:@"nav_btn_screened"];
        }
            break;
        case NavBarItemTypeMessage:
        {
            btnImg = [UIImage imageNamed:@"nav_btn_reply"];
            btnHiImg = btnSelImg = [UIImage imageNamed:@"nav_btn_reply_h"];
        }
            break;
        case NavBarItemReport:
        {
            btnImg = [UIImage imageNamed:@"nav_btn_report"];
            btnHiImg = btnSelImg = [UIImage imageNamed:@"nav_btn_report_h"];
        }
            break;
        case NavBarItemTypeNewTopic:
        {
            [button.titleLabel setFont:[UIFont boldSystemFontOfSize:16.0]];
            [button setTitle:info.title forState:UIControlStateNormal];
            [button setTitle:info.title forState:UIControlStateHighlighted];
            [button setTitle:info.title forState:UIControlStateSelected];
            [button setTitle:info.title forState:UIControlStateDisabled];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        }
            break;
        case NavBarItemTypeUser:
        {
            btnImg=[UIImage imageNamed:@"ic_nav_user"];
        }
            break;
        case NavBarItemTypeCirTags:
        {
            btnImg = [UIImage imageNamed:@"ic_nav_subject"];
        }
            break;
        case NavBarItemTypeMore:
        {
            btnImg = [UIImage imageNamed:@"nav_btn_more"];
            btnHiImg = [UIImage imageNamed:@"nav_btn_more_h"];
            btnSelImg = [UIImage imageNamed:@"nav_btn_more_h"];
//            btnImg = [UIImage imageNamed:@"ic_nav_more_nor"];
//            [button setImage:[UIImage imageNamed:@"ic_nav_more_pre"] forState:UIControlStateHighlighted];
        }
            break;
        case NavBarItemSwitchAccount:
        {
            btnImg = [UIImage imageNamed:@"nav_btn_userchange"];
            btnHiImg = [UIImage imageNamed:@"nav_btn_userchange_h"];
            btnSelImg = [UIImage imageNamed:@"nav_btn_userchange_h"];
        }
            break;
        case NavBarItemTypeHelp:
        {
            btnImg = [UIImage imageNamed:@"nav_btn_help"];
            [button setImage:[UIImage imageNamed:@"nav_btn_help_h"] forState:UIControlStateHighlighted];
        }
            break;
            
        case NavBarItemTypeEdit:
            btnImg = [UIImage imageNamed:@"account_edit"];
            btnSelImg = [UIImage imageNamed:@"account_edit_h"];
            break;
        default:
        {
            btnImg =[UIImage imageNamed:@"nav_back_btn"];
        }
            break;
    }
    
    //UIView *lv=[[UIView alloc] init];
    // [lv addSubview:button];
    // UIGraphicsBeginImageContextWithOptions(CGSizeMake(39, 30), NO, 0.0);
    //      [bgImg drawInRect:CGRectMake(8, 3, 39, 30)];
    //    bgImg = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    //    button.frame=CGRectMake(0,0, 39, 30);
    // lv.frame=CGRectMake(0,0,39,30);
    // [button setBackgroundImage:btnImg forState:UIControlStateNormal];
    if (btnImg) {
        [button setImage:btnImg forState:UIControlStateNormal];
    }
    
    if (btnHiImg) {
        [button setImage:btnHiImg forState:UIControlStateHighlighted];
    }
    
    if (btnSelImg) {
        [button setImage:btnSelImg forState:UIControlStateSelected];
    }
    
    [button  setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)location];

    if (location==NavBarLocationLeft) {
        [button  setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    }else if(location==NavBarLocationRight){
         [button  setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    }else if(location==NavBarLocationMiddle){
         [button  setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    }else if(location==NavBarLocationLeftAndRight){
         [button  setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    }
    
    [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    //[button setContentMode:UIControlContentHorizontalAlignmentCenter];
    
    UIBarButtonItem *barBtnItem= [[UIBarButtonItem alloc] initWithCustomView:button];
    switch (location) {
        case NavBarLocationLeft:
            [button addTarget:self action:@selector(leftNavBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            break;
        case NavBarLocationRight:
            [button addTarget:self action:@selector(rightNavBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            break;
        default:
            break;
    }
    
    
    return barBtnItem;
    //return [[UIBarButtonItem alloc] initWithCustomView:button];
}

-(void)leftNavBtnAction:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)rightNavBtnAction:(id)sender{
    ///over wirite in subclasses
}

-(void)setBackground
{
//    if ([self isKindOfClass:[UITableViewController class]]) {
//        UITableViewController *tbController=(UITableViewController *)self;
//        [tbController.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg"]]];
//    }else{
//        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]]];
//    }
    
}

/**
 *  显示loading浮层
 */
-(void)showProgeressHud
{
    [SVProgressHUD show];
}

-(void)hideProgressHud
{
    [SVProgressHUD dismiss];
}

-(void)setControllerParams:(NSDictionary *)params
{
    objc_setAssociatedObject(self, (__bridge const void *)(kParamsAssociatedKey), params, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


-(NSDictionary *)controllerParams
{
    return objc_getAssociatedObject(self, (__bridge const void *)(kParamsAssociatedKey));
}

-(void)setControllerHandler:(void (^)(id))controllerHandler
{
    objc_setAssociatedObject(self, (__bridge const void *)(kHandlerAssociatedKey), controllerHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(void (^)(id))controllerHandler
{
    return objc_getAssociatedObject(self, (__bridge const void *)(kHandlerAssociatedKey));
}

@end
