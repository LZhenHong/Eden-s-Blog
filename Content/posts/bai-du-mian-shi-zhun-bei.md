---
title: 百度面试准备
date: 2016-11-10 16:12
tags: iOS
published: true
hideInList: false
feature: 
isTop: false
---
**申明：以下知识点均来自网络，来源均在每节最前面给出，侵删。**
**感谢愿意分享知识的人 🙏🙏，是他们让我们学习了更多更好的知识。**

前一段时间准备百度面试总结的一些知识点，~~虽然面试没过 😭😭~~ 把这些东西记录下来，也方便自己以后查看。

<!-- more -->

## `+ load` 方法理解
> [你真的了解 load 方法么？][1]
> 「Effective Objective-C」Page 200

文章介绍的很详细，推荐阅读，但对面试来说，我们需要知道下面的知识应该差不多了。同时 `Effective Objective-C` 这本书的第 51 条也介绍了 `+ load` 方法。

load 作为 Objective-C 中的一个方法，与其它方法有很大的不同。它只是一个在整个文件被加载到运行时，在 main 函数调用之前被 ObjC 运行时调用的钩子方法。其中关键字有这么几个：

* 文件刚加载
* main 函数之前
* 钩子方法

由于它的调用不是惰性的，且其只会在程序调用期间调用一次，最最重要的是，如果在类与分类中都实现了 load 方法，它们都会被调用，不像其它的在分类中实现的方法会被覆盖。

load 方法并不像普通的方法那样，它并不遵从那套继承规则。如果某个类本身没实现 load 方法，那么不管其各级超类是否实现此方法，系统都不会调用。 load 方法调用顺序：

* 父类先于子类调用
* 类先于分类调用

不要在 load 方法中使用其他类，因为类的载入我们是不能确定的，所以会造成安全隐患。

load 方法务必实现得精简一些，也就是要尽量减少其所执行的操作，因为整个应用程序在执行 load 方法时都会阻塞。如果 load 方法中包含繁杂的代码，那么应用程序在执行期间就会变得无响应。不要在里面等待锁，也不要调用可能会加锁的方法。

其真正用途仅在于调试程序，比如可以在分类里编写此方法，用来判断该分类是否已经正确加载。

由于 `+ load` 方法的特殊性，我们经常会在 `+ load` 方法中进行 [Method Swizzling][3] 。

## `+ initialize` 方法理解
> [懒惰的 initialize 方法][2]
> 「Effective Objective-C」Page 202

`+ initialize` 只会在对应类的方法第一次被调用时，才会调用。如果这个类一直没有使用，这个方法就不会执行。

`+ initialize` 方法是在 `alloc` 方法之前执行完的，`alloc` 的调用导致了前者的执行。

在这个方法中，运行期系统是处于正常的状态，因此可以在此方法中调用任何类中的任意方法。

`+ initialize` 方法只应该用来设置内部数据。不应该调用其他方法。若某个全局状态无法在编译期初始化，可以放在 `+ initialize`  方法中来做。

```objectivec
// EOCClass.h
#import <Foundation/Foundation.h>

@interface EOCClass: NSObject
@end

// EOCClass.m
static const int kInterval = 10;
// 创建实例之前必须先激活运行期系统
static NSMutableArray *kSomeObjects;

@implementation

+ (void)initialize {
    if (self == [EOCClass class]) {
        kSomeObjects = [NSMutableArray array];
    }
}

@end
```

* `+ initialize` 的调用是惰性的，它会在第一次调用当前类的方法时被调用
* 与 `load` 不同，`+ initialize` 方法调用时，所有的类都已经加载到了内存中
* `+ initialize` 的运行是线程安全的
* 子类会继承父类的 `+ initialize` 方法，父类的调用先于子类。

## runtime 理解
> [Method Swizzling][3]
> [Associated Objects][4]
> [关联对象 AssociatedObject 完全解析][5]
> [轻松学习之一－－Objective-C消息转发][8]
> [Objective-C Runtime][9]

### Method Swizzling

Method swizzling 用于改变一个已经存在的 selector 的实现。这项技术使得在运行时通过改变 selector 在类的消息分发列表中的映射从而改变方法的掉用成为可能。

