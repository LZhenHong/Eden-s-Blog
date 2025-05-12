---
title: ARC 的内存管理
date: 2017-03-14 09:39
tags: ObjC
published: true
hideInList: false
feature: 
isTop: false
---
ObjC 是使用引用计数来管理对象内存的，关于引用计数更加详细的解释，可以看 [理解 iOS 的内存管理][5]，这篇文章还讲了 ARC 下可能存在的内存管理问题。

ARC 是编译器的特性，在编译的时候自动插入管理引用计数的代码，给 ObjC 对象提供自动内存管理，并生成相应的 `dealloc` 方法。ARC 可以让你更加专注于编写代码的逻辑而不是去管理内存，但是在 ARC 下遵循 ObjC 的命名规则就显得很重要了。

<!-- more -->

## ARC 下内存管理变量关键字

在 ARC 下，虽然编译器帮我们做了大部分的内存管理的工作，但是我们还是要了解在 ARC 下的内存管理关键字。

### __strong

对一个对象进行强引用，表示拥有该对象，就像在 MRC 下进行 `retain` 是一样的，当一个对象没有强引用指针引用时，这个对象就再不被拥有，这时这个对象就会被销毁。

```
NSObject * __strong objc = [[NSObject alloc] init]; == NSObject * objc = [[NSObject alloc] init];
```

在 ARC 下，默认的指针就是强引用指针。

### __weak

对一个对象进行弱引用，不会拥有该对象，不会改变这个对象的内存周期，即不会改变该对象的引用计数。当被引用的对象被销毁时，weak 指针会自动置空，这样就可以避免野指针访问错误。常用来解决循环引用问题。

```
__typeof__(self) __weak weakSelf = self;
```

`__weak` 只在 iOS 5 以上版本可用，iOS 5 以下的版本用随后介绍的 `__unsafe_unretained`。

### __unsafe_unretained

跟 `__weak` 相似，不会拥有指向的对象。但是指向的对象被销毁时不会置 nil，就会变成悬挂指针，即会发生野指针错误。

```
__typeof__(self) __unsafe_unretained weakSelf = self;
```

在现在的 iOS 版本下，这个内存管理关键字几乎没有用处，因为 `__weak` 总是更好的选择。但是如果你想在结构体中声明一个对象的成员变量，你就需要用到这个关键字来避免 Xcode 的编译错误，但是这样你就得花精力去管理这个成员变量的内存周期，所以使用类去实现是更好的选择。

### __autoreleasing

使用这个关键字主要为了延长对象的存活周期，不要被过早的销毁。这个关键字常用来声明对象的指针。

```
NSError * __autoreleasing error = nil;
```

即使我们没有使用 `__autoreleasing` 声明，编译器还是会在编译器时期帮我们自动添加。

```mm
NSError *error; 
NSError *__autoreleasing tempError = error;
[data writeToFile:filename options:NSDataWritingAtomic error:&tempError]；
```

在这里有个问题需要注意：

```
- (BOOL)doSomethingWithDictionary:(NSDictionary *)dictionary error:(NSError * __autoreleasing *)error {
    // NSError * __block temp = nil;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        // do sth with key & obj
        if (error && [some error happened]) {
            *error = [NSError errorWithDomain:@"TestError" code:1 userInfo:nil];
            // tempError = [NSError errorWithDomain:@"TestError" code:1 userInfo:nil];
        }
    }];
    
    if (error) {
        // *error = tempError;
    }
}
```

上面的代码看着好像没有什么问题，但是在 `enumerateKeysAndObjectsUsingBlock:` 的 block 里，会自动创建一个 `@autoreleasepool {}`， 当离开此次遍历，error 就会被释放掉，最后就不能得到想要的 error 信息。

可按照上面注释掉的代码解决。

## ARC 内存管理问题

虽然 ARC 的出现让我们不需要花太多的精力在内存管理上，但是有些内存管理问题 ARC 还是没有办法处理的。例如：循环引用和 Core Foundation。

### 循环引用

循环引用就是两个对象相互强引用对方，造成两个对象都不能被释放，从而引起内存泄漏。

#### block 的循环引用

在 block 的使用中是最容易发生内存泄漏的地方，一个对象拥有这个 block，但是在这个 block 里又用到了该对象，block 会持有内部引用的对象，这样就会发生循环引用。

在 block 中有两种方式来解决循环引用的问题：

1. 主动断开循环引用：在 block 使用完，主动将 block 清空，这样就可以断开 block 对内部持有对象的强引用，也就断开了循环引用。

    ```
    self.completionBlock = nil;
    ```

2. 使用弱引用：弱引用不会影响引用对象的内存管理周期，并且在引用对象销毁时置 nil。
    
    ```
    __typeof(self) __weak weakSelf = self;
    self.completionBlock = ^{
      __typeof(weakSelf) strongSelf = weakSelf;
     if (strongSelf) {
       // do something with self
      }
    };
    ```

