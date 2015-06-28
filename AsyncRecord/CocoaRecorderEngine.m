//
//  CocoaRecorderEngine.m
//  CocoaAsynRecord
//
//  Created by 李鑫 on 14/11/21.
//  Copyright (c) 2014年 TKingLee. All rights reserved.
//

#import "CocoaRecorderEngine.h"

#import <AVFoundation/AVAudioSession.h>

#define kNumberBuffers      3

#define t_sample             SInt16

#define kSamplingRate       1000000
#define kNumberChannels     1
#define kBitsPerChannels    (sizeof(t_sample) * 8)
#define kBytesPerFrame      (kNumberChannels * sizeof(t_sample))
//#define kFrameSize          (kSamplingRate * sizeof(t_sample))
#define kFrameSize          1000

//A custom structure for a recording audio queue
//static const int kNumberBuffers = 3;
struct AQRecorderState{
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    AudioFileID mAudioFile;
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    bool mIsRunning;
};
typedef struct AQRecorderState AQRecorderState;

InputCallBack block;

@implementation CocoaRecorderEngine
{
    AQRecorderState aqData;
}
#pragma mark - Code -> Init
/**
 *  Init the Recorder Engine
 *
 *  @return Recorder Instance
 */
- (id)init{
    self = [super init];
    
    if(self)
    {
        
        aqData.mDataFormat.mSampleRate = kSamplingRate;
        aqData.mDataFormat.mFormatID = kAudioFormatLinearPCM;
        aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger |kLinearPCMFormatFlagIsPacked;
        aqData.mDataFormat.mFramesPerPacket = 1;
        aqData.mDataFormat.mChannelsPerFrame = kNumberChannels;
        
        aqData.mDataFormat.mBitsPerChannel = kBitsPerChannels;
        
        aqData.mDataFormat.mBytesPerPacket = kBytesPerFrame;
        aqData.mDataFormat.mBytesPerFrame = kBytesPerFrame;
        
        AudioFileTypeID fileType = kAudioFileAIFFType;
        //    aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        
        
        //Creating a recording audio queue
        int aqCreateStatus = AudioQueueNewInput(&aqData.mDataFormat,
                                                HandleInputBuffer,
                                                &aqData,
                                                NULL,
                                                kCFRunLoopCommonModes,
                                                0,
                                                &aqData.mQueue);
        [CocoaRecorderEngine LogOSStatus:aqCreateStatus];
        
        //Getting the audio format from an audio queue
        UInt32 dataFormatSize = sizeof(aqData.mDataFormat);
        
        AudioQueueGetProperty(aqData.mQueue,
                              kAudioQueueProperty_StreamDescription,
                              &aqData.mDataFormat,
                              &dataFormatSize);
        
        //Creating an audio file for recording
        //    CFStringRef urlString = CFSTR("http://www.apple.com/");
        //    CFURLRef audioFile = CFURLCreateWithString(kCFAllocatorDefault, urlString, NULL);
        
        NSString *filePathString = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *filePathURLString = [filePathString stringByAppendingPathComponent:@"RecordFile.caf"];
        const char *filePath = [filePathURLString UTF8String];
        
        CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
                                                                        (const UInt8 *)filePath,
                                                                        strlen(filePath) ,
                                                                        false);
        
        AudioFileCreateWithURL(audioFileURL,
                               fileType,
                               &aqData.mDataFormat,
                               kAudioFileFlags_EraseFile,
                               &aqData.mAudioFile);
        
        //Setting an audio queue buffer size
        DeriveBufferSize(aqData.mQueue,
                         aqData.mDataFormat,
                         0.5,
                         &aqData.bufferByteSize);
        
        //Preparing a set of audio queue buffers
        for (int i = 0; i < kNumberBuffers; ++i) {
            int aqAllocStatus = AudioQueueAllocateBuffer(aqData.mQueue,
                                                         aqData.bufferByteSize,
                                                         &aqData.mBuffers[i]);
            
            int aqEnqueueStatus = AudioQueueEnqueueBuffer(aqData.mQueue,
                                                          aqData.mBuffers[i],
                                                          0,
                                                          NULL);
            
            [CocoaRecorderEngine LogOSStatus:aqAllocStatus];
            [CocoaRecorderEngine LogOSStatus:aqEnqueueStatus];
        }
        
        //Recording audio
        aqData.mCurrentPacket = 0;
        aqData.mIsRunning = true;
        
        //Turn Audio Queue Check
        UInt32 trueValue = true;
        UInt32 sizeOfEnableProperty = sizeof(UInt32);
        AudioQueueSetProperty(aqData.mQueue, kAudioQueueProperty_EnableLevelMetering, &trueValue, sizeOfEnableProperty);
        
        
        BOOL avAudioSucc = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        
        [[AVAudioSession sharedInstance]setActive:YES error:nil];
        NSLog(@"AVAudioSession Change Success %d",avAudioSucc);
    }
    
    return self;
}
#pragma mark - Interface -> Start Record
- (void)startRecordWithInputCallBack:(InputCallBack)callBack{
    block = callBack;
    int aqStatus = AudioQueueStart(aqData.mQueue, NULL);
    [CocoaRecorderEngine LogOSStatus:aqStatus];
}
#pragma mark - Interface -> Pause Record
- (void)PauseRecord:(BOOL)inImmediate{
    int aqStatus = AudioQueuePause(aqData.mQueue);
    [CocoaRecorderEngine LogOSStatus:aqStatus];
}
#pragma mark - Interface -> Stop Record
- (void)StopRecord:(BOOL)inImmediate{
    int aqStatus = AudioQueueStop(aqData.mQueue,inImmediate);
    [CocoaRecorderEngine LogOSStatus:aqStatus];
}
- (void)ResetRecord{
    int aqStatus = AudioQueueReset(aqData.mQueue);
    [CocoaRecorderEngine LogOSStatus:aqStatus];
    id newTarget = [self init];
    NSLog(@"%@",newTarget);
}
#pragma mark - Core -> Record Interruption CB
void interruptionListenerCallback (void *                  inClientData,
                                   UInt32                  inInterruptionState)
{
    NSLog(@"inInterruptionState status %d",(unsigned int)inInterruptionState);
}
#pragma mark - Core -> Record Input Buffer CB

