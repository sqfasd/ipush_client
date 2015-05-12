# xcomet ios library
xcomet iOS连接lib

## 依赖第三方库

	* CocoaLumberjack
	* GCNetworkReachability
	* GCDAsyncSocket
  这三个依赖库都已经build进framework里，无需再添加到工程里

## 集成方法

1. 选择你的Project文件->BuildPhrases->Link Binary With Libraries,添加以下lib：
   
   * SystemConfiguration.framework
   * CFNetwork.framework
   * Add Other...->选择 xcomet.framework

2. 在需要使用的文件中
   
   		#import  <xcomet/xcomet.h>
   		
3. 初始化:

	    _xclient = [[XClient alloc] init];
    	_xclient.enableBackgroundingOnSocket = YES;//允许后台运行
    	[_xclient addDelegate:self delegateQueue:dispatch_get_main_queue()];
   		
3. connect：

		    _xclient.hostName=@"182.92.113.188";
    		_xclient.hostPort=9000;
   			_xclient.username= @"user527";
    		_xclient.password = @"pwd520";****
    		NSError *error = nil;
    		if (![_xclient connectWithTimeout:XClientTimeoutNone error:&error])
    		{
        		NSLog(@"Error connecting: %@", error);
    		}
    		
4. 代理方法 XClientDelegate

		/**
		 * This method is called after the client has been connected  
		 * if error is nil, auzhorized successfull
		 * if error is not nil, auzhorized failed.
		 **/
		- (void)xclientDidConnect:(XClient *)sender withError:(NSError *)error;
		/**
		 * This method is called after the client has reveived a message.
		 **/
		- (void)xclient:(XClient *)sender didReceiveMessage:(XCMessage *)message;
		/**
		 * This method is called after the client has reveived a message that be parsed or an err response.
		 **/
		- (void)xclient:(XClient *)sender didReceiveError:(NSError *)error;
		/**
		 * This method is called after the client is closed.
		 **/
		- (void)xclientDidDisconnect:(XClient *)sender withError:(NSError *)error; 
   		
   		

    		
 