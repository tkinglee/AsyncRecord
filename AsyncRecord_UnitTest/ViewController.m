//
//  ViewController.m
//  AsyncRecord_UnitTest
//
//  Created by 李鑫 on 14/11/22.
//  Copyright (c) 2014年 TKingLee. All rights reserved.
//

#import "ViewController.h"

#import "CocoaAsynRecord.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [CocoaRecorderInterface startRecorder:^(double power) {
        NSLog(@"power %f",power);
    }];
}
- (IBAction)run:(id)sender {
    [CocoaRecorderInterface startRecorder:^(double power) {
        NSLog(@"power %f",power);
    }];
}
- (IBAction)Pause:(id)sender {
    [CocoaRecorderInterface StopRecord];
}
- (IBAction)Reset:(id)sender {
    [CocoaRecorderInterface ResetRecord];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
