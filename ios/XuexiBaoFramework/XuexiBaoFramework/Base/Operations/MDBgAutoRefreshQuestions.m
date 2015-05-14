//
//  MDBgAutoRefreshQuestions.m
//  education
//
//  Created by Tim on 14-11-6.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDBgAutoRefreshQuestions.h"




@interface MDBgAutoRefreshQuestions ()

{
    dispatch_semaphore_t semaphore;
    dispatch_queue_t queue;
    int loopI;
}

@property (nonatomic, strong) NSArray *arrayIntervals;

@end



@implementation MDBgAutoRefreshQuestions

- (id)init
{
    self = [super init];
    if (self) {
        semaphore = dispatch_semaphore_create(1);
        loopI = 0;
    }
    
    return self;
}

- (void)dealloc
{
    loopI = 5;
    dispatch_semaphore_signal(semaphore);
}

- (void)reset
{
    MDLog(@"BGAutoRefresh reset enter");
    
    if (loopI == 0) {
        MDLog(@"BGAutoRefresh reset loopi zero");
        return;
    }
    
    loopI = 0;
    MDLog(@"BGAutoRefresh reset set loopi %i", loopI);
    
    dispatch_semaphore_signal(semaphore);
    MDLog(@"BGAutoRefresh reset after signal");
}

- (void)signal
{
    NSInteger count = [[MDCoreDataUtil sharedInstance] queCountOfSubProcessing];
    if (count <= 1) {
        loopI = 5;
        dispatch_semaphore_signal(semaphore);
    }
}

- (void)main
{
    queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0UL);
    MDLog(@"BGAutoRefresh enter main");
    
    for (; loopI < 5;) {
        MDLog(@"BGAutoRefresh enter loop %i", loopI);
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        MDLog(@"BGAutoRefresh pass wait %i", loopI);
        
        if (loopI >= 5) {
            return;
        }
        
        dispatch_async(queue,^{
            MDLog(@"BGAutoRefresh enter async queue %i", loopI);
            
            if(loopI < 5){
                int loopInt = [((NSNumber *)[self.arrayIntervals objectAtIndex:loopI]) intValue];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, loopInt * NSEC_PER_SEC), queue, ^{
                    MDLog(@"BGAutoRefresh dispatch_after %d", loopI);
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        MDLog(@"BGAutoRefresh post ntf mainqueue");
                        // show label on screen
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REFRESH_QUESTIONLIST object:nil];
                    });
                    
                    loopI++;
                    MDLog(@"BGAutoRefresh increase loopi %i", loopI);

                    dispatch_semaphore_signal(semaphore);
                    MDLog(@"BGAutoRefresh after signal");
                });
            }
        });
    }
}


#pragma mark -
#pragma mark - Properties
- (NSArray *)arrayIntervals
{
    if (!_arrayIntervals) {
        _arrayIntervals = [NSArray arrayWithObjects:@(5), @(10), @(20), @(60), @(120), nil];
    }
    
    return _arrayIntervals;
}

@end




