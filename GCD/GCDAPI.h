//
//  GCDAPI.h
//  GCD
//
//  Created by jianqin_ruan on 2021/7/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCDAPI : NSObject

+ (void)barrier;
+ (void)after;
+ (void)apply;

+ (void)groupNotify;
+ (void)groupWait;
+ (void)groupEnterAndLeave;

+ (void)semaphoreSync;

@end

NS_ASSUME_NONNULL_END
