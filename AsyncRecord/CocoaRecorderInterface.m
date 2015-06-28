//
//  CocoaRecorderInterface.m
//  CocoaAsynRecord
//
//  Created by 李鑫 on 14/11/16.
//  Copyright (c) 2014年 TKingLee. All rights reserved.
//

#import "CocoaRecorderInterface.h"
#import "CocoaRecorderEngine.h"


@implementation CocoaRecorderInterface
+ (CocoaRecorderEngine *)sharedRecorder{
    static dispatch_once_t onceToken;
    static CocoaRecorderEngine *recorder_engine;
    dispatch_once(&onceToken, ^{
        recorder_engine = [[CocoaRecorderEngine alloc] init];
    });
    
    return recorder_engine;
}

+ (void)startRecorder:(RecorderCallBack)callBack{
    [[CocoaRecorderInterface sharedRecorder] startRecordWithInputCallBack:^(double lowPassValue) {
        if(callBack)
        {
            callBack(lowPassValue);
        }
    }];
}
+ (void)PauseRecord{
    [[CocoaRecorderInterface sharedRecorder] PauseRecord:YES];
}
+ (void)StopRecord{
    [[CocoaRecorderInterface sharedRecorder] StopRecord:YES];
}
+ (void)ResetRecord{
    [[CocoaRecorderInterface sharedRecorder] ResetRecord];
}
@end

