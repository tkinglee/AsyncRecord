//
//  CocoaRecorderInterface.h
//  CocoaAsynRecord
//
//  Created by 李鑫 on 14/11/16.
//  Copyright (c) 2014年 TKingLee. All rights reserved.
//
typedef void(^RecorderCallBack)(double power);
#import <Foundation/Foundation.h>

@class CocoaRecorderEngine;
@interface CocoaRecorderInterface : NSObject
/**
 *  开始异步采样进入后台也不会受到微信等程序打断
 *
 *  @param callBack 音频采样后的回调(power 音频采样的响度值)
 */
+ (void)startRecorder:(RecorderCallBack)callBack;
/**
 *  暂停音频采样
 */
+ (void)PauseRecord;
/**
 *  停止音频采样
 */
+ (void)StopRecord;

+ (void)ResetRecord;
@end
