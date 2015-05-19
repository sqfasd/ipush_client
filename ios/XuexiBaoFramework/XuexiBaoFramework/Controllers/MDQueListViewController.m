//
//  MDQueListViewController.m
//  education
//
//  Created by kimziv on 14-7-15.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDQueListViewController.h"
#import "MDQeustionDetailViewController.h"
#import "MDQuestionCell.h"
#import "SCNavigationController.h"
#import "UIActionSheet+Blocks.h"
#import "MDQuestionData.h"
#import "UIViewController+Extension.h"
#import "KxMenu.h"
#import "MDUpdProcessingView.h"
#import "MDQueUpdFailView.h"
#import "MDNoNetHeader.h"
#import "MDXuexiBaoOperationMgr.h"
#import "UIImageView+Extension.h"

#import "MDEmptyMainView.h"

#import "UIButton+WebCache.h"
#import <pop/POP.h>



#define RECT_TAKEPHOTO_BTN CGRectMake(SCREEN_WIDTH / 2 - 37.5, SCREEN_HEIGHT - 115 - 37.5, 75, 75)
#define RECT_DELETE_BTN CGRectMake(0, SCREEN_HEIGHT - 40 - 64, SCREEN_WIDTH, 40)

// CGRectMake(SCREEN_WIDTH / 2 - 80, 120, 160, 160)
#define RECT_EMPTYMAIN_SHOW CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64)
#define RECT_EMPTYMAIN_HIDE CGRectMake(0, -SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - 64)

#define RECT_TAKEPHOTO_BTN_SPRING CGRectMake(0, 0, 75, 75)

#define RECT_EMPTYREMIND_LABEL CGRectMake(64, 300, 192, 36)


typedef enum : NSUInteger {
    HEADER_DISPTYPE_NONE = 0,
    HEADER_DISPTYPE_UPDFAIL = 1,
    HEADER_DISPTYPE_UPDING = 2,
    HEADER_DISPTYPE_NOCONN = 3
} HEADER_DISPTYPE;


@interface MDQueListViewController ()<UITableViewDataSource, UITableViewDelegate, SCNavigationControllerDelegate, MDEmptyMainViewDelegate>
{
    // NSInteger _page;
    NSNumber *_searchType;//-1未解答，其他已解答
    NSNumber *_lastQueId;
    NSTimer *_timer;
    BOOL _isRequesting;
    BOOL _isRequestTimeout;
    
    
    NSString *_subjectName;
    UIBarButtonItem *_leftLoadingBtnItem;
    UIBarButtonItem *_leftBtnItem;
    UIImageView *portraitImgV;
    
    NSInteger alertType;
    
    NSInteger lastDisplayCell;
    
    BOOL isDoingVCPush;
    
    NSArray *selDelIndexPaths;
}

@property (nonatomic) NSInteger headDispType;

//@property(nonatomic)NSInteger page;
@property(nonatomic)NSInteger subjectType;
@property(nonatomic,strong)NSNumber *searchType;
@property(nonatomic,strong)NSNumber *lastQueId;
@property(nonatomic)BOOL isRequesting;
@property(nonatomic)BOOL isRequestTimeout;
@property(nonatomic,strong)UIBarButtonItem *leftLoadingBtnItem;
@property(nonatomic,strong)UIBarButtonItem *leftBtnItem;

// V2.0
@property (nonatomic) BOOL hasProcessingSubject;
@property (nonatomic) BOOL hasNetErrorSubject;
@property (nonatomic, strong) MDUpdProcessingView *uploadProcessingView;
@property (nonatomic, strong) UIButton *leftNavButton;

@property (nonatomic, strong) MDQueUpdFailView *updFailView;
@property (nonatomic, strong) MDNoNetHeader *noNetHeader;

@property (strong, nonatomic) IBOutlet UIButton *takePhotoButton;

@property (nonatomic, strong) UIView *meBadge;
@property (nonatomic, strong) UIView *strollBadge;
@property (nonatomic, strong) UIView *rightCustomView;

@property (nonatomic, strong) NSMutableArray *dataList;

@property (nonatomic, strong) MDEmptyMainView *emptyMainView;

- (IBAction)takeSubPhotoBtnClicked:(id)sender;

// V2.4
@property (nonatomic, strong) UIButton *deleteBtn;

@end





static MDQueListViewController *queListViewController = nil;

@implementation MDQueListViewController
//@synthesize page=_page;
@synthesize subjectType=_subjectType;
@synthesize searchType=_searchType;
@synthesize lastQueId=_lastQueId;
@synthesize isRequesting=_isRequesting;
@synthesize isRequestTimeout=_isRequestTimeout;
@synthesize leftLoadingBtnItem=_leftLoadingBtnItem;
@synthesize leftBtnItem=_leftBtnItem;

