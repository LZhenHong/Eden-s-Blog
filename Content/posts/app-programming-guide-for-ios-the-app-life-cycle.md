---
title: App Programming Guide for iOS - The App Life Cycle
date: 2016-11-03 19:50
tags: iOS
published: true
---

## The Main Function

每个基于 C 语言的程序的入口都是 main 函数，iOS App 也没有区别。开发 iOS 你不需要自己编写 main 函数，Xcode 的模版项目会自动实现，一般情况下你不需要修改 main 函数。main 函数会将控制权交给 UIKit framework。`UIApplicationMain` 函数会创建应用的核心对象，从 SB 文件中加载 UI 界面，启动 App 的 runloop 等等。

```objectivec
#import "AppDelegate.h"
 
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

关于在 Main 函数之前发生了什么，可以看这个 [iOS 程序 main 函数之前发生了什么][2]。

<!-- more -->

## The Structure of an App

每个应用的核心就是 `UIApplication` 对象，这个对象的任务就是处理系统与 App 之间的交互。

下面这张图片显示了大部分应用的对象以及这些对象扮演的角色。

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/core_objects_2x.png?raw=true' width=340 alt='Core Objects' />
<div align=left>

在上面这张图中我们可以看到 iOS 应用遵守 MVC 架构。但是 MVC 是有一定的缺陷的，各种逻辑都是由 C(控制器) 来处理的，例如作为 V(视图) 的代理，接收 M(模型) 分发的通知，这样随着业务的增长，控制器中的代码就可能会越来越多。MVVM 等其他的设计模式就这样出现了。~~扯远了 🙄🙄~~

|              Object               |                                                                                                    Description                                                                                                    |
| :-------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
|        UIApplication 对象         | UIApplication 对象管理 event loop 和 high-level 应用行为。当应用的状态发生变化或者有远程通知的时候，UIApplication 对象会通知它的 delegate 对象，这个代理对象就是你在 UIApplicationMain 函数中传递的最后一个参数。 |
|          App 的代理对象           |                                           这个对象用来处理 App 的状态变化，例如：Active -> Background，还可以处理其他 App 级别的事件。每个 App 只有一个这样的代理对象。                                           |
|           数据模型对象            |                                                                 App 中的数据模型。For more see [Document-Based App Programming Guide for iOS][4].                                                                 |
|            控制器对象             |                                   控制器对象是管理展示在屏幕上的内容，一个控制器对象管理一个 view 和其所有 subview。当需要展示的时候，控制器会将 view 添加到 App 的 window 上。                                   |
|        [UIWindow][5] 对象         |                                          UIWindow 对象协调多个 view 的展示。一般情况下，一个 App 只有一个 window 对象，但是 App 在外接设备上展示内容就会有多个 window。                                           |
| UI (Views, Controls, Layers) 对象 |            Views 和 Controls 在特定的矩形框中展示可视化界面和处理这个区域内的事件。其实 Layer 才是真正渲染界面的对象，UIView 只是 CALayer 的代理，你可以直接创建 CALayer 对象，将其添加到视图层级中。             |

## The Main Run Loop

App 的 main run loop 处理所有与用户有关的事件，main run loop 运行在 App 的**主线程**上，这样保证 App 处理的事件与接收的顺序是一样的。

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/event_draw_cycle_a_2x.png?raw=true' width=340 alt='Event draw cycle' />
<div align=left>

上面这张图向我们展示了 App 是如何处理用户交互的。当用户与设备进行交互的时候，系统会为这些交互生成相应的事件，然后通过 UIKit 的特殊端口传递给 App。事件在内部是通过队列管理的，事件是一个一个交给 main run loop 来处理的。UIApplication 对象是第一个接收到事件的，由它来决定如何处理这个事件。

一些类型的事件是通过 main run loop 分发的，另外一些事件是直接分发给 delegate 或者传递给 block。~~分别举一些例子~~

Controls 的触摸事件跟 Views 的触摸事件是不一样的，Controls 的交互方式通常来说是有限的，所以这些事件被重新打包成动作消息 (action messages) 传递给 target 对象。这里就是 `target-action` 设计模式。

## Execution States for Apps

App 有五种状态，在特定的时间，你的 App 会处于任意一种状态，这五种状态分别是：

* Not running：App 没有启动
* Inactive：App 在前台，但是没有处理事件
* Active：App 在前台，并且在处理事件
* Background：App 在后台，并且在执行代码
* Suspended：App 在后台，没有执行代码。当 App 进入这个状态，App 不会接收到通知

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/high_level_flow_2x.png?raw=true' width=340 alt='High level flow' />
<div align=left>

大部分 App 状态改变都会调用相应的 App 代理方法：

* `application:willFinishLaunchingWithOptions:` - 在 App 的启动时间，这是你第一次可以执行自己的代码。
* `application:didFinishLaunchingWithOptions:` - 在应用展示给用户之前，你可以在这个方法做最后的初始化操作。
* `applicationDidBecomeActive:` - 当你的 App 从后台回到前台的时候会调用这个方法。
* `applicationWillResignActive:` - 当你的 App 即将离开前台时，这个方法会被调用。
* `applicationDidEnterBackground:` - 这时你的 App 运行在后台，并且可能在任意时间进入 Suspended 状态。在这里可以做一些清理操作，`SDWebImage` 就监听了这个通知，来做一些清理过期图片的操作。
* `applicationWillEnterForeground:` - 你的 App 离开后台，即将进入前台，但是仍然没有进入 active 状态。
* `applicationWillTerminate:` - 你的 App 将要结束。如果你的 App 此时处于 Suspended 状态，这个方法就不会调用。同样可以在这里做一些清理操作，`SDWebImage` 就监听了这个通知，来做一些清理过期图片的操作。

## App Termination

App 应该有随时被终止的准备，系统会回收处于 Suspended 状态的 App 的内存资源以便分配给新启动的 App 使用。处于 Suspended 状态的 App 被终止时，不会收到通知。App 处于 Background 状态，系统会在终止 App 之前调用 `applicationWillTerminate:` 代理方法。如果设备重启的话，系统仍然不会调用 `applicationWillTerminate:` 代理方法。

~~In addition to the system terminating your app, the user can terminate your app explicitly using the multitasking UI. User-initiated termination has the same effect as terminating a suspended app. The app’s process is killed and no notification is sent to the app.~~ 这句没太理解。

## Threads and Concurrency

多线程开发的几点建议：

* UI 的刷新始终要在主线程
* 消耗时间比较长的任务放在后台线程执行，例如：网络请求，文件处理等等
* 在启动时，尽量不要将任务放在主线程执行，只将与 UI 界面有关的初始化放在主线程，其他任务异步执行

For more see [Concurrency Programming Guide][8].

## Related Link

* [The App Life Cycle][1]

[1]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/TheAppLifeCycle/TheAppLifeCycle.html#//apple_ref/doc/uid/TP40007072-CH2-SW1
[2]: http://blog.sunnyxx.com/2014/08/30/objc-pre-main/
[3]: http://oatw5vnlr.bkt.clouddn.com/core_objects_2x.png
[4]: https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/DocumentBasedAppPGiOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40011149
[5]: https://developer.apple.com/reference/uikit/uiwindow
[6]: http://oatw5vnlr.bkt.clouddn.com/event_draw_cycle_a_2x.png
[7]: http://oatw5vnlr.bkt.clouddn.com/high_level_flow_2x.png
[8]: https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008091
