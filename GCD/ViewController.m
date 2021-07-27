//
//  ViewController.m
//  GCD
//
//  Created by kinken on 2021/7/26.
//

#import "ViewController.h"
#import "GCDTaskAndQueue.h"
#import "GCDAPI.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 主线程执行
    //    [GCDTaskAndQueue syncToSerial];
//    [GCDTaskAndQueue syncToCurrentQueue];
//    [GCDTaskAndQueue syncToMainQueue_MainThread];
    // 使用 NSThread 的 detachNewThreadSelector 方法会创建子线程，并自动启动线程执行 selector 任务
//    [NSThread detachNewThreadSelector:@selector(syncToMainQueue_MainThread) toTarget:[GCDTaskAndQueue class] withObject:nil];
//    [GCDTaskAndQueue asyncToSerial];
//    [GCDTaskAndQueue asyncToConcurrent];
//    [GCDTaskAndQueue asyncToMain];
    
    // 非主线程执行
//    [NSThread detachNewThreadSelector:@selector(syncToSerial) toTarget:[GCDTaskAndQueue class] withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(syncToCurrentQueue) toTarget:[GCDTaskAndQueue class] withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(asyncToSerial) toTarget:[GCDTaskAndQueue class] withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(asyncToConcurrent) toTarget:[GCDTaskAndQueue class] withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(asyncToMain) toTarget:[GCDTaskAndQueue class] withObject:nil];
    
    // GCD其他方法
//    [GCDAPI barrier];
//    [GCDAPI after];
//    [GCDAPI apply];
//    [GCDAPI groupNotify];
//    [GCDAPI groupWait];
//    [GCDAPI groupEnterAndLeave];
//    [GCDAPI semaphoreSync];
}

@end
