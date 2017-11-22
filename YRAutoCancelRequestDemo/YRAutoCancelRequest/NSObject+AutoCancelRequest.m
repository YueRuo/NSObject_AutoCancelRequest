//
//  NSObject+AutoCancelRequest.m
//
//  Created by YueRuo on 2017/3/3.
//  Copyright © 2017年 YueRuo. All rights reserved.
//

#import "NSObject+AutoCancelRequest.h"
#import <objc/runtime.h>

@interface YRWeakRequest : NSObject
@property (weak, nonatomic) id request;
@end
@implementation YRWeakRequest
@end
@interface YRDeallocRequests : NSObject
@property (strong, nonatomic) NSMutableArray<YRWeakRequest*> *weakRequests;
@property (strong, nonatomic) NSLock *lock;
@end
@implementation YRDeallocRequests
- (instancetype)init{
    if (self = [super init]) {
        _weakRequests = [NSMutableArray arrayWithCapacity:20];
        _lock = [[NSLock alloc]init];
    }
    return self;
}
- (void)addRequest:(YRWeakRequest*)request{
    if (!request||!request.request) {
        return;
    }
    [_lock lock];
    [self.weakRequests addObject:request];
    [_lock unlock];
}
- (void)clearDeallocRequest{
    [_lock lock];
    NSInteger count = self.weakRequests.count;
    for (NSInteger i=count-1; i>0; i--) {
        YRWeakRequest *weakRequest = self.weakRequests[i];
        if (!weakRequest.request) {
            [self.weakRequests removeObject:weakRequest];
        }
    }
    [_lock unlock];
}
- (void)dealloc{
    for (YRWeakRequest *weakRequest in self.weakRequests) {
        [weakRequest.request cancel];
    }
}
@end

@implementation NSObject (YRRequest)
- (YRDeallocRequests *)deallocRequests{
    YRDeallocRequests *requests = objc_getAssociatedObject(self, _cmd);
    if (!requests) {
        requests = [[YRDeallocRequests alloc]init];
        objc_setAssociatedObject(self, _cmd, requests, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return requests;
}

- (void)autoCancelRequestOnDealloc:(id)request{
    [[self deallocRequests] clearDeallocRequest];
    YRWeakRequest *weakRequest = [[YRWeakRequest alloc] init];
    weakRequest.request = request;
    [[self deallocRequests] addRequest:weakRequest];
}
@end
