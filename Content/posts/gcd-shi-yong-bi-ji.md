---
title: GCD 使用笔记
date: 2016-09-19 10:05
tags: iOS
published: true
hideInList: false
feature: 
isTop: false
---
在我年少无知的时候其实就已经写过一篇关于 GCD 的文章，自己现在拿出来看觉得有点羞愧，发现自己对 GCD 的认识基本上还是停留在一年前的水平，所以自己开始慢慢补上 GCD 的知识。

将以前写的东西拿出来~~充字数~~提醒自己。

<!-- more -->

## 任务

GCD 中要执行的操作都可以叫做任务(下载图片、下载文本等)。

## 队列

按照 FIFO (先进先出)的顺序帮我们调度任务，GCD 会把我们添加到队列中的任务取出，放到线程中执行。队列分为：

1. 串行队列：串行队列同一时间只能有一个任务执行，后一个任务只有在前一个任务执行完之后才能被调度到线程中执行。

    ![072323111886385](https://github.com/LZhenHong/BlogImages/blob/master/072323111886385.png?raw=true)

2. 并行队列：并行队列同一时间可以多个任务执行，后一个任务不需要等前一个任务执行完，就可以被调度。

    ![072323191425022](https://github.com/LZhenHong/BlogImages/blob/master/072323191425022.png?raw=true)

## 任务的提交

任务提交的方式会决定要不要 **开启新的线程**，在 GCD 中将任务添加到队列中有两种方式：

1. **同步提交**：将任务同步提交给队列，不会开启新的线程，只会在*当前线程执行*，并且只有在同步任务执行完之后，才能继续向下执行代码，同步提交的方式：`dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);`

2. **异步提交**：任务被异步提交给队列，*会开启新的线程*，但开多少新的线程，我们不能决定，由系统自己决定，并且不需要等异步任务执行完，就可以继续向下执行代码，异步提交的方式：`dispatch_async(dispatch_queue_t queue, dispatch_block_t block);`

## GCD 中不同的提交方式与不同队列的组合

### 串行队列同步提交

```objectivec
dispatch_queue_t queue = dispatch_queue_create("com.yys.test", DISPATCH_QUEUE_SERIAL);
dispatch_sync(queue, ^{
    // 下载文件，图片等资源
});
```
    
* 首先根据同步提交 -> 没有新的线程开启。
* 然后根据串行队列的特点 -> 同一时间只能执行一个任务。
* 最终得到 -> 不会开启新的线程，任务按照提交顺序在当前线程依次执行。


### 串行队列异步提交

```objectivec
dispatch_queue_t queue = dispatch_queue_create("com.yys.test", DISPATCH_QUEUE_SERIAL);
dispatch_async(queue, ^{
    // 下载文件，图片等资源
});
```

* 根据异步提交 -> 会有新的线程开启。
* 根据串行队列的特点 -> 同一时间只能执行一个任务。
* 最终得到 -> 会开启新的线程，任务在新开启的线程中按照提交顺序依次执行，但是仅仅只会开启一条新的线程，因为异步提交会开启新的线程，但是串行队列只需要一条线程就可以执行所有提交的任务。


### 并行队列同步提交
    
```objectivec
dispatch_queue_t queue = dispatch_queue_create("com.yys.test", DISPATCH_QUEUE_CONCURRENT);
dispatch_sync(queue, ^{
    // 下载文件，图片等资源
});
```

* 根据同步提交 -> 没有新的线程开启。
* 并行队列 -> 同一时间可以有多个任务被调度，但是在同步提交的条件下，并行队列失去了并行的能力，与串行队列区别不大。
* 最终得到 -> 不会开启新的线程，提交的任务在当前线程按照提交顺序依次执行。


### 并行队列异步提交

```objectivec
dispatch_queue_t queue = dispatch_queue_create("com.yys.test", DISPATCH_QUEUE_CONCURRENT);
dispatch_async(queue, ^{
    // 下载文件，图片等资源
});
```

* 异步提交 -> 可以开启新的线程。
* 并行队列 -> 同一时间可以有多个任务被调度。
* 最终得到 -> 有新的线程开启，可以多个任务同时执行，会开多条线程，但是开多少条线程我们不能控制。所以，可以用来同时下载多张图片。

## GCD 中特别的队列：主队列(串行队列)

主队列是串行队列，它的主要作用就是用来更新 UI 控件，*所有 UI 控件的刷新都必须在主线程中执行*。

### 主队列同步提交

```objectivec
dispatch_queue_t queue = dispatch_get_main_queue();
dispatch_sync(queue, ^{
    // 下载文件，图片等资源
});
```
* 主队列同步提交任务一定会发生死锁，就是线程被阻塞，不会再继续向下执行代码。
* 同步提交使用时尤其注意，不能在当前线程再向这个线程中提交任务。
* 主线程在执行任务 A，在任务 A 中向主队列中添加任务 B，这时任务 B 会在主线程中执行，由于*主队列是串行队列*，所以任务会依次执行，任务 A 执行完就会执行任务 B，但是任务 A 要执行完则任务 B 必须也要执行完，但是任务 B 要等任务 A 执行完才能执行，因此会发生死锁，代码不会向下执行。

![主线程](https://github.com/LZhenHong/BlogImages/blob/master/%E4%B8%BB%E7%BA%BF%E7%A8%8B.png?raw=true)

### 主队列异步提交

```objectivec
dispatch_queue_t queue = dispatch_get_main_queue();
dispatch_async(queue, ^{
    // 下载文件，图片等资源
});
```

* 这一情况也是很特殊的，尽管是异步提交，但是没有新的线程开启，GCD会在恰当的时候把你提交的任务在主线程中执行完，执行的时刻不可控。

## GCD 的其他用法

### dispatch\_after: 延后执行

```objectivec
dispatch_time_t time ＝ dispatch_time(DISPATCH_TIME_NOW, (int64_t)(需要延后的时间 * NSEC_PER_SEC));
dispatch_after(time, dispatch_get_main_queue(), ^{
   // 需要延后执行的代码
});
NSLog(@"线程执行开始");
dispatch_async(dispatch_get_main_queue(), ^{
   [NSThread sleepForTimeInterval:10.];
});
dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5. * NSEC_PER_SEC));
dispatch_after(time, dispatch_get_main_queue(), ^{
   NSLog(@"延后提交任务”);
});
```

* 需要注意的是，这里并不是在某一个时刻执行任务，只是将任务提交给队列。
* 执行结果：

    ![072323514709413](https://github.com/LZhenHong/BlogImages/blob/master/072323514709413.png?raw=true)

* 这里第二次打印是在第一次打印10秒之后，并不是5秒之后。


### dispatch\_once: 只执行一次某段代码

```objectivec
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    // 只需要执行一次的代码
});
```

* 需要注意的是 onceToken 一定要用 static 申明，这样才能保证需要执行一次的代码执行一次，否则的话，不能保证代码只执行一次，会出现难以修复的 bug。


### dispatch\_group
使用场景：当你执行多个异步任务，并且要等到所有的任务执行完做某些操作时

```objectivec
dispatch_group_t group = dispatch_group_create();
dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 提交任务A
});
dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 提交任务B
});
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    // 所有任务执行完后，所需要的操作
});
```

这里有两种方式通知所有的任务完成：

* dispatch\_group\_notify 这一种是异步通知，不会阻塞当前线程(常用)
* dispatch\_group\_wait 这一种会一直等待，直到所有的任务完成或者超时


### dispatch\_barrier\_sync 和 dispatch\_barrier\_async

```objectivec
dispatch_barrier_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 提交任务
});
```

* 这两个函数提交的任务，在执行时会阻塞后面的任务，在这一时间内，只有这一任务在执行，后续任务只有在这个任务执行完成后才能执行，并且所有在这个任务之前的任务一定会先于这个任务完成。
* dispatch\_barrier\_sync 和 dispatch\_barrier\_async 只在自己创建的并发队列上有效，在全局并发队列、串行队列上，效果跟 dispatch\_sync、 dispatch\_async 效果一样。