+ (MDQueListViewController *)sharedInstance
{
    if (!queListViewController) {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"LOTStoryboard" bundle:XXBFRAMEWORK_BUNDLE];
        queListViewController = [storyBoard instantiateViewControllerWithIdentifier:@"MDQueListViewController"];
//        queListViewController = [[MDQueListViewController alloc] initWithNibName:XXBRSRC_NAME(@"MDQueListViewController") bundle:XXBFRAMEWORK_BUNDLE];

//        MDLog(@"LOTSTORYBOARD: %@  XXBFRAMEWORK_BUNDLE: %@", LOTSTORYBOARD, XXBFRAMEWORK_BUNDLE);
//        queListViewController = [LOTSTORYBOARD instantiateViewControllerWithIdentifier:@"MDQueListViewController"];
    }
    
    return queListViewController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        queListViewController = self;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        queListViewController = self;
    }
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
}

-(NSString *)tabImageName
{
    return @"ic_tab_pen";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initProcessor];
    
    [self initViews];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.emptyMainView shineStars];
    
    [TalkingData trackPageBegin:NSStringFromClass([MDQueListViewController class])];

    [self checkNetworkReachability];
    
    [self initHeaderDispType];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    isDoingVCPush = NO;
    
    [TalkingData trackPageEnd:NSStringFromClass([MDQueListViewController class])];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //    NSInteger storedVer=[[MDStoreUtil sharedInstance] storedappVersion];
    //    NSInteger plistVer=[MDStoreUtil plistAppVersion];
    //    if (storedVer==0 || storedVer<plistVer) {
    //        [self showIntroView];
    //    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)checkNetworkReachability {
    // 检测网络
    StartReachabilityCheck(^{
        // 隐藏顶部状态条
        self.headDispType = HEADER_DISPTYPE_NONE;
    }, ^{
        // 显示顶部状态条
        self.headDispType = HEADER_DISPTYPE_NOCONN;
    });

}


-(void)updateReadStatus:(NSNotification *)notification
{
    NSString *imageID = [notification.userInfo nonNullObjectForKey:@"image_id"];
    if (imageID) {
        
    }
    
    [self.tableView reloadData];
}

-(void)refreshData:(NSNotification *)noti
{
    NSDictionary *userinfo=noti.userInfo;
    if (userinfo&& userinfo.count>0) {
        [self getQueList:self.lastQueId more:NO];
    }
}


- (void)refreshQuestionList:(NSNotification *)note
{
    [self refreshQues];
}


-(void)refreshDataWhenLogout:(NSNotification *)notification
{
    [self refreshQues];
}

-(void)refreshQues
{
    NSString *lastToken=[MDUserUtil sharedInstance].token;
    if (lastToken==nil || lastToken.length==0) {
        return;
    }
    
    [self getQueList:nil more:NO];
}

-(void)initLeftNavBtn
{
    if (self.tableView.isEditing) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.leftBarButtonItems = nil;

        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        bgView.backgroundColor = [UIColor colorWithHex:0x0091ff];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:bgView];
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.leftBarButtonItems = nil;

        [super initLeftNavBtn];
    }
}

-(void)leftNavBtnAction:(id)sender
{
    if (isDoingVCPush) {
        return;
    }
    
    isDoingVCPush = YES;
    
    [super leftNavBtnAction:sender];
}

- (void)initRightNavBtn
{
    if (self.tableView.isEditing) {
        [self setRightNavBtnCancel];
    }
    else {
        [self setRightNavBtnMore];
    }
}

- (void)setRightNavBtnMore {
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = nil;
    
    if (self.dataList.count > 0) {
        NavBarItemInfo info = {.type = NavBarItemTypeMore};
        UIBarButtonItem *barItem = [self makeNavBtn:info location:NavBarLocationRight];
        
        UIBarButtonItem * negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSpacer.width = -16;
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, barItem, nil];
    }
}

- (void)setRightNavBtnCancel {
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = nil;
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 40, 40);
    cancelBtn.titleLabel.textColor = [UIColor whiteColor];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    cancelBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    cancelBtn.backgroundColor = [UIColor clearColor];
    [cancelBtn addTarget:self action:@selector(onTappedCancelDelete) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:cancelBtn];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)onTappedCancelDelete {
    [self becomeEditMode:NO];
}

- (void)rightNavBtnAction:(id)sender
{
    static BOOL isMenuDisplay = NO;
    
    // 取消编辑状态
    if (self.tableView.isEditing) {
        [self becomeEditMode:NO];
    }
    // 打开管理菜单
    else {
        if (!isMenuDisplay) {
            [KxMenu setTintColor:[UIColor whiteColor]];
            NSArray *menuItems =
            @[
              [KxMenuItem menuItem:@"管理题目"
                             image:[UIImage imageNamed:@"qaMngIcon"]
                            target:self
                            action:@selector(manageSubjects)]];
            
            [KxMenu showMenuInView:self.navigationController.view fromRect:CGRectMake(self.view.width - 70, 26, 60, 30) menuItems:menuItems];
            
            isMenuDisplay = YES;
        }
        else {
            [KxMenu dismissMenu];
            
            isMenuDisplay = NO;
        }
    }
}

