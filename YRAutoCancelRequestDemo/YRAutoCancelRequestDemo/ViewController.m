//
//  ViewController.m
//  YRAutoCancelRequestDemo
//
//  Created by YueRuo on 2017/11/22.
//  Copyright © 2017年 YueRuo. All rights reserved.
//

#import "ViewController.h"
#import "TempViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)push:(id)sender {
    TempViewController *vc = [[TempViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:true];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
