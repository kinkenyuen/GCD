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

> 注意：**异步执行（async）**虽然具有开启新线程的能力，但是并不一定开启新线程。这跟任务所指定的队列类型有关

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
/** * 异步执行 + 串行队列 * 特点：会开启新线程，但是因为任务是串行的，执行完一个任务，再执行下一个任务。 */+ (void)asyncToSerial {    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程    NSLog(@"asyncSerial---begin");        dispatch_queue_t queue = dispatch_queue_create("com.kk.testQueue", DISPATCH_QUEUE_SERIAL);        dispatch_async(queue, ^{        // 追加任务 1        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程    });    dispatch_async(queue, ^{        // 追加任务 2        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程    });    dispatch_async(queue, ^{        // 追加任务 3        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程    });        NSLog(@"asyncSerial---end");}2021-07-26 21:21:00.778083+0800 GCD[2423:85536] currentThread---<NSThread: 0x6000033d8780>{number = 1, name = main}2021-07-26 21:21:00.778255+0800 GCD[2423:85536] asyncSerial---begin2021-07-26 21:21:00.778381+0800 GCD[2423:85536] asyncSerial---end2021-07-26 21:21:02.779482+0800 GCD[2423:85821] 1---<NSThread: 0x6000033f1740>{number = 6, name = (null)}2021-07-26 21:21:04.782653+0800 GCD[2423:85821] 2---<NSThread: 0x6000033f1740>{number = 6, name = (null)}2021-07-26 21:21:06.787764+0800 GCD[2423:85821] 3---<NSThread: 0x6000033f1740>{number = 6, name = (null)}
```

### 异步执行 + 并发队列

可以开启多个线程，任务交替（同时）执行

```objective-c
/** * 异步执行 + 并发队列 * 特点：可以开启多个线程，任务交替（同时）执行。 */+ (void)asyncToConcurrent {    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程    NSLog(@"asyncConcurrent---begin");        dispatch_queue_t queue = dispatch_queue_create("com.kk.testQueue", DISPATCH_QUEUE_CONCURRENT);        dispatch_async(queue, ^{        // 追加任务 1        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程    });        dispatch_async(queue, ^{        // 追加任务 2        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程    });        dispatch_async(queue, ^{        // 追加任务 3        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程    });        NSLog(@"asyncConcurrent---end");}2021-07-26 21:24:35.537538+0800 GCD[2476:88726] currentThread---<NSThread: 0x6000001405c0>{number = 1, name = main}2021-07-26 21:24:35.537729+0800 GCD[2476:88726] asyncConcurrent---begin2021-07-26 21:24:35.537935+0800 GCD[2476:88726] asyncConcurrent---end2021-07-26 21:24:37.540399+0800 GCD[2476:88840] 3---<NSThread: 0x600000104f40>{number = 5, name = (null)}2021-07-26 21:24:37.540399+0800 GCD[2476:88846] 2---<NSThread: 0x600000108380>{number = 3, name = (null)}2021-07-26 21:24:37.540401+0800 GCD[2476:88843] 1---<NSThread: 0x60000014bf00>{number = 7, name = (null)}
```

### 异步执行 + 主队列

```objective-c
/** * 异步执行 + 主队列 * 特点：只在主线程中执行任务，执行完一个任务，再执行下一个任务 */+ (void)asyncToMain {    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程    NSLog(@"asyncMain---begin");        dispatch_queue_t queue = dispatch_get_main_queue();        dispatch_async(queue, ^{        // 追加任务 1        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程    });        dispatch_async(queue, ^{        // 追加任务 2        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程    });        dispatch_async(queue, ^{        // 追加任务 3        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程    });        NSLog(@"asyncMain---end");}2021-07-26 21:32:25.068658+0800 GCD[2565:93879] currentThread---<NSThread: 0x60000110c580>{number = 1, name = main}2021-07-26 21:32:25.068782+0800 GCD[2565:93879] asyncMain---begin2021-07-26 21:32:25.068905+0800 GCD[2565:93879] asyncMain---end2021-07-26 21:32:27.083046+0800 GCD[2565:93879] 1---<NSThread: 0x60000110c580>{number = 1, name = main}2021-07-26 21:32:29.084549+0800 GCD[2565:93879] 2---<NSThread: 0x60000110c580>{number = 1, name = main}2021-07-26 21:32:31.086077+0800 GCD[2565:93879] 3---<NSThread: 0x60000110c580>{number = 1, name = main}
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