- (void)becomeEditMode:(BOOL)isEditing {
    if (self.tableView.isEditing == isEditing)
        return;
    
    // 进入编辑状态
    if (isEditing) {
        self.tableView.pullToRefreshView.hidden = YES;
        self.tableView.infiniteScrollingView.hidden = YES;
        
        [self.tableView setEditing:YES animated:YES];

        [self showDeleteBtn];
        [self setRightNavBtnCancel];
    }
    else {
        self.tableView.pullToRefreshView.hidden = NO;
        self.tableView.infiniteScrollingView.hidden = NO;

        [self.tableView setEditing:NO animated:YES];

        [self hideDeleteBtn];
        [self setRightNavBtnMore];
    }
    
    [self initLeftNavBtn];
}

- (void)manageSubjects {
    [self becomeEditMode:YES];
}


-(UIBarButtonItem *)leftBtnItem
{
    if (_leftBtnItem) {
        return _leftBtnItem;
    }
    NavBarItemInfo info={.type=NavBarItemTypeMe};
    _leftBtnItem=[self makeNavBtn:info location:NavBarLocationLeft];
    return _leftBtnItem;
}

-(UIBarButtonItem *)leftLoadingBtnItem
{
    if (_leftLoadingBtnItem) {
        return _leftLoadingBtnItem;
    }
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicatorView.hidesWhenStopped=YES;
    [indicatorView startAnimating];
    _leftLoadingBtnItem=[[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    return _leftLoadingBtnItem;
}



#pragma mark -
#pragma mark - MDEmptyMainViewDelegate
- (void)emptyViewDidOpenCamera:(MDEmptyMainView *)emptyMainView
{
    [self showCameraController];
}


#pragma mark -
#pragma mark - Properties
- (UIButton *)deleteBtn {
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteBtn.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 80);
        _deleteBtn.backgroundColor = [UIColor colorWithHex:0xaeaeae];
        _deleteBtn.titleLabel.textColor = [UIColor whiteColor];
        [_deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_deleteBtn addTarget:self action:@selector(onTappedDeleteQues) forControlEvents:UIControlEventTouchUpInside];
        _deleteBtn.enabled = NO;
    }
    
    return _deleteBtn;
}

- (void)showDeleteBtn {
    self.deleteBtn.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 40);
    self.takePhotoButton.frame = RECT_TAKEPHOTO_BTN;
    
    [UIView animateWithDuration:0.2 animations:^{

    } completion:^(BOOL finished) {
        self.takePhotoButton.frame = CGRectMake(SCREEN_WIDTH / 2 - 37, SCREEN_HEIGHT, 75, 75);
        self.deleteBtn.frame = RECT_DELETE_BTN;
    }];
}

- (void)hideDeleteBtn {
    self.deleteBtn.frame = CGRectMake(0, SCREEN_HEIGHT - 40, SCREEN_WIDTH, 40);
    
    [self enableDeleteBtn:NO];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.takePhotoButton.frame = RECT_TAKEPHOTO_BTN;
        self.deleteBtn.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 40);
    } completion:^(BOOL finished) {
        self.takePhotoButton.frame = RECT_TAKEPHOTO_BTN;
        self.deleteBtn.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 40);
    }];
}

- (void)enableDeleteBtn:(BOOL)enable {
    if (self.deleteBtn.enabled == enable)
        return;
    
    if (enable) {
        self.deleteBtn.backgroundColor = [UIColor colorWithHex:0xf25454];
    }
    else {
        self.deleteBtn.backgroundColor = [UIColor colorWithHex:0xaeaeae];
    }

    self.deleteBtn.enabled = enable;
}

- (void)onTappedDeleteQues {
    NSArray *ips = self.tableView.indexPathsForSelectedRows;
    NSArray *resultArray = [ips sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSIndexPath *ip1 = (NSIndexPath *)obj1;
        NSIndexPath *ip2 = (NSIndexPath *)obj2;
        
        if (ip1.row > ip2.row) {
            return NSOrderedAscending;
        }
        else if (ip1.row < ip2.row) {
            return NSOrderedDescending;
        }
        
        return NSOrderedSame;
    }];

    NSMutableString *imgIds = [[NSMutableString alloc] init];
    for (NSIndexPath *indexPath in resultArray) {
        if (indexPath.row >= self.dataList.count) {
            continue;
        }
        
        MDQuestionData *data = [self.dataList objectAtIndex:indexPath.row];
        [imgIds appendFormat:@"%@,", data.imageID];
    }
    
    
    [SVProgressHUD showMDBusying];
    
    [[MDXuexiBaoAPI sharedInstance] postForAPI:MD_DOMAIN api:OP_QUE_DELETE post:@{@"image_ids":imgIds.copy} success:^(id responseObject) {
        [SVProgressHUD dismiss];

        for (NSIndexPath *indexPath in resultArray) {
            [self.dataList removeObjectAtIndex:indexPath.row];
        }
        
        // 退出编辑按钮
        [self becomeEditMode:NO];

        [self.tableView reloadData];
        
        [self switchEmptyDisplay:(self.dataList.count == 0)];
    } failure:^(NSError *error) {
        
    }];
}