static void HandleInputBuffer(
                              void *                          aqData,
                              AudioQueueRef                   inAQ,
                              AudioQueueBufferRef             inBuffer,
                              const AudioTimeStamp *          inStartTime,
                              UInt32                          inNumberPacketDescriptions,
                              const AudioStreamPacketDescription *inPacketDescs)
{
    AQRecorderState *pAqData = (AQRecorderState *) aqData;
    
    if (inNumberPacketDescriptions == 0 && pAqData->mDataFormat.mBytesPerPacket != 0) {
        inNumberPacketDescriptions = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    }
    if (AudioFileWritePackets(pAqData->mAudioFile,
                              false,
                              inBuffer->mAudioDataByteSize,
                              inPacketDescs,
                              pAqData->mCurrentPacket,
                              &inNumberPacketDescriptions,
                              inBuffer->mAudioData) == noErr) {
        pAqData->mCurrentPacket += inNumberPacketDescriptions;
    }
    if (pAqData->mIsRunning == 0) {
        return;
    }
    
    AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, 0, NULL);
    
    CaculatePower(pAqData->mQueue, &pAqData->mDataFormat);
};

#pragma mark - Core -> Record Caculate Power
 void CaculatePower (AudioQueueRef inAQ,const AudioStreamBasicDescription *streamDes)
{
    UInt32 dataSize = sizeof(AudioQueueLevelMeterState) * streamDes->mChannelsPerFrame;
    AudioQueueLevelMeterState *levels = (AudioQueueLevelMeterState*)malloc(dataSize);
    OSStatus rc = AudioQueueGetProperty(inAQ, kAudioQueueProperty_CurrentLevelMeter, levels, &dataSize);
    if(rc != 0)
    {
        [CocoaRecorderEngine LogOSStatus:rc];
    }
    
    if(block)
    {
        block(levels->mAveragePower);
    }
    //NSLog(@"%f",levels->mAveragePower);
    //return levels->mAveragePower;
}
#pragma mark - Core -> Record Buffer Deriving CB
//Deriving a recording audio queue buffer size
void DeriveBufferSize (
                       AudioQueueRef                audioQueue,                  // 1
                       AudioStreamBasicDescription  ASBDescription,             // 2
                       Float64                      seconds,                     // 3
                       UInt32                       *outBufferSize               // 4
) {
    static const int maxBufferSize = 0x50000;                 // 5
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;       // 6
    if (maxPacketSize == 0) {                                 // 7
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               audioQueue,
                               kAudioQueueProperty_MaximumOutputPacketSize,
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    Float64 numBytesForTime = ASBDescription.mSampleRate * maxPacketSize * seconds; // 8
    *outBufferSize = (UInt32)(numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);                     // 9
}

#pragma mark - Core -> Magic Cookies Writes
//Setting a magic cookie for an audio file
OSStatus SetMagicCookieForFile(AudioQueueRef inQueue,
                               AudioFileID inFile)
{
    OSStatus result = noErr;
    UInt32 cookieSize;
    if (AudioQueueGetPropertySize(inQueue, kAudioQueueProperty_MagicCookie, &cookieSize) == noErr) {
        char *magicCookie = (char *)malloc(cookieSize);
        if (AudioQueueGetProperty(inQueue, kAudioQueueProperty_MagicCookie, magicCookie, &cookieSize) == noErr) {
            result = AudioFileSetProperty(inFile, kAudioFilePropertyMagicCookieData, cookieSize, magicCookie);
            free(magicCookie);
        }
    }
    return  result;
}

#pragma mark - Tool -> Log Error
+ (void)LogOSStatus:(OSStatus)statusCode{
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:statusCode
                                     userInfo:nil];
    NSLog(@"Audio Queue Service Error: %@", error);
}
@end
