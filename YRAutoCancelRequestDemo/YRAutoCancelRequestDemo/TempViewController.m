//
//  TempViewController.m
//  YRAutoCancelRequestDemo
//
//  Created by YueRuo on 2017/11/22.
//  Copyright © 2017年 YueRuo. All rights reserved.
//

#import "TempViewController.h"
#import "NSObject+AutoCancelRequest.h"

@interface TempViewController ()

@end

@implementation TempViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:@"http://img-arch.pconline.com.cn/images/upload/upc/tx/photoblog/1311/17/c0/28704978_28704978_1384619788578.jpg"] completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"-->>response = %@ , error = %@",response,error);
    }];
    [task resume];
    [self autoCancelRequestOnDealloc:task];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