- (void)setHeadDispType:(NSInteger)headDispType {
    _headDispType = headDispType;
    
    [self.tableView reloadData];
}

- (MDEmptyMainView *)emptyMainView
{
    if (!_emptyMainView) {
        _emptyMainView = [MDEmptyMainView sharedView];
        _emptyMainView.delegate = self;
    }
    
    return _emptyMainView;
}

- (NSMutableArray *)dataList
{
    if (!_dataList) {
        _dataList = [[NSMutableArray alloc] init];
    }
    
    return _dataList;
}

- (void)onTapReuploadFailQue:(UITapGestureRecognizer *)gesture {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%li道题目上传失败：", (long)[[MDCoreDataUtil sharedInstance] queCountOfSubUpdFail]] delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [actionSheet addButtonWithTitle:@"全部上传"];
    [actionSheet addButtonWithTitle:@"全部删除"];
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"取消", @"")];
    
    [actionSheet showInView:self.view handler:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
        // 全部上传
        if (buttonIndex == 0) {
            [[MDXuexiBaoOperationMgr sharedInstance] checkAndSyncUpdFailSubjects:YES];
        }
        // 全部删除
        else if (buttonIndex == 1) {
            [[MDCoreDataUtil sharedInstance] queClearQuesUploadFailed];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];

}

- (MDQueUpdFailView *)updFailView {
    if (!_updFailView) {
        NSArray *views = [XXBFRAMEWORK_BUNDLE loadNibNamed:@"MDQueUpdFailView" owner:self options:nil];
        _updFailView = views.firstObject;
        [_updFailView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapReuploadFailQue:)]];
    }
    
    _updFailView.failCount = [[MDCoreDataUtil sharedInstance] queCountOfSubUpdFail];
    
    return _updFailView;
}

- (MDNoNetHeader *)noNetHeader {
    if (!_noNetHeader) {
        _noNetHeader = [[MDNoNetHeader alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)];
    }
    
    return _noNetHeader;
}


- (MDUpdProcessingView *)uploadProcessingView
{
    if (!_uploadProcessingView) {
        _uploadProcessingView = [[MDUpdProcessingView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)];
        _uploadProcessingView.uploadingCount = 0;
        _uploadProcessingView.hidden = YES;
    }
    
    _uploadProcessingView.uploadingCount = [[MDCoreDataUtil sharedInstance] queCountOfSubProcessing];
    
    return _uploadProcessingView;
}

- (void)showUpdProcessingView
{
    self.headDispType = HEADER_DISPTYPE_UPDING;
}

- (BOOL)hasProcessingSubject
{
    NSInteger count = [[MDCoreDataUtil sharedInstance] queCountOfSubProcessing];
    
    return count > 0 ? YES : NO;
}

- (BOOL)hasNetErrorSubject
{
    if ([[MDCoreDataUtil sharedInstance] queCountOfSubUpdFail] <= 0) {
        return NO;
    }
    
    return YES;
}


- (UIView *)meBadge
{
    if (!_meBadge) {
        _meBadge = [[UIView alloc] initWithFrame:CGRectMake(28, 4, 8, 8)];
        _meBadge.backgroundColor = COLOR_THEME_RED;
        _meBadge.layer.cornerRadius = _meBadge.size.width / 2;
        _meBadge.clipsToBounds = YES;
        _meBadge.hidden = YES;
    }
    
    return _meBadge;
}



#pragma mark -
#pragma mark - MDSubjectsMenuDelegate
-(void)topicPosted:(NSNotification *)notification
{
    //NSDictionary *info=notification.userInfo;
    //MDLog(@"userinfo:%@",[info nonNullObjectForKey:@"topicType"]);
    [SVProgressHUD showStatus:NSLocalizedString(@"msg_sent_success", @"")];
}

-(void)introPageFinished
{
    if (self.tableView.pullToRefreshView.state==MDPullToRefreshStateLoading ) {
        [self.tableView.pullToRefreshView stopAnimating];
    }
    
    [self getQueList:self.lastQueId more:NO];
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_timer) {
        [_timer invalidate];
        _timer=nil;
    }
}


