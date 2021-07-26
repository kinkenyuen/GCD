//
//  GCDTaskAndQueue.h
//  GCD
//
//  Created by kinken on 2021/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCDTaskAndQueue : NSObject

+ (void)syncToCurrentQueue;
+ (void)syncToSerial;
+ (void)syncToMainQueue_MainThread;

+ (void)asyncToSerial;
+ (void)asyncToConcurrent;
+ (void)asyncToMain;

@end

NS_ASSUME_NONNULL_END