**swizzling 应该只在 dispatch_once 中完成**
由于 swizzling 改变了全局的状态，所以我们需要确保每个预防措施在运行时都是可用的。原子操作就是这样一个用于确保代码只会被执行一次的预防措施，就算是在不同的线程中也能确保代码只执行一次。Grand Central Dispatch 的 dispatch_once 满足了所需要的需求，并且应该被当做使用 swizzling 的初始化单例方法的标准。

实现的代码可以参考 [Method Swizzling][3] 。

### Associated Objects

在分类中 @property 并不会自动生成实例变量以及存取方法，所以一般使用关联对象为已经存在的类添加「属性」。

我们使用了两个方法 `objc_getAssociatedObject` 以及 `objc_setAssociatedObject` 来模拟「属性」的存取方法，而使用关联对象模拟实例变量。使用 @selector(categoryProperty) (即 `_cmd`) 作为 key 传入。因为这种方法省略了声明参数的代码，并且能很好地保证 key 的唯一性。

在分类中，因为类的实例变量的布局已经固定，使用 @property 已经无法向固定的布局中添加新的实例变量（这样做可能会覆盖子类的实例变量），所以我们需要使用关联对象以及两个方法来模拟构成属性的三个要素。

函数 `objc_removeAssociatedObjects` 的主要目的是在「初始状态」时方便地返回一个对象。你不应该用这个函数来删除对象的属性，因为可能会导致其他客户对其添加的属性也被移除了。规范的方法是：调用 `objc_setAssociatedObject` 方法并传入一个 nil 值来清除一个关联。[可以看这里][6]。

关联对象应用实例：[动态修改UINavigationBar的背景色][7]。

*不懂待填*：~~创建一个用于 KVO 的关联观察者~~

### 消息转发

读一下这一篇文章[轻松学习之一－－Objective-C消息转发][8]，简单易懂。

很多情况下，程序会在运行时挂掉并抛出 unrecognized selector sent to … 的异常。但在异常抛出前，Objective-C 的运行时会给你三次拯救程序的机会：

* Method resolution
    `+ (BOOL)resolveInstanceMethod:(SEL)sel`
    `+ (BOOL)resolveClassMethod:(SEL)sel`

* Fast forwarding
    `- (id)forwardingTargetForSelector:(SEL)aSelector`

* Normal forwarding
    `- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector`：如果 `-methodSignatureForSelector:` 返回 nil ，runtime 则会发出 `-doesNotRecognizeSelector:` 消息，程序这时也就挂掉了
    `- (void)forwardInvocation:(NSInvocation *)anInvocation`


Objective-C 中给一个对象发送消息会经过以下几个步骤：

1. 在对象类的 dispatch table 中尝试找到该消息。如果找到了，跳到相应的函数IMP去执行实现代码；
2. 如果没有找到，runtime 会发送 `+ resolveInstanceMethod:` 或者 `+ resolveClassMethod:` 尝试去 resolve 这个消息；
3. 如果 resolve 方法返回 NO，runtime 就发送 `- forwardingTargetForSelector:` 允许你把这个消息转发给另一个对象；
4. 如果没有新的目标对象返回， runtime 就会发送 `- methodSignatureForSelector:` 和 `- forwardInvocation:` 消息。你可以发送 `- invokeWithTarget:` 消息来手动转发消息或者发送 `- doesNotRecognizeSelector:` 抛出异常。

## Category
> [深入理解Objective-C：Category][10]
> [objc category的秘密][11]

* 可以把类的实现分开在几个不同的文件里面。这样做有几个显而易见的好处：
    * 可以减少单个文件的体积
    * 可以把不同的功能组织到不同的 category 里
    * 可以由多个开发者共同完成一个类
    * 可以按需加载想要的category
* 声明私有方法
* 模拟多继承
* 把 framework 的私有方法公开

extension 在编译期决议，它就是类的一部分，在编译期和头文件里的 @interface 以及实现文件里的 @implementation 一起形成一个完整的类，它伴随类的产生而产生，亦随之一起消亡。extension 一般用来隐藏类的私有信息，你必须有一个类的源码才能为一个类添加 extension，所以你无法为系统的类比如 NSString 添加 extension。