- (void)initProcessor
{
    NSNotificationCenter *ntfCenter = [NSNotificationCenter defaultCenter];
    
    [ntfCenter  addObserver:self selector:@selector(updateReadStatus:) name:kNOTIFICATION_NAME_QuestionRead object:nil];
    
    // 刷新问题列表
    [ntfCenter addObserver:self selector:@selector(refreshQuestionList:) name:kNTF_REFRESH_QUESTIONLIST object:nil];
    
    [ntfCenter addObserver:self selector:@selector(ntfQueNewStart:) name:kNTF_QUE_NEW_START object:nil];
    [ntfCenter addObserver:self selector:@selector(ntfQueNewUpdFail:) name:kNTF_QUE_NEW_UPDFAIL object:nil];
    [ntfCenter addObserver:self selector:@selector(ntfQueReuploadFailed:) name:kNTF_QUE_REUPLOAD object:nil];
    
    // 删除题目
    [ntfCenter addObserver:self selector:@selector(ntfDeleteQuestion:) name:kNOTIFICATION_NAME_DelQuestion object:nil];
}



static NSString *CellIdentifier = @"QueTableCell";


-(void)initViews
{
    isDoingVCPush = NO;
    
    lastDisplayCell = 0;
    [self.tableView registerNib:[UINib nibWithNibName:@"QuestionCell" bundle:XXBFRAMEWORK_BUNDLE] forCellReuseIdentifier:CellIdentifier];
    
    
    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height = SCREEN_HEIGHT;
    self.tableView.frame = tableFrame;
    
    self.navigationItem.title = @"错题本";
    
    _subjectName=NSLocalizedString(@"all", @"");
    
    [self initEmptyView];

    self.tableView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64);
    self.takePhotoButton.frame = CGRectMake(SCREEN_WIDTH / 2 - 37, SCREEN_HEIGHT - 75 - 15, 75, 75);
    
    // 添加删除按钮
    [self.view addSubview:self.deleteBtn];
    [self.view bringSubviewToFront:self.deleteBtn];
    MDLog(@"queSubViews: %@", self.view.subviews);
    

    self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    
    _isRequesting=NO;
    _isRequestTimeout=NO;
    self.searchType=kSEARCH_TYPE_SOLVED;
    
    
    //下拉刷新和上拉更多
    __weak typeof (*& self) wSelf=self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        if (!wSelf.tableView.isEditing) {
            wSelf.lastQueId=nil;
            [wSelf getQueList:wSelf.lastQueId more:NO];
        }
        else {
            [wSelf.tableView.pullToRefreshView stopAnimating];
        }
    }];
    [self.tableView.pullToRefreshView setArrowColor:[UIColor colorWithHex:kCOLOR_NAVIGATION_BAR]];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        if (!wSelf.tableView.isEditing) {
            [wSelf getQueList:wSelf.lastQueId more:YES];
        }
        else {
            [wSelf.tableView.infiniteScrollingView stopAnimating];
        }
    }];
    [self.tableView.infiniteScrollingView setEnabled:NO];
    
    [self initAnimationStatusBarView];
//    [self.view addSubview:self.uploadProcessingView];
    
    ShowLoadingStatus(YES, YES);
    
    [self.tableView triggerPullToRefresh];
}

// 初始化顶部状态栏
- (void)initHeaderDispType {
    if ([[MDCoreDataUtil sharedInstance] queCountOfSubUpdFail] > 0) {
        self.headDispType = HEADER_DISPTYPE_UPDFAIL;
    }
    else if ([[MDCoreDataUtil sharedInstance] queCountOfSubProcessing] > 0) {
        self.headDispType = HEADER_DISPTYPE_UPDING;
    }
    else {
        self.headDispType = HEADER_DISPTYPE_NONE;
    }
}


- (void)initAnimationStatusBarView
{
    UIView * statusbarView = [[UIView alloc] initWithFrame:CGRectMake(0, -64, SCREEN_WIDTH, 64)];
    statusbarView.backgroundColor = COLOR_NAVIGATIONBAR;            //必须是导航栏背景色，慎重
    [self.view addSubview:statusbarView];
}

- (void)initEmptyView
{
    [self.view addSubview:self.emptyMainView];
    [self.emptyMainView initDisplay];
    [self displayEmptyMainView:NO];

//    self.takePhotoButton.frame = RECT_TAKEPHOTO_BTN;
//    self.takePhotoButton.hidden = NO;
}

- (void)switchEmptyDisplay:(BOOL)isEmpty
{
    static BOOL s_isempty = YES;
    
    MDLog(@"");
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        //    dispatch_async(dispatch_get_main_queue(), ^{
        if (s_isempty != isEmpty) {
            if (!isEmpty) {
                [self hideEmptyMainView:YES];
            }
            else  {
                [self displayEmptyMainView:YES];
            }
            
            s_isempty = isEmpty;
        }
    });
}

