//
//  CocoaRecorderEngine.h
//  CocoaAsynRecord
//
//  Created by 李鑫 on 14/11/21.
//  Copyright (c) 2014年 TKingLee. All rights reserved.
//
typedef void (^InputCallBack)(double lowPassValue);
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface CocoaRecorderEngine : NSObject
/**
 *  Start Record
 *
 *  @param CallBack Block
 */
- (void)startRecordWithInputCallBack:(InputCallBack)callBack;
/**
 *  Pause Record
 *
 *  @param inImmediate if YES Pause Record Immediate or Wait for Queue Empty
 */
- (void)PauseRecord:(BOOL)inImmediate;
/**
 *  Stop Record
 *
 *  @param inImmediate if YES Stop Record Immediate or Wait for Queue Empty
 */
- (void)StopRecord:(BOOL)inImmediate;
/**
 *  engine initlzation
 *
 *  @return CocoaRecorderEngine
 */
- (void)ResetRecord;

- (id)init;
@end