但是 category 则完全不一样，它是在运行期决议的。
就 category 和 extension 的区别来看，我们可以推导出一个明显的事实，extension 可以添加实例变量，而 category 是无法添加实例变量的（因为在运行期，对象的内存布局已经确定，如果添加实例变量就会破坏类的内部布局，这对编译型语言来说是灾难性的）。

怎么调用到原来类中被 category 覆盖掉的方法？
对于这个问题，我们已经知道 category 其实并不是完全替换掉原来类的同名方法，只是 category 在方法列表的前面而已，所以我们只要顺着方法列表找到最后一个对应名字的方法。

## iOS 内存管理
> [理解 iOS 的内存管理][12]

**弱引用的实现原理**

弱引用的实现原理是这样，系统对于每一个有弱引用的对象，都维护一个表来记录它所有的弱引用的指针地址。这样，当一个对象的引用计数为 0 时，系统就通过这张表，找到所有的弱引用指针，继而把它们都置成 nil。

从这个原理中，我们可以看出，弱引用的使用是有额外的开销的。虽然这个开销很小，但是如果一个地方我们肯定它不需要弱引用的特性，就不应该盲目使用弱引用。举个例子，有人喜欢在手写界面的时候，将所有界面元素都设置成 weak 的，这某种程度上与 Xcode 通过 Storyboard 拖拽生成的新变量是一致的。但是我个人认为这样做并不太合适。因为：

1. 我们在创建这个对象时，需要注意临时使用一个强引用持有它，否则因为 weak 变量并不持有对象，就会造成一个对象刚被创建就销毁掉。
2. 大部分 ViewController 的视图对象的生命周期与 ViewController 本身是一致的，没有必要额外做这个事情。
3. 早先苹果这么设计，是有历史原因的。在早年，当时系统收到 Memory Warning 的时候，ViewController 的 View 会被 unLoad 掉。这个时候，使用 weak 的视图变量是有用的，可以保持这些内存被回收。但是这个设计已经被废弃了，替代方案是将相关视图的 CALayer 对应的 CABackingStore 类型的内存区会被标记成 volatile 类型。

## UIWindow
> [分析UIWindow][13]
> [UIWindow - Apple Developer][14]
> [View Programming Guide for iOS][15]

UIWindow 一旦被创建就会被添加到整个界面上。Xcode 创建的新项目使用 Storyboard，Storyboard 需要使用 AppDelegate 提供的 window 对象，Xcode 创建的模版自动提供该 window。Window 不展示自身，通常保留 rootViewController 的 view。不使用 Storyboard 的项目需要手动创建 UIWindow 对象，让 AppDelegate 引用这个对象，并调用 `-makeKeyAndVisible` 设成 app 的 keyWindow。

每一个 controller 都会被 UIWindow 接管，UIWindow 一次只能接管一个 controller。

UIWindow 会在一个 controller 的 `- viewDidAppear` 方法中才接管了当前 controller，而不是在`- viewDidLoad` 方法中。

UIWindow 有着比一切 controller 都要高的优先级显示权利，加载在 UIWindow 上面的 View 是不会被遮挡住的。keyWindow 是指定的用来接收键盘以及非触摸类的消息，而且程序中每一个时刻只能有一个 window 是 keyWindow。

UIWindow的主要功能：

* 提供一个区域来显示 views
* 发送 events 给 views

[1]: http://draveness.me/load/
[2]: http://draveness.me/initialize/
[3]: http://nshipster.cn/method-swizzling/
[4]: http://nshipster.cn/associated-objects/
[5]: http://draveness.me/ao/
[6]: http://weibo.com/3321824014/EcKe666en?type=comment/
[7]: http://tech.glowing.com/cn/change-uinavigationbar-backgroundcolor-dynamically/
[8]: http://www.jianshu.com/p/1bde36ad9938/
[9]: http://tech.glowing.com/cn/objective-c-runtime/
[10]: http://tech.meituan.com/DiveIntoCategory.html
[11]: http://blog.sunnyxx.com/2014/03/05/objc_category_secret/
[12]: http://blog.devtang.com/2016/07/30/ios-memory-management/
[13]: http://www.cnblogs.com/YouXianMing/p/3811741.html
[14]: https://developer.apple.com/documentation/uikit/uiwindow?language=objc
[15]: https://developer.apple.com/library/content/documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/CreatingWindows/CreatingWindows.html