- (void)displayEmptyMainView:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!animated) {
            self.emptyMainView.frame = RECT_EMPTYMAIN_SHOW;
            return;
        }
        
        self.emptyMainView.hidden = NO;
        
        POPSpringAnimation *animPos = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
        animPos.springBounciness = 12;
        animPos.springSpeed = 6;
        animPos.toValue = [NSValue valueWithCGPoint:CGPointMake(SCREEN_WIDTH / 2, (SCREEN_HEIGHT - 64) / 2)];
        animPos.completionBlock = ^(POPAnimation *anim, BOOL finished) {
            self.emptyMainView.frame = RECT_EMPTYMAIN_SHOW;
        };
        
        [self.emptyMainView.layer pop_addAnimation:animPos forKey:@"position"];
    });
}

- (void)hideEmptyMainView:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!animated) {
            self.emptyMainView.frame = RECT_EMPTYMAIN_HIDE;
            return;
        }
        
        UIView *coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
        coverView.backgroundColor = [UIColor colorWithHex:0x0091ff];
        [self.view addSubview:coverView];
        
        [self.view bringSubviewToFront:self.emptyMainView];
        
        POPBasicAnimation *basicAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
        basicAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        basicAnim.duration = 0.15;
        basicAnim.toValue = @(self.emptyMainView.center.y + 20);
        
        [basicAnim setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
            if (finished) {
                POPBasicAnimation *basicAnim2 = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
                basicAnim2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                basicAnim2.duration = 1.0;
                basicAnim2.toValue = @(-SCREEN_HEIGHT + 64);
                
                [self.emptyMainView pop_addAnimation:basicAnim2 forKey:@"positionY"];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [coverView removeFromSuperview];
                });
            }
        }];

        [self.emptyMainView pop_addAnimation:basicAnim forKey:@"positionY"];
    });
}


#pragma mark -
#pragma mark - Notification
- (void)ntfDeleteQuestion:(NSNotification *)note
{
    if (!note)
        return;
    
    NSString *imageID = [note.userInfo nonNullObjectForKey:@"image_id"];
    if (!imageID || imageID.length <= 0)
        return;
    
    int foundIndex = -1;
    for (int i = 0; i < self.dataList.count; i++) {
        MDQuestionData *cellData = [self.dataList objectAtIndex:i];
        
        if ([imageID isEqualToString:cellData.imageID]) {
            foundIndex = i;
            break;
        }
    }
    
    if (foundIndex >= 0) {
        [self.dataList removeObjectAtIndex:foundIndex];
        [self.tableView reloadData];
        
        [self switchEmptyDisplay:(self.dataList.count == 0)];
    }
}

- (void)ntfQueReuploadFailed:(NSNotification *)note
{
    MDLog(@"ntfQueReuploadFailed");
    
    [self.tableView reloadData];
    
    [self showUpdProcessingView];
}

- (void)ntfQueNewStart:(NSNotification *)note
{
    MDLog(@"ntfQueNewStart");
    
    [self showUpdProcessingView];
}

- (void)ntfQueNewUpdFail:(NSNotification *)note
{
    MDLog(@"ntfQueNewUpdFail");
    
    [self initHeaderDispType];
    
    [self.tableView reloadData];
    return;
}

#pragma mark -
#pragma mark - SCNavigationController delegate
- (void)didEndEditPhoto:(UIImage *)image
{
    // 2. 开始实际上传操作
    [[MDXuexiBaoAPI sharedInstance] uploadSubjectPicture:image success:^(id responseObject) {
        MDLog(@"didSelectPhoto succeed");
    } failure:^(NSError *error) {
        
    }];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //    static CGFloat scrollYOffsetDistance = 0;
    //    static CGFloat lastScrollYOffset = 0;
    //
    //    scrollYOffsetDistance = lastScrollYOffset - scrollView.contentOffset.y;
    //    [self.filterTopView updateOrigin:scrollYOffsetDistance content:scrollView.contentOffset.y];
    //
    //    lastScrollYOffset = scrollView.contentOffset.y;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    
}



-(void)setLeftBarButton:(MDQueListType)listType
{
    UIBarButtonItem *btnItem=self.navigationItem.leftBarButtonItem;
    
    switch (listType) {
        case MDQueListTypeSolved:
            btnItem.customView.hidden=NO;
            break;
        case MDQueListTypeUnsolved:
            btnItem.customView.hidden=YES;
            break;
        default:
            break;
    }
}


-(void)stopPullAnimating
{
    _isRequestTimeout=YES;
    if (!_isRequesting) {
        [self.tableView.pullToRefreshView stopAnimating];
    }
    [_timer invalidate];
    _timer=nil;
}

