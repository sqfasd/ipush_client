							学习宝SDK（iOS端）说明文档

一. LOTLib 是SDK中的核心类

1. 所有关于LOTLib的操作，都通过sharedInstance方法发起，LOTLib维护一个全局单例

2. -(void)startWithAppKey:(NSString *)appKey secret:(NSString *)secret; 尽可能早得调用这个接口，对SDK进行初始化，建议在AppDelegate的didFinishLaunchingWithOptions中调用。

3. -(NSInteger)queCountOfSubUpdFailed; 题目列表获取“上传失败题目数”
	
4. -(void)queReuploadSubUpdFailed; 在用户点击题目列表中“上传失败区域”时，调用这个接口，会发起重新上传的操作
	
5. -(NSInteger)queCountOfSubProcessing; 题目列表获取“正在识别中题目数”操作
	
6. -(void)queCheckAnySubGetAnswer:(NSArray *)queList; 题目列表，在下拉刷新时需要调用这个接口，SDK会将本地保存的“上传失败”“正在识别中”等记录尽情清除。queList参数传入的是NSString数组，每一个元素代表一个image_id
	

二. 相机操作：
	
1. 创建相机：
	
	SCNavigationController *nav = [[SCNavigationController alloc] init];
	nav.scNaigationDelegate = self;
	[nav showCameraWithParentController:self isPro:YES];
	同时将一个controller注册成为“SCNavigationControllerDelegate”代理
	
2. 处理代理：
		
		- (void)didEndEditPhoto:(UIImage *)image;
		- (BOOL)willDismissNavigationController:(SCNavigationController*)navigatonController;

	客户端可以从第一个代理，拿到最终的编辑图片，可以用于自行定义的操作
	

3. XuexiBaoHeader.h
	
			
			// 题目进入“上传中”
			#define kNTF_QUE_NEW_START @"ntf_que_new_start"
			// 题目“上传失败”
			#define kNTF_QUE_NEW_UPDFAIL @"ntf_que_new_updfail"
			// 题目进入“重新上传中”
			#define kNTF_QUE_REUPLOAD @"ntf_que_reupload"
			// 通知程序刷新题目列表
			#define kNTF_REFRESH_QUESTIONLIST @"ntf_refresh_questionlist"
			
	题目列表注册四个通知，kNTF_QUE_NEW_START用于展现“上传中栏目”，kNTF_QUE_NEW_UPDFAIL用于展现“上传失败栏目”，kNTF_QUE_REUPLOAD在“上传失败的题目进入重传”时发送，客户端可以刷新题目列表；kNTF_REFRESH_QUESTIONLIST用户刷新题目列表。
	
	
	






