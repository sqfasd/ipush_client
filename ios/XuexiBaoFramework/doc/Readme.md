							学习宝SDK（iOS端）说明文档

一. LOTLib 是SDK中的核心类

1. 所有关于LOTLib的操作，都通过sharedInstance方法发起，LOTLib维护一个全局单例

		// 引用XuexiBaoFramework头文件
		#import <XuexiBaoFramework/XuexiBaoFramework.h>
		
			
		// 尽可能早得调用这个接口，对SDK进行初始化，如果不调用此方法，拍题功能将无法正常启动
		// 建议在AppDelegate的didFinishLaunchingWithOptions中调用。
		[[LOTLib sharedInstance] startWithAppKey:@"********" secret:@"********"];
 

	

二. 拍题操作：
	
1. 创建题目列表页面：
	
		// 引用XuexiBaoFramework头文件
		#import <XuexiBaoFramework/XuexiBaoFramework.h>

		
		// 将题目列表也推入页面堆栈
		[self.navigationController pushViewController:[MDQueListViewController sharedInstance] animated:YES];
	

三. 注意事项：

1. XuexiBaoFramework使用cocoapods集成了以下开源库：AFNetworking，Cordova，MagicalRecord，pop
其中“AFNetworking”所有header打包对外提供，App中如果需要使用AFNetworking，可以import如下：
		
		#import <XuexiBaoFramework/AFNetworking.h>
		
	如果App的代码中碰巧使用了以上这些开源库，请与我们联系，我们将开放出相应库的头文件。
	
	