- (void)checkIfAnyQuestionGotAnswer:(NSArray *)questions
{
    if (!questions || questions.count <= 0)
        return;
    
    NSArray *processingList = [[MDCoreDataUtil sharedInstance] queArrayOfSubProcessing];
    if (!processingList || processingList.count <= 0)
        return;
    
    BOOL hasMatchData = NO;
    NSMutableArray *removeImgIDs = [[NSMutableArray alloc] init];
    
    for (NSDictionary *question in questions) {
        for (MDQuestionV2 *dbQue in processingList) {
            MDLog(@"dbQue imgID:%@", dbQue.image_id);
            
            if ([dbQue.image_id isEqualToString:[question nonNullValueForKeyPath:@"question.image_id"]]) {
                MDLog(@"found equal");
                [removeImgIDs addObject:dbQue.image_id];
                hasMatchData = YES;
            }
        }
    }
    
    if (hasMatchData) {
        [[MDCoreDataUtil sharedInstance] queRemoveQuesWithArrImgID:removeImgIDs.copy];
    }
}

-(void)getQueList:(NSNumber *)lastQueId more:(BOOL)more
{
    if (_isRequesting) {
        MDLog(@"error:  Requesting...");
        return ;
    }
    
    [self checkNetworkReachability];
    
    NSString *token=[MDUserUtil sharedInstance].token;
    if (token==nil || token.length==0) {
        [self.tableView.pullToRefreshView stopAnimating];
        MDLog(@"error: token is nil");
        return;
    }
    
    _isRequesting=YES;
    
    NSMutableDictionary *input = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  @(self.subjectType), @"subject",
                                  (_searchType?_searchType:@""), @"search_type",
                                  @15, @"pageSize",
                                  nil];
    if (!more) {
        [input setObject:@"" forKey:@"id"];
    }
    else {
        [input setObject:(_lastQueId?_lastQueId:@"") forKey:@"id"];
        selDelIndexPaths = self.tableView.indexPathsForSelectedRows;
    }
    
    
    [[MDXuexiBaoAPI sharedInstance] getQueList:[input copy] success:^(id responseObject) {
        _isRequesting=NO;
        
        ShowLoadingStatus(NO, NO);
        
        if (IsResponseOK(responseObject)) {
            
            NSArray *list=[responseObject nonNullValueForKeyPath:@"result"];
            if (list && list.count>0) {
                [self checkIfAnyQuestionGotAnswer:list];
                
                if (!more) {
                    [self switchEmptyDisplay:NO];
                    
                    lastDisplayCell = 0;
                    [self.dataList removeAllObjects];
                    [self.dataList addObjectsFromArray:parseQuestionListData(list)];
                    
                    if (_isRequestTimeout) {
                        [self.tableView.pullToRefreshView stopAnimating];
                        [_timer invalidate];
                        _timer=nil;
                    }
                    
                    [self initRightNavBtn];
                    
                    [self.tableView reloadData];
                    
                    [self.tableView.infiniteScrollingView setEnabled:(self.tableView.contentSize.height>self.tableView.height)];
                }else{
                    [self.dataList addObjectsFromArray:parseQuestionListData(list)];
                    
                    [self.tableView reloadData];
                    [self.tableView.infiniteScrollingView stopAnimating];
                }
                
                _lastQueId = ((MDQuestionData *)self.dataList.lastObject).rowID;
                
                return ;
            }else{
                if (!more) {
                    lastDisplayCell = 0;
                    [self.dataList removeAllObjects];
                    if (_isRequestTimeout) {
                        [self.tableView.pullToRefreshView stopAnimating];
                        [_timer invalidate];
                        _timer=nil;
                    }
                    [self.tableView reloadData];
                    [self.tableView.infiniteScrollingView setEnabled:(self.tableView.contentSize.height>self.tableView.height)];
                    [self switchEmptyDisplay:(self.dataList.count == 0)];
                }
            }
        }
        if (!more) {
            if (_isRequestTimeout) {
                [self.tableView.pullToRefreshView stopAnimating];
                [_timer invalidate];
                _timer=nil;
            }
        }else{
            [self.tableView.infiniteScrollingView stopAnimating];
        }
        
    } failure:^(NSError *error) {
        _isRequesting=NO;
        
        if (!more) {
            [self.tableView.pullToRefreshView stopAnimating];
            [self switchEmptyDisplay:(self.dataList.count == 0)];
        }else{
            [self.tableView.infiniteScrollingView stopAnimating];
        }
        
    }];
    
    
    if (!more) {
        _isRequestTimeout=NO;
        _timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(stopPullAnimating) userInfo:nil repeats:NO];
        [self.tableView.infiniteScrollingView stopAnimating];
    }
    else{
        if (self.tableView.pullToRefreshView.state==MDPullToRefreshStateLoading) {
            [self.tableView.pullToRefreshView stopAnimating];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark -
#pragma mark - UITableViewDelegate & UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.headDispType == HEADER_DISPTYPE_NONE || self.headDispType == HEADER_DISPTYPE_NOCONN) {
        return 0;
    }
    
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.headDispType == HEADER_DISPTYPE_UPDFAIL) {
        return self.updFailView;
    }
    else if (self.headDispType == HEADER_DISPTYPE_UPDING) {
        return self.uploadProcessingView;
    }
