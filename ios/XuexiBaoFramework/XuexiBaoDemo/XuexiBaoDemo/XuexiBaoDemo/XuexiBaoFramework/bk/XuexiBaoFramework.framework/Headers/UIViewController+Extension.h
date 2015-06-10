//
//  UIViewController+Extension.h
//  education
//
//  Created by kimziv on 14-5-5.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    NavBarLocationMiddle        = 0,
    NavBarLocationLeft          = 1,
    NavBarLocationRight         = 2,
    NavBarLocationLeftAndRight  = 3
} NavBarLocation;

typedef enum {
    NavBarItemTypeNone=-1,
    NavBarItemTypeBack=0,
    NavBarItemTypeCancel,
    NavBarItemTypeDelete,
    NavBarItemTypeSubject,
    NavBarItemTypeSearch,
    NavBarItemTypeAction,
    NavBarItemTypeSetting,
    NavBarItemTypeNewTopic,
    NavBarItemTypeCirTags,
    NavBarItemTypeWonder,   // 逛逛
    NavBarItemTypeMe,       // 我
    NavBarItemTypeFilter,   // 筛选
    NavBarItemTypeMessage,  // 未读消息
    NavBarItemTypeMore,  // 未读消息
    NavBarItemTypeEdit,  // 编辑按钮
//    NavBarItemTypeSlideMenu=1,
//    NavBarItemTypeRefresh  = 2,
//    NavBarItemTypePost=3,
//    NavBarItemTypeSetting=4,
//    NavBarItemTypePromote=5,
//    NavBarItemTypeAddWeibo =6,
//    NavBarItemTypeAddMember =7,
//    NavBarItemTypeChat=8,
//    NavBarItemTypeReport=9,
//    NavBarItemTypeNext,
//    NavBarItemTypeCreateNext,
//    NavBarItemTypeCreateBack,
    NavBarItemTypeUser,
    NavBarItemReport,        // 举报
    NavBarItemSwitchAccount,    // 切换账号
    NavBarItemTypeHelp
} NavBarItemType;

typedef struct {
    NavBarItemType type;
    __unsafe_unretained NSString *title;
}NavBarItemInfo;

@interface UIViewController (Extension)
-(void)initLeftNavBtn;
-(void)initRightNavBtn;
-(UIBarButtonItem*)makeNavBtn:(NavBarItemInfo)info location:(NavBarLocation)location;
-(void)leftNavBtnAction:(id)sender;
-(void)rightNavBtnAction:(id)sender;
-(void)setBackground;

-(void)showProgeressHud;
-(void)hideProgressHud;


//Controller 之间双向传参数
@property(nonatomic, strong)NSDictionary *controllerParams;
@property(nonatomic, copy)void(^controllerHandler)(id sender);
@end
