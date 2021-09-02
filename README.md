# 目录

   * [GCD](#gcd)
      * [任务和队列](#任务和队列)
      * [使用GCD](#使用gcd)
         * [创建/获取队列](#创建获取队列)
         * [创建任务](#创建任务)
      * [任务和队列的组合方式](#任务和队列的组合方式)
         * [同步执行 + 串行队列](#同步执行--串行队列)
         * [同步执行 + 并发队列](#同步执行--并发队列)
         * [同步执行 + 主队列](#同步执行--主队列)
            * [在主线程上调用](#在主线程上调用)
            * [在非主线程上调用](#在非主线程上调用)
         * [异步执行 + 串行队列](#异步执行--串行队列)
         * [异步执行 + 并发队列](#异步执行--并发队列)
         * [异步执行 + 主队列](#异步执行--主队列)
         * [小结](#小结)
      * [队列、任务、线程之间关系的理解](#队列任务线程之间关系的理解)
      * [GCD 线程间的通信](#gcd-线程间的通信)
      * [GCD一些API方法](#gcd一些api方法)
         * [栅栏函数 dispatch_barrier_async](#栅栏函数-dispatch_barrier_async)
         * [延时执行 dispatch_after](#延时执行-dispatch_after)
         * [一次性代码（只执行一次）：dispatch_once](#一次性代码只执行一次dispatch_once)
         * [快速迭代方法：dispatch_apply](#快速迭代方法dispatch_apply)
         * [队列组：dispatch_group](#队列组dispatch_group)
            * [dispatch_group_notify](#dispatch_group_notify)
            * [dispatch_group_wait](#dispatch_group_wait)
            * [dispatch_group_enter、dispatch_group_leave](#dispatch_group_enterdispatch_group_leave)
      * [GCD信号量：dispatch_semaphore](#gcd信号量dispatch_semaphore)
         * [Dispatch Semaphore 线程同步](#dispatch-semaphore-线程同步)
         * [Dispatch Semaphore 线程安全和线程同步（为线程加锁）](#dispatch-semaphore-线程安全和线程同步为线程加锁)
   * [原文](#原文)

# GCD

##  任务和队列

* **任务**：就是执行操作的意思，换句话说就是你在线程中执行的那段代码。在 GCD 中是放在 block 中的

  执行任务有两种方式：**同步执行**、**异步执行**，主要区别是：**是否等待队列的任务执行结束，以及是否具备开启新线程的能力**

  * **同步执行(sync)**
    * 同步添加任务到指定的队列中，在添加的任务执行结束之前，会一直等待，直到队列里面的任务完成之后再继续执行
    * 只能在当前线程中执行任务，不具备开启新线程的能力
  * **异步执行(async)**
    * 异步添加任务到指定的队列中，它不会做任何等待，可以继续执行任务
    * 可以在新的线程中执行任务，具备开启新线程的能力

> 注意：异步执行(async)虽然具有开启新线程的能力，但是并不一定开启新线程。这跟任务所指定的队列类型有关

* **队列(Dispatch Queue)**：这里的队列指执行任务的等待队列，即用来存放任务的队列

  队列是一种特殊的线性表，采用 `FIFO`（先进先出）的原则，即新任务总是被插入到队列的末尾，而读取任务的时候总是从队列的头部开始读取。每读取一个任务，则从队列中释放一个任务

  在 GCD 中有两种队列：**串行队列** 和 **并发队列**。两者都符合 `FIFO`（先进先出）的原则。两者的主要区别是：**执行顺序不同，以及开启线程数不同**

  * **串行队列(Serial Dispatch Queue)**：

    * 每次只有一个任务被执行。让任务一个接着一个地执行（只开启一个线程，一个任务执行完毕后，再执行下一个任务）

  * **并发队列(Concurrent Dispatch Queue)**：

    * 可以让多个任务并发(同时)执行(可以开启多个线程，并且同时执行任务)

    > **并发队列**的并发功能只有在异步方法(dispath_async)下才有效

## 使用GCD

1. 创建队列
2. 将任务追加到所需的等待队列中

系统会根据任务类型执行任务(同步执行或异步执行)

### 创建/获取队列

```objective-c
// 串行队列
dispatch_queue_create("com.kk.serialQueue", DISPATCH_QUEUE_SERIAL);

// 并发队列
dispatch_queue_create("com.kk.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
```

* 参数1：队列唯一标识符
* 参数2：队列类型

---

对于串行队列，GCD提供一种特殊的串行队列：**主队列**

* **所有放在主队列的任务，都会在主线程中执行**
* 使用`dispatch_get_main_queue()`来获取主队列

```objective-c
dispatch_get_main_queue();
```

---

对于并发队列，GCD提供一个**全局并发队列**

* 使用`dispatch_get_global_queue`来获取全局并发队列
  * 参数1：队列优先级，一般使用`DISPATCH_QUEUE_PRIORITY_DEFAULT`
  * 参数2：保留标记，传**0**即可

```objective-c
dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
```

### 创建任务

```objective-c
// 同步执行任务创建方法
dispatch_sync(queue, ^{
    // 这里放同步执行任务代码
});

// 异步执行任务创建方法
dispatch_async(queue, ^{
    // 这里放异步执行任务代码
});
```

## 任务和队列的组合方式

既然我们有两种队列（串行队列 / 并发队列），两种任务执行方式（同步执行 / 异步执行），那么我们就有了四种不同的组合方式。这四种不同的组合方式是：

* **同步执行 + 串行队列**

* **同步执行 + 并发队列**
* **异步执行 + 串行队列**
* **异步执行 + 并发队列**

实际上，刚才还说了两种特殊队列：**全局并发队列**、**主队列**。**全局并发队列可以作为普通并发队列来使用**。**但是主队列因为有点特殊，所以我们就又多了两种组合方式**。这样就有六种不同的组合方式了

* **同步执行 + 主队列**
* **异步执行 + 主队列**

### 同步执行 + 串行队列

在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务

```objective-c
/**
 * 同步执行 + 串行队列
 * 特点：在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务
 */
+ (void)syncToSerial {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncSerial---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("com.kk.testQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"syncSerial---end");
}

2021-07-26 21:01:30.585781+0800 GCD[2162:71082] currentThread---<NSThread: 0x6000007305c0>{number = 1, name = main}
2021-07-26 21:01:30.585975+0800 GCD[2162:71082] syncSerial---begin
2021-07-26 21:01:32.585205+0800 GCD[2162:71082] 1---<NSThread: 0x6000007305c0>{number = 1, name = main}
2021-07-26 21:01:34.585459+0800 GCD[2162:71082] 2---<NSThread: 0x6000007305c0>{number = 1, name = main}
2021-07-26 21:01:36.584936+0800 GCD[2162:71082] 3---<NSThread: 0x6000007305c0>{number = 1, name = main}
2021-07-26 21:01:36.585126+0800 GCD[2162:71082] syncSerial---end
```

### 同步执行 + 并发队列

```objective-c
/**
 * 同步执行 + 并发队列
 * 特点：在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务
 */
+ (void)syncToCurrentQueue {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncConcurrent---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("com.kk.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"syncConcurrent---end");
}

2021-07-26 20:50:25.524441+0800 GCD[2005:62578] currentThread---<NSThread: 0x600003af4540>{number = 1, name = main}
2021-07-26 20:50:25.524601+0800 GCD[2005:62578] syncConcurrent---begin
2021-07-26 20:50:27.524826+0800 GCD[2005:62578] 1---<NSThread: 0x600003af4540>{number = 1, name = main}
2021-07-26 20:50:29.525263+0800 GCD[2005:62578] 2---<NSThread: 0x600003af4540>{number = 1, name = main}
2021-07-26 20:50:31.525673+0800 GCD[2005:62578] 3---<NSThread: 0x600003af4540>{number = 1, name = main}
2021-07-26 20:50:31.525950+0800 GCD[2005:62578] syncConcurrent---end
```

### 同步执行 + 主队列

`同步执行 + 主队列` **在不同线程中调用结果是不一样，在主线程中调用会发生死锁问题，而在其他线程中调用则不会**

#### 在主线程上调用

```objective-c
+ (void)syncToMainQueue_MainThread {
    /**
     * 同步执行 + 主队列
     * 特点(主线程调用)：互等卡主不执行。
     * 特点(其他线程调用)：不会开启新线程，执行完一个任务，再执行下一个任务。
     */
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncMain---begin");
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"syncMain---end");
}

2021-07-26 21:11:39.174370+0800 GCD[2260:77236] currentThread---<NSThread: 0x600002d24740>{number = 1, name = main}
2021-07-26 21:11:39.174496+0800 GCD[2260:77236] syncMain---begin
(lldb) 
```

#### 在非主线程上调用

不会开启新线程，执行完一个任务，再执行下一个任务

```swift
// 开启子线程执行syncToMainQueue_MainThread方法
[NSThread detachNewThreadSelector:@selector(syncToMainQueue_MainThread) toTarget:[GCDTaskAndQueue class] withObject:nil];

2021-07-26 21:14:49.757912+0800 GCD[2299:80251] currentThread---<NSThread: 0x600003c74440>{number = 7, name = (null)}
2021-07-26 21:14:49.758065+0800 GCD[2299:80251] syncMain---begin
2021-07-26 21:14:51.771196+0800 GCD[2299:79967] 1---<NSThread: 0x600003c38680>{number = 1, name = main}
2021-07-26 21:14:53.775052+0800 GCD[2299:79967] 2---<NSThread: 0x600003c38680>{number = 1, name = main}
2021-07-26 21:14:55.776869+0800 GCD[2299:79967] 3---<NSThread: 0x600003c38680>{number = 1, name = main}
2021-07-26 21:14:55.777246+0800 GCD[2299:80251] syncMain---end
```

### 异步执行 + 串行队列

会开启新线程，但是因为任务是串行的，执行完一个任务，再执行下一个任务

```objective-c
/**
 * 异步执行 + 串行队列
 * 特点：会开启新线程，但是因为任务是串行的，执行完一个任务，再执行下一个任务。
 */
+ (void)asyncToSerial {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"asyncSerial---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("com.kk.testQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"asyncSerial---end");
}

2021-07-26 21:21:00.778083+0800 GCD[2423:85536] currentThread---<NSThread: 0x6000033d8780>{number = 1, name = main}                                                                                    2021-07-26 21:21:00.778255+0800 GCD[2423:85536] asyncSerial---begin                                                                                      2021-07-26 21:21:00.778381+0800 GCD[2423:85536] asyncSerial---end                                                                                      2021-07-26 21:21:02.779482+0800 GCD[2423:85821] 1---<NSThread: 0x6000033f1740>{number = 6, name = (null)}                                                                                    2021-07-26 21:21:04.782653+0800 GCD[2423:85821] 2---<NSThread: 0x6000033f1740>{number = 6, name = (null)}                                                                                    2021-07-26 21:21:06.787764+0800 GCD[2423:85821] 3---<NSThread: 0x6000033f1740>{number = 6, name = (null)}
```

### 异步执行 + 并发队列

可以开启多个线程，任务交替（同时）执行

```objective-c
/**
 * 异步执行 + 并发队列
 * 特点：可以开启多个线程，任务交替（同时）执行。
 */
+ (void)asyncToConcurrent {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"asyncConcurrent---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("com.kk.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"asyncConcurrent---end");
}        

2021-07-26 21:24:35.537538+0800 GCD[2476:88726] currentThread---<NSThread: 0x6000001405c0>{number = 1, name = main}
2021-07-26 21:24:35.537729+0800 GCD[2476:88726] asyncConcurrent---begin
2021-07-26 21:24:35.537935+0800 GCD[2476:88726] asyncConcurrent---end
2021-07-26 21:24:37.540399+0800 GCD[2476:88840] 3---<NSThread: 0x600000104f40>{number = 5, name = (null)}
2021-07-26 21:24:37.540399+0800 GCD[2476:88846] 2---<NSThread: 0x600000108380>{number = 3, name = (null)}
2021-07-26 21:24:37.540401+0800 GCD[2476:88843] 1---<NSThread: 0x60000014bf00>{number = 7, name = (null)}
```

### 异步执行 + 主队列

```objective-c
/**
 * 异步执行 + 主队列
 * 特点：只在主线程中执行任务，执行完一个任务，再执行下一个任务
 */
+ (void)asyncToMain {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"asyncMain---begin");
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"asyncMain---end");
}
                                                                         
2021-07-26 21:32:25.068658+0800 GCD[2565:93879] currentThread---<NSThread: 0x60000110c580>{number = 1, name = main}
2021-07-26 21:32:25.068782+0800 GCD[2565:93879] asyncMain---begin
2021-07-26 21:32:25.068905+0800 GCD[2565:93879] asyncMain---end
2021-07-26 21:32:27.083046+0800 GCD[2565:93879] 1---<NSThread: 0x60000110c580>{number = 1, name = main}
2021-07-26 21:32:29.084549+0800 GCD[2565:93879] 2---<NSThread: 0x60000110c580>{number = 1, name = main}
2021-07-26 21:32:31.086077+0800 GCD[2565:93879] 3---<NSThread: 0x60000110c580>{number = 1, name = main}
```

### 小结

| 任务类型    | 串行队列                        | 并发队列                     | 主队列                       |
| ----------- | ------------------------------- | ---------------------------- | ---------------------------- |
| 同步(sync)  | 没有开启新线程，串行执行任务    | 没有开启新线程，串行执行任务 | 死锁                         |
| 异步(async) | 有开启新线程(1条)，串行执行任务 | 有开启新线程，并发执行任务   | 没有开启新线程，串行执行任务 |

## 队列、任务、线程之间关系的理解

假设现在有 5 个人要穿过一道门禁，这道门禁总共有 10 个入口，管理员可以决定同一时间打开几个入口，可以决定同一时间让一个人单独通过还是多个人一起通过。不过默认情况下，管理员只开启一个入口，且一个通道一次只能通过一个人

* 人要穿过门禁对应是 **任务**，管理员对应是 **系统**，入口则对应**线程**
  * 5个人表示有5个任务，10个入口代表10条线程
  * **串行队列** 好比是5个人排成一条长队
  * **并发队列** 好比是5个人排成多支队伍，比如2队等等
  * **同步任务** 好比是管理员只开启了一个入口 (当前线程)
  * **异步任务** 好比是管理员同时开启了多个入口(当前线程 + 新开启的线程)
* **异步执行 + 并发队列** 可以理解为：现在管理员开启了多个入口（比如 3 个入口），5 个人排成了多支队伍（比如 3 支队伍），这样这 5 个人就可以 3 个人同时一起穿过门禁了
* **同步执行 + 并发队列** 可以理解为：现在管理员只开启了 1 个入口，5 个人排成了多支队伍。虽然这 5 个人排成了多支队伍，但是只开了 1 个入口啊，这 5 个人虽然都想快点过去，但是 1 个入口一次只能过 1 个人，所以大家就只好一个接一个走过去了，表现的结果就是：顺次通过入口
* 换成GCD的意思理解：
  * **异步执行 + 并发队列** ：系统开启了多个线程（主线程+其他子线程），任务可以多个同时运行
  * **同步执行 + 并发队列**：系统只默认开启了一个主线程，没有开启子线程，虽然任务处于并发队列中，但也只能一个接一个执行了

## GCD 线程间的通信

在 iOS 开发过程中，我们一般在主线程里边进行 UI 刷新，例如：点击、滚动、拖拽等事件。我们通常把一些耗时的操作放在其他线程，比如说图片下载、文件上传等耗时操作。而当我们有时候在其他线程完成了耗时操作时，需要回到主线程，那么就用到了线程之间的通讯

```objective-c
/**
 * 线程间通信
 */
- (void)communication {
    // 获取全局并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // 获取主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        // 异步追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
        
        // 回到主线程
        dispatch_async(mainQueue, ^{
            // 追加在主线程中执行的任务
            [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
            NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
        });
    });
}

2021-07-27 11:58:03.909889+0800 GCD[92282:6613242] 1---<NSThread: 0x6000008a0b40>{number = 7, name = (null)}
2021-07-27 11:58:05.911011+0800 GCD[92282:6601924] 2---<NSThread: 0x6000008e8140>{number = 1, name = main}
```

## GCD一些API方法

### 栅栏函数 dispatch_barrier_async

有时需要异步执行两组操作，而且第一组操作执行完之后，才能开始执行第二组操作。这样我们就需要一个相当于 `栅栏` 一样的一个方法将两组异步执行的操作组给分割起来，当然这里的操作组里可以包含一个或多个任务

```objective-c
/**
 * 栅栏方法 dispatch_barrier_async
 */
+ (void)barrier {
    dispatch_queue_t queue = dispatch_queue_create("com.kk.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_barrier_async(queue, ^{
        // 追加任务 barrier
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"barrier---%@",[NSThread currentThread]);// 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_async(queue, ^{
        // 追加任务 4
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"4---%@",[NSThread currentThread]);      // 打印当前线程
    });
}

2021-07-27 14:11:24.228252+0800 GCD[92748:6688458] 2---<NSThread: 0x600002991fc0>{number = 7, name = (null)}
2021-07-27 14:11:24.228252+0800 GCD[92748:6688459] 1---<NSThread: 0x600002988500>{number = 5, name = (null)}
2021-07-27 14:11:26.228535+0800 GCD[92748:6688459] barrier---<NSThread: 0x600002988500>{number = 5, name = (null)}
2021-07-27 14:11:28.229438+0800 GCD[92748:6688458] 4---<NSThread: 0x600002991fc0>{number = 7, name = (null)}
2021-07-27 14:11:28.229438+0800 GCD[92748:6688459] 3---<NSThread: 0x600002988500>{number = 5, name = (null)}
```

### 延时执行 dispatch_after

在指定时间（例如 3 秒）之后执行某个任务。可以用 GCD 的`dispatch_after` 方法来实现。
需要注意的是：`dispatch_after` 方法并不是在指定时间之后才开始执行处理，而是在指定时间之后将任务追加到主队列中。严格来说，这个时间并不是绝对准确的，但想要大致延迟执行任务，`dispatch_after` 方法是很有效的

```objc
/**
 * 延时执行方法 dispatch_after
 */
+ (void)after {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"asyncMain---begin");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 2.0 秒后异步追加任务代码到主队列，并开始执行
        NSLog(@"after---%@",[NSThread currentThread]);  // 打印当前线程
    });
}

2021-07-27 14:21:40.240387+0800 GCD[92866:6698685] currentThread---<NSThread: 0x6000032c81c0>{number = 1, name = main}
2021-07-27 14:21:40.240564+0800 GCD[92866:6698685] asyncMain---begin
2021-07-27 14:21:42.240978+0800 GCD[92866:6698685] after---<NSThread: 0x6000032c81c0>{number = 1, name = main}
```

###  一次性代码（只执行一次）：dispatch_once

我们在创建单例、或者有整个程序运行过程中只执行一次的代码时，我们就用到了 GCD 的 `dispatch_once` 方法。使用 `dispatch_once` 方法能保证某段代码在程序运行过程中只被执行 1 次，并且即使在多线程的环境下，`dispatch_once` 也可以保证线程安全

```objective-c
/**
 * 一次性代码（只执行一次）dispatch_once
 */
- (void)once {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 只执行 1 次的代码（这里面默认是线程安全的）
    });
}
```

### 快速迭代方法：dispatch_apply

通常我们会用 for 循环遍历，但是 GCD 给我们提供了快速迭代的方法 `dispatch_apply`。`dispatch_apply` 按照指定的次数将指定的任务追加到指定的队列中，并等待全部队列执行结束

如果是在串行队列中使用 `dispatch_apply`，那么就和 for 循环一样，按顺序同步执行。但是这样就体现不出快速迭代的意义了

我们可以利用并发队列进行异步执行。比如说遍历 0~5 这 6 个数字，for 循环的做法是每次取出一个元素，逐个遍历。`dispatch_apply` 可以 在多个线程中同时（异步）遍历多个数字

还有一点，无论是在串行队列，还是并发队列中，`dispatch_apply` 都会等待全部任务执行完毕，这点就像是同步操作

```objc
/**
 * 快速迭代方法 dispatch_apply
 */
+ (void)apply {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSLog(@"apply---begin");
    dispatch_apply(6, queue, ^(size_t index) {
        NSLog(@"%zd---%@",index, [NSThread currentThread]);
    });
    NSLog(@"apply---end");
}

2021-07-27 14:30:27.897923+0800 GCD[92937:6707029] apply---begin
2021-07-27 14:30:27.898209+0800 GCD[92937:6707831] 2---<NSThread: 0x600001dd8140>{number = 3, name = (null)}
2021-07-27 14:30:27.898209+0800 GCD[92937:6707827] 5---<NSThread: 0x600001dd68c0>{number = 5, name = (null)}
2021-07-27 14:30:27.898209+0800 GCD[92937:6707029] 0---<NSThread: 0x600001d94640>{number = 1, name = main}
2021-07-27 14:30:27.898212+0800 GCD[92937:6707828] 1---<NSThread: 0x600001ddc6c0>{number = 7, name = (null)}
2021-07-27 14:30:27.898213+0800 GCD[92937:6707825] 3---<NSThread: 0x600001dc4140>{number = 8, name = (null)}
2021-07-27 14:30:27.898215+0800 GCD[92937:6707826] 4---<NSThread: 0x600001d90fc0>{number = 6, name = (null)}
2021-07-27 14:30:27.898410+0800 GCD[92937:6707029] apply---end
```

### 队列组：dispatch_group

有时候我们会有这样的需求：**分别异步执行2个耗时任务，然后当2个耗时任务都执行完毕后再回到主线程执行任务**。这时候我们可以用到 GCD 的队列组

* 调用队列组的 `dispatch_group_async` 先把任务放到队列中，然后将队列放入队列组中。或者使用队列组的 `dispatch_group_enter`、`dispatch_group_leave` 组合来实现 `dispatch_group_async`
* 调用队列组的 `dispatch_group_notify` 回到指定线程执行任务。或者使用 `dispatch_group_wait` 回到当前线程继续向下执行（会阻塞当前线程）

#### dispatch_group_notify

监听 group 中任务的完成状态，当所有的任务都执行完成后，追加任务到 group 中，并执行任务

```objective-c
/**
 * 队列组 dispatch_group_notify
 */
+ (void)groupNotify {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"group---begin");
    
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 等前面的异步任务 1、任务 2 都执行完毕后，回到主线程执行下边任务
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程

        NSLog(@"group---end");
    });
}

2021-07-27 14:42:21.805834+0800 GCD[93013:6716602] currentThread---<NSThread: 0x600000a88280>{number = 1, name = main}
2021-07-27 14:42:21.806028+0800 GCD[93013:6716602] group---begin
2021-07-27 14:42:23.806467+0800 GCD[93013:6717151] 2---<NSThread: 0x600000acdb00>{number = 4, name = (null)}
2021-07-27 14:42:23.806467+0800 GCD[93013:6717144] 1---<NSThread: 0x600000ad1300>{number = 5, name = (null)}
2021-07-27 14:42:25.807383+0800 GCD[93013:6716602] 3---<NSThread: 0x600000a88280>{number = 1, name = main}
2021-07-27 14:42:25.807757+0800 GCD[93013:6716602] group---end
```

当所有任务都执行完成之后，才执行 `dispatch_group_notify` 相关 block 中的任务

#### dispatch_group_wait

暂停当前线程（阻塞当前线程），等待指定的 group 中的任务执行完成后，才会往下继续执行

```objective-c
/**
 * 队列组 dispatch_group_wait
 */
+ (void)groupWait {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"group---begin");
    
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    // 等待上面的任务全部完成后，会往下继续执行（会阻塞当前线程）
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"group---end");
}

2021-07-27 14:48:21.804531+0800 GCD[93064:6722033] currentThread---<NSThread: 0x60000182c300>{number = 1, name = main}
2021-07-27 14:48:21.804798+0800 GCD[93064:6722033] group---begin
2021-07-27 14:48:23.808301+0800 GCD[93064:6722569] 2---<NSThread: 0x600001829580>{number = 3, name = (null)}
2021-07-27 14:48:23.808301+0800 GCD[93064:6722567] 1---<NSThread: 0x600001869400>{number = 4, name = (null)}
2021-07-27 14:48:23.808673+0800 GCD[93064:6722033] group---end
```

#### dispatch_group_enter、dispatch_group_leave

- `dispatch_group_enter` 标志着一个任务追加到 group，执行一次，相当于 group 中未执行完毕任务数 +1
- `dispatch_group_leave` 标志着一个任务离开了 group，执行一次，相当于 group 中未执行完毕任务数 -1
- 当 group 中未执行完毕任务数为0的时候，才会使 `dispatch_group_wait` 解除阻塞，以及执行追加到 `dispatch_group_notify` 中的任务

```objective-c
/**
 * 队列组 dispatch_group_enter、dispatch_group_leave
 */
+ (void)groupEnterAndLeave {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"group---begin");
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程

        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
        
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 等前面的异步操作都执行完毕后，回到主线程.
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    
        NSLog(@"group---end");
    });
}

2021-07-27 15:13:31.313841+0800 GCD[93387:6744611] currentThread---<NSThread: 0x600003c08900>{number = 1, name = main}
2021-07-27 15:13:31.314082+0800 GCD[93387:6744611] group---begin
2021-07-27 15:13:33.319007+0800 GCD[93387:6745109] 2---<NSThread: 0x600003c58300>{number = 5, name = (null)}
2021-07-27 15:13:33.319031+0800 GCD[93387:6745112] 1---<NSThread: 0x600003c4ae40>{number = 4, name = (null)}
2021-07-27 15:13:35.320458+0800 GCD[93387:6744611] 3---<NSThread: 0x600003c08900>{number = 1, name = main}
2021-07-27 15:13:35.320810+0800 GCD[93387:6744611] group---end
```

## GCD信号量：dispatch_semaphore

GCD 中的信号量是指 **Dispatch Semaphore**，是持有计数的信号。类似于过高速路收费站的栏杆。可以通过时，打开栏杆，不可以通过时，关闭栏杆。在 **Dispatch Semaphore** 中，使用计数来完成这个功能，计数小于 0 时等待，不可通过。计数为 0 或大于 0 时，计数减 1 且不等待，可通过

**Dispatch Semaphore** 提供了三个方法：

* `dispatch_semaphore_create`：创建一个 Semaphore 并初始化信号的总量
* `dispatch_semaphore_signal`：发送一个信号，让信号总量加 1
* `dispatch_semaphore_wait`：可以使总信号量减 1，信号总量小于 0 时就会一直等待（阻塞所在线程），否则就可以正常执行

> 信号量的使用前提是：想清楚你需要处理哪个线程等待（阻塞），又要哪个线程继续执行，然后使用信号量

Dispatch Semaphore 在实际开发中主要用于：

- 保持线程同步，将异步执行任务转换为同步执行任务
- 保证线程安全，为线程加锁

### Dispatch Semaphore 线程同步

我们在开发中，会遇到这样的需求：异步执行耗时任务，并使用异步执行的结果进行一些额外的操作。换句话说，相当于，将将异步执行任务转换为同步执行任务。比如说：`AFNetworking` 中 `AFURLSessionManager.m` 里面的 `tasksForKeyPath:` 方法。通过引入信号量的方式，等待异步执行任务结果，获取到 tasks，然后再返回该 tasks

```objective-c
- (NSArray *)tasksForKeyPath:(NSString *)keyPath {
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(dataTasks))]) {
            tasks = dataTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadTasks))]) {
            tasks = uploadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(downloadTasks))]) {
            tasks = downloadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(tasks))]) {
            tasks = [@[dataTasks, uploadTasks, downloadTasks] valueForKeyPath:@"@unionOfArrays.self"];
        }

        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return tasks;
}
```

下面，我们来利用 `Dispatch Semaphore` 实现线程同步，将异步执行任务转换为同步执行任务

```objc
/**
 * semaphore 线程同步
 */
+ (void)semaphoreSync {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"semaphore---begin");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block int number = 0;
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
        
        number = 100;
        
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"semaphore---end,number = %d",number);
}

2021-07-27 15:27:30.655656+0800 GCD[93581:6758916] currentThread---<NSThread: 0x600002924540>{number = 1, name = main}
2021-07-27 15:27:30.655923+0800 GCD[93581:6758916] semaphore---begin
2021-07-27 15:27:32.659177+0800 GCD[93581:6759762] 1---<NSThread: 0x600002971940>{number = 4, name = (null)}
2021-07-27 15:27:32.659540+0800 GCD[93581:6758916] semaphore---end,number = 100
```

* semaphore 初始创建时计数为 0。
* `异步执行` 将 `任务 1` 追加到队列之后，不做等待，接着执行 `dispatch_semaphore_wait` 方法，semaphore 减 1，此时 `semaphore == -1`，当前线程进入等待状态
* 然后，异步任务 1 开始执行。任务 1 执行到 `dispatch_semaphore_signal` 之后，总信号量加 1，此时 `semaphore == 0`，正在被阻塞的线程（主线程）恢复继续执行
* 最后打印 `semaphore---end,number = 100`

这样就实现了线程同步，将异步执行任务转换为同步执行任务

### Dispatch Semaphore 线程安全和线程同步（为线程加锁）

**线程安全**：如果你的代码所在的进程中有多个线程在同时运行，而这些线程可能会同时运行这段代码。如果每次运行结果和单线程运行的结果是一样的，而且其他的变量的值也和预期的是一样的，就是线程安全的

若每个线程中对全局变量、静态变量只有读操作，而无写操作，一般来说，这个全局变量是线程安全的；若有多个线程同时执行写操作（更改变量），一般都需要考虑线程同步，否则的话就可能影响线程安全

**线程同步**：可理解为线程 A 和 线程 B 一块配合，A 执行到一定程度时要依靠线程 B 的某个结果，于是停下来，示意 B 运行；B 依言执行，再将结果给 A；A 再继续操作

举个简单例子就是：两个人在一起聊天。两个人不能同时说话，避免听不清(操作冲突)。等一个人说完(一个线程结束操作)，另一个再说(另一个线程再开始操作)

# 原文

[iOS 多线程：『GCD』详尽总结](https://bujige.net/blog/iOS-Complete-learning-GCD.html)