//    else if (self.headDispType == HEADER_DISPTYPE_NOCONN) {
//        return self.noNetHeader;
//    }
    
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > lastDisplayCell) {
        CGFloat rotationAngleDegrees = 0;
        CGFloat rotationAngleRadians = rotationAngleDegrees * (M_PI/180);
        //    CGPoint offsetPositioning = CGPointMake(-200, -20);
        CGPoint offsetPositioning = CGPointMake(0, SCREEN_HEIGHT);
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DRotate(transform, rotationAngleRadians, 0.0, 0.0, 1.0);
        transform = CATransform3DTranslate(transform, offsetPositioning.x, offsetPositioning.y, 0.0);
        
        
        UIView *card = [cell contentView];
        card.layer.transform = transform;
        card.layer.opacity = 0.8;
        
        
        card.alpha = 0;
        [UIView animateWithDuration:0.7f animations:^{
            card.alpha = 1;
            card.layer.transform = CATransform3DIdentity;
            card.layer.opacity = 1;
        }];
        
        lastDisplayCell = indexPath.row;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath NS_AVAILABLE_IOS(6_0)
{
    if (!tableView.visibleCells || tableView.visibleCells.count <= 0)
        return;
    
    MDQuestionCell *queCell = tableView.visibleCells.firstObject;
    
    NSIndexPath *index = [tableView indexPathForCell:queCell];
    if (!self.dataList || index.row >= self.dataList.count)
        return;
    
    //    NSDictionary *questionData = [_queList objectAtIndex:index.row];
    //    NSNumber *timestamp = [questionData nonNullValueForKeyPath:@"question.update_time"];
    //
    //    [self setMonthFloatText:timestamp];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.dataList.count;
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 0)
        return 0;
    
    return 60.0f;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 0) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    MDQuestionCell *cell = nil;
    
    // 3. “返回结果”的题目
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (indexPath.row < self.dataList.count) {
        [cell setData:[self.dataList objectAtIndex:indexPath.row]];
    }
    //cell.backgroundColor = [UIColor redColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        [self enableDeleteBtn:YES];
        return;
    }
    
    if (indexPath.section > 0 || indexPath.row >= self.dataList.count)
        return;

    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MDQuestionData *cellData = [self.dataList objectAtIndex:indexPath.row];
    
    MDQeustionDetailViewController *detailController = [[MDQeustionDetailViewController alloc] initWithNibName:XXBRSRC_NAME(@"MDQeustionDetailViewController") bundle:XXBFRAMEWORK_BUNDLE]; //[self.storyboard instantiateViewControllerWithIdentifier:@"MDQeustionDetailViewController"];
    
    detailController.imageId = cellData.imageID; //[data nonNullValueForKeyPath:@"question.image_id"];
    detailController.updateTime = [NSNumber numberWithDouble:cellData.updateTime.timeIntervalSince1970 * 1000]; //[data nonNullValueForKeyPath:@"question.update_time"];

    // 如果有新音频，将新音频的QuestionID传递进去
    if (cellData.hasNewAudio && cellData.audioNewQuestionID > 0) {
        detailController.audioNewQuestionID = cellData.audioNewQuestionID;
    }

    [self.navigationController pushViewController:detailController animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        NSArray *selectedCells = tableView.indexPathsForSelectedRows;
        if (!selectedCells || selectedCells.count <= 0) {
            [self enableDeleteBtn:NO];
        }
        
        return;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

// Override to support editing(delete only) the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //call delete api
        MDQuestionData *cellData = [self.dataList objectAtIndex:indexPath.row];

        [self deleteQuestion:cellData.imageID callBack:^(id response) {
            if (self.dataList.count==0) {
                return ;
            }

            //[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.dataList removeObject:cellData];
            [self.tableView reloadData];
            
            [self switchEmptyDisplay:(self.dataList.count == 0)];
        }];
    }
}



-(void)deleteQuestion:(NSString *)imageId callBack:(void(^)(id response))callBack
{
    if (imageId==nil || imageId.length==0) {
        MDLog(@"imageid is nil");
        return;
    }
    
    [SVProgressHUD showMDBusying];
    
    [[MDXuexiBaoAPI sharedInstance] deleteQuestion:imageId success:^(id responseObject) {
        [SVProgressHUD dismiss];
        if (IsResponseOK(responseObject)) {
            if (callBack) {
                callBack(responseObject);
            }
            [SVProgressHUD showStatus:@"已成功删除提问"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showStatus:NSLocalizedString(@"network_error", @"")];
    }];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)takeSubPhotoBtnClicked:(id)sender {
    [self showCameraController];
}

- (void)showCameraController
{
    [TalkingData trackEvent:EVENT_SUB_CAM_OPEN];

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




@end




