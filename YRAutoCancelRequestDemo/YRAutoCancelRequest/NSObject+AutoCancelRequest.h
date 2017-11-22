//
//  NSObject+AutoCancelRequest.m
//
//  Created by YueRuo on 2017/3/3.
//  Copyright © 2017年 YueRuo. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 *	@brief	help to auto cancel request when vc or manager destoryed
 *
 */
@interface NSObject (AutoCancelRequest)

/*!
 *	@brief  add request to auto cancel when obj dealloc
 *  @note   will call request's cancel method , so the request must have cancel method..
 */
- (void)autoCancelRequestOnDealloc:(id)request;

@end