#### NSTimer

NSTimer Class Reference 指出 NSTimer 会强引用 target。并且官方的 Timer Programming Topics 指出： 我们不应该在 `dealloc` 中 invalidate timer。

举一个例子，我们让 timer 在我们的 ViewController 中不断调用 `handleTimer` 方法.

```
.h
@property (nonatomic, strong) NSTimer *timer;

.m
- (void)viewDidLoad {
    [super viewDidload];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
}
```

这个时候，timer 和我们的 ViewController 就是循环引用的。即使我们在 `dealloc` 方法中 invalidate timer 也是没用的。因为 timer 强引用着 VC。而 `dealloc` 是在对象销毁的时候才会被调用。

即使 VC 对 NSTimer 没有一个强引用，还是有可能会发生内存泄漏，如果一个 timer 添加到 runloop 中，runloop 会对 NSTimer 有一个强引用，如果我们不主动 invalidate timer 的话，runloop 持有 timer，timer 对 VC 也有一个强引用，就会导致内存泄漏。

> Note in particular that run loops maintain strong references to their timers, so you don’t have to maintain your own strong reference to a timer after you have added it to a run loop.

因此在使用 NSTimer 时，特别是循环的 NSTimer 时。我们需要注意在什么地方 invalidate 计时器，在上面这个例子，我们可以在 `viewWillDisappear` 里面做这样的工作。

### performSelector

在 [iOS 内存管理机制][8] 这篇文章中还提到了使用 `performSelector` 可能存在的内存泄漏。

编译器不知道即将调用的 selector 是什么，不了解方法签名和返回值，所以编译器无法用 ARC 的内存管理规则来判断返回值是否应该释放。因此，ARC 采用了比较谨慎的做法，不添加释放操作，即在方法返回对象时就可能将其持有，从而可能导致内存泄露。

### Core Foundation

ARC 不会去管理 Core Foundation 的对象，但是我们在 ARC 下编写代码也不可避免会碰到 Core Foundation 的对象，所以知道一定的 Core Foundation 内存管理对开发这很有帮助的。

关于 Core Foundation 的内存管理：[Memory Management Programming Guide for Core Foundation][11]

## ARC 下的 dealloc 方法

* 移除通知中心 (NSNotificationCenter) 的观察者：从 iOS 9 开始，不再需要移除通知中心 (NSNotificationCenter) 的观察者。如果你的 App 依然支持 iOS 8，你还是需要移除观察者。 More details: [NSNotificationCenter automatic reregistration][13]
* 移除 KVO 观察者
* 释放一些 Core Foundation 的对象

不允许主动调用此方法，runtime 会在对象被销毁之前调用此方法。当应用直接结束的时候，对象可能不会接收到 `dealloc` 方法。

在 ARC 下不需要也不允许编写 `[super dealloc];`，因为 ARC 下 runtime 会处理好父类的 `dealloc` 链；但是在 MRC 下必须要在 `dealloc` 方法的最后调用 `[super dealloc];` 来执行父类的清理操作。

## 扩展阅读

* [Simple Memory Management][4]
* [iOS夯实：内存管理][6]
* [iOS 内存管理机制][8]
* [iOS 与 OSX 内存管理：引用计数][9]

## 相关链接

* [Transitioning to ARC Release Notes][1]
* [iOS ARC 内存管理要点][2]
* [Natural Code Just Works][3]
* [Advanced Memory Management Programming Guide][12]

[1]: https://developer.apple.com/library/content/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html
[2]: http://www.samirchen.com/ios-arc/
[3]: https://iosguy.com/tag/__autoreleasing/
[4]: http://www.informit.com/articles/article.aspx?p=1765122&seqNum=7
[5]: http://blog.devtang.com/2016/07/30/ios-memory-management/
[6]: https://github.com/100mango/zen/blob/master/iOS夯实：内存管理/iOS夯实：内存管理.md
[7]: http://stackoverflow.com/questions/8056188/should-i-refer-to-self-property-in-the-init-method-with-arc/8056260#8056260
[8]: http://ibloodline.com/articles/2016/01/15/memory.html
[9]: https://segmentfault.com/a/1190000006708291
[10]: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmPractical.html#//apple_ref/doc/uid/TP40004447
[11]: https://developer.apple.com/library/content/documentation/CoreFoundation/Conceptual/CFMemoryMgmt/CFMemoryMgmt.html#//apple_ref/doc/uid/10000127i
[12]: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/MemoryMgmt.html#//apple_ref/doc/uid/10000011-SW1
[13]: https://developer.apple.com/library/content/releasenotes/Foundation/RN-Foundation/index.html#10_11NotificationCenter


