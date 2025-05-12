---
title: App Programming Guide for iOS - Background Execution
date: 2016-11-25 20:27
tags: iOS
published: true
hideInList: false
feature: 
isTop: false
---
我们知道 iOS App 有五种状态：not running／inactive／active／background／suspended，当用户按下 Home 键的时候，App 就会进入 background 状态，随后进入 suspended 状态。在 suspended 状态下，我们没有办法对 App 进行任何操作。所以，我们会尽量在 background 状态下就做好 App 的一些清理等操作，来使 App 有进入 suspended 的准备。但是，iOS 系统分配给 App 的 background 状态下的时间是有限的，我们需要做一些自定义的操作来向 iOS 系统申请更多的后台时间，或者直接常驻后台。例如一些音乐类 App，当我们退出这类 App，我们还是可以听到 🎵 的播放，这些 App 就属于常驻后台的 App。

<!-- more -->

iOS 为三类适合在后台运行的 App 提供很好的支持，这三类 App 分别是：

* App 在前台的时候开启了一个持续时间较短的任务，当 App 进入后台的时候希望能继续执行完成。
* App 在前台初始化一个下载操作，当 App 进入后台时，将下载操作的控制权交给系统。这样 App 就能在下载操作继续的情况下被挂起或者结束。
* 支持特定的在后台执行任务的 App 要先声明它们支持的一个或者多个后台运行模式。

## Executing Finite-Length Tasks

当 App 进入到 background 状态，系统期望尽快将 App 转入 suspended 状态。但是如果这个时候 App 还需要更多时间来做一些操作，我们就需要向系统申请额外的后台运行时间。iOS 为 `UIApplication` 对象提供了 `beginBackgroundTaskWithName:expirationHandler:` 和 `beginBackgroundTaskWithExpirationHandler:` 方法来申请额外的后台时间，调用任意一个方法都会延缓 App 进入 suspended 状态，当任务完成之后，你需要调用 `UIApplication` 对象的 `endBackgroundTask:` 方法来告诉系统，你的 App 已经准备好可以进入 suspended 状态。

需要注意的是，` beginBackgroundTaskWithName:expirationHandler:` 和 
`beginBackgroundTaskWithExpirationHandler:` 这两个方法的调用都会为相应的后台 task 创建唯一的 token，这个 token 是 `endBackgroundTask:` 需要的参数，如果调用 `endBackgroundTask:` 失败会导致 App 直接被终止。我们在申请额外后台时间的时候，可以提供一个 expirationHandler，当额外时间消耗完，task 这时还是没有完成的话，系统就会调用这个 handler 来给你最后的机会做一些清理操作。

你不需要等到 App 进入后台状态才去调用 ` beginBackgroundTaskWithName:expirationHandler:` 或者 `beginBackgroundTaskWithExpirationHandler:` 方法，你可以在开始一个 task 之前就可以调用这两个方法中的任意一个，然后在 task 完成之后尽快调用 `endBackgroundTask:`。当 App 还在前台的时候就可以这样做。

**Starting a background task at quit time**

```
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;

- (void)applicationDidEnterBackground:(UIApplication *)application {
    bgTask = [application beginBackgroundTaskWithName:@"MyTask" expirationHandler:^{
        // App 已经快要没有后台运行时间
        // 在这里尽快清理没有完成的 task
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 做一些操作来完成 task
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}
```

在原来经常用这种方式来处理一些网络上传和下载操作，系统通常情况下会给大概 10 mins 的时间，但是系统并不保证一定会给 10 mins，实际的后台运行时间是由 iOS 系统决定的，可以通过 `backgroundTimeRemaining` 来查看剩余的后台运行时间。现在可以用 `NSURLSession` 来处理网络请求，即使 App 进入 suspended 状态 `NSURLSession` 还是可以继续运行。More about NSURLSession: [NSURLSession Tutorial: Getting Started][3].

严格来说这个并不算后台模式，因为它只是申请一些额外的后台运行时间，并不能常驻后台，最后还是要进入 suspended 状态。

## Downloading Content in the Background

前面提到过，下载网络数据使用 `NSURLSession`，可以在 App 被挂起或者停止的时候将控制权交给系统。

为了支持后台下载，你需要为 `NSURLSession` 做一些配置。

1. 用 `NSURLSessionConfiguration` 的 `backgroundSessionConfigurationWithIdentifier:` 方法来创建一个 `NSURLSession` 的配置对象。
2. 设置 `NSURLSessionConfiguration` 对象的 `sessionSendsLaunchEvents` 属性为 YES。
3. 如果 App 在前台开始这个请求，最好将 `NSURLSessionConfiguration` 对象的 ` discretionary` 属性也设置为 YES。
4. 正确设置 `NSURLSessionConfiguration` 对象的其他属性。
5. 用创建好的 `NSURLSessionConfiguration` 对象来创建 `NSURLSession` 对象。

用这个配置好的 `NSURLSession` 创建的上传 & 下载操作都可以在恰当的时机将控制权交给系统。对于所有后台上传 & 下载的 task，你必须要提供一个遵守 `NSURLSessionDownloadDelegate` 协议的 delegate，如果你不需要 delegate 提供的额外特性，在创建 session 对象的时候给 delegate 参数传递 nil (session 对象在 App 退出或者你使 session 对象无效之前会对 delegate 有一个强应用)。

当 task 完成之后，如果 App 在运行，不管是前台还是后台，都会通知 session 对象的 delegate。如果 task 还没有完成，这时系统结束 App，系统还会继续在后台管理 tasks，当 session 相关的 tasks 都完成之后，系统会重新唤醒 App 并调用 `application:handleEventsForBackgroundURLSession:completionHandler:` 方法。如果是用户主动结束 App，系统会取消等待执行的 tasks，不会继续在后台管理 session 相关的  tasks。

在  Stack Overflow 找了几篇关于用户主动退出 App，后台下载操作是否会继续执行的讨论，感兴趣的话可以看一下：[第一篇][6]／[第二篇][7]／[第三篇][8]。

## Implementing Long-Running Tasks

一些特定类型的 App 需要一直运行在前台或者后台，不进入 suspended 状态，这种类型 App 需要向系统申请后台运行权限，可以在项目 setting 的 Capabilities 选项的来声明特定类型的后台应用。只有特定的几种允许常驻后台：

* *[需要一直得到用户位置更新信息的 App](#location)*。
* *[播放音频或者记录音频的 App](#audio)*。
* *[定时下载和处理数据的 App](#fetch)*。
* *[支持 Voice over Internet Protocol (VoIP) 的 App](#VoIP)*。
* *[接收外设更新的 App](#accessory)*。

<span id='location'></span>

### Tracking the User’s Location

在后台跟踪用户的位置有好几种方法，大部分都不需要 App 一直运行在后台：

* 用户的位置信息有显著的更新才通知 App，当 App 不需要特别精确的位置信息，Apple 强烈推荐使用这种方法。
* 只在前台获取用户的位置信息。
* 后台获取用户位置。

当 App 使用第一种服务，有显著的位置信息更新时，如果 App 处于 suspended 状态，系统会将 App 变成  background 状态以便来处理位置信息的更新。如果 App 使用这种位置服务的时候，被系统完全退出，当有位置信息更新时系统就会启动 App 来处理，并调用 `CLLocationManager` delegate 的 `locationManager:didUpdateLocations:` 方法。

前台或者后台位置服务都是使用标准的 Core Location 服务来取得位置数据。不同的是，使用前台服务的 App 在应用被挂起之后就不会再接收到位置信息更新。

当你在 Xcode 项目的 Capabilities 选项中勾选了 **Location Update**，这样做并不会阻止 App 进入 suspended 状态，而是在位置信息更新的时候唤醒 App 来处理位置数据。

对Map 方面了解比较少。More about location services: [Location and Maps Programming Guide][9].

<span id='audio'></span>

### Playing and Recording Background Audio

这类 App 可以在后台播放或者记录音频，但是 App 播放的音频必须是有声的。~~因为以前有些 App 会通过播放一段没有声音的音频来获取后台运行权限。~~

典型的音频类 App 包括：

* 音乐播放 App。
* 记录音频 App。
* 支持 AirPlay 播放音频 & 视频的 App。
* VoIP App。

当你将 App 声明为这类应用，系统的 media frameworks 会自动阻止你的 App 进入 suspended 状态。因为 App 一直处理后台，这时处理回调和在前台没有区别，但是在回调中你应该只处理播放相关的数据，并且尽可能快的返回。当播放或者记录停止，系统就会让 App 进入 suspended 状态。

可能会有多个 App 属于音频类型，系统会决定这些 App 的优先级。前台的 App 的优先级适中比后台高。在后台同时播放音频是有可能的，这要取决于每个 App 的 audio session 对象的配置。你应该要时刻准备好音频播放被打断的打算，并且提供相应的操作来处理打断和一些其他音频相关的通知。More about configuring audio session objects for background execution: [Audio Session Programming Guide][10].

<span id='fetch'></span>

### Background Fetch

这类 App 需要时不时的检查是否有新数据，并且在有新数据的时候初始化下载操作来下载新内容。当你在 Xcode 中将 App 声明成这类应用并不能保证系统会给 App 分配时间来执行 background fetch。系统会决定在恰当的时候来执行 background fetch。

当有好机会的时候，系统会唤醒或者启动 App 到 background 状态，然后调用 `UIApplication` 代理的 `application:performFetchWithCompletionHandler:` 方法，在这个方法中来检查是否有新内容需要下载。当你完成新内容的下载之后，要尽快调用提供的 completion handler 块，并且传递参数来表明是否有新数据，如果传递的是 ` UIBackgroundFetchResultNewData` 可能会让 iOS 对应用做一次截图操作。执行这个 block 会告诉系统可以将 App 变成 suspended 状态了。

<span id='VoIP'></span>

### Implementing a VoIP App

VoIP 应用可以让用户使用网络连接来通话，而不是使用蜂窝服务。这样的 App 需要维护与服务器维护一个长连接。iOS 系统不会让 VoIP 应用一直保持运行，而是提供工具来监测 sockets，并且会在需要的时候唤醒 VoIP 应用，并将 socket 的控制权交给 VoIP 应用。

More about VoIP: [iOS VoIP (VoIP Push)开发集成][11] & [iOS Call Kit for VoIP][12] & [Tips for Developing a VoIP App][15].

### Using Push Notifications to Initiate a Download

当服务器发送远程通知来告诉 App 有新内容，你可以告诉系统在后台运行你的应用来开始下载新内容。

为了触发这样的操作，服务器发出的 notification payload 中一定要有 `content-available` 字段，并且设置为 1。当这样的字段出现，系统会唤醒或者启动 App 到 background 状态，并且调用相应的代理方法来让你做一些操作。

<span id='accessory'></span>

### Communicating with External Accessory

对这一块真的没有一点接触，所以我就不瞎说了 😛😛。给出[官方文档][13]。

### Downloading Newsstand Content in the Background

现在好像已经看不到这种应用，记得在 iOS 7 的时候还下过一个。感兴趣可以看一下[官方文档][14]。

## Being a Responsible Background App

* Do not make any OpenGL ES calls from your code.
* Cancel any Bonjour-related services before being suspended.
* Be prepared to handle connection failures in your network-based sockets.
* Save your app state before moving to the background.
* Remove strong references to unneeded objects when moving to the background.
* Stop using shared system resources before being suspended.
* Avoid updating your windows and views.
* Respond to connect and disconnect notifications for external accessories.
* Clean up resources for active alerts when moving to the background.
* Remove sensitive information from views before moving to the background.
* Do minimal work while running in the background.

[More details][16].

## Opting Out of Background Execution

如果你一点也不想 App 运行在 background 状态下，你可以在 Info.plist 文件中添加 `UIApplicationExitsOnSuspend` 键并且设置为 YES，这样 App 只有 not running／inactive／active 状态。当用户按了 Home 键之后，`applicationWillTerminate:` 方法就会调用。Apple 不推荐这样实现。

## Summary

废话了很多，我自己看到这里都很辛苦了 😅😅。这里有一篇知乎的 [所谓的iOS「伪多任务」和Android的多任务处理的区别在哪？][5]感兴趣的话可以看一下。

Apple 官方文档还有一节关于 [Understanding When Your App Gets Launched into the Background][17]。同样，感兴趣的话可以看一下。

还有关于 Background Execution  的实践，可以看 [Background Modes Tutorial: Getting Started][2].

## Related Link

* [Background Execution][1]
* [Background Modes Tutorial: Getting Started][2]

[1]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW1
[2]: https://www.raywenderlich.com/143128/background-modes-tutorial-getting-started
[3]: https://www.raywenderlich.com/110458/nsurlsession-tutorial-getting-started
[4]: https://developer.apple.com/reference/uikit/uiapplicationdelegate/1622941-application
[5]: https://www.zhihu.com/question/20258088
[6]: http://stackoverflow.com/questions/25047427/does-nsurlsession-continue-file-transfer-if-the-app-is-killed-from-task-manager?answertab=votes#tab-top
[7]: http://stackoverflow.com/questions/20159471/ios-does-force-quitting-the-app-disables-background-upload-using-nsurlsession
[8]: http://stackoverflow.com/questions/31904182/how-to-resume-nsurlsession-download-process-after-app-force-quit-and-app-relaunc
[9]: https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/LocationAwarenessPG/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009497
[10]: https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007875
[11]: http://jpache.com/2016/03/18/iOS-VoIP-VoIP-Push-开发集成/
[12]: http://www.jianshu.com/p/3bf73a293535/comments/5271525
[13]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW53
[14]: https://developer.apple.com/reference/newsstandkit
[15]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/StrategiesforImplementingYourApp/StrategiesforImplementingYourApp.html#//apple_ref/doc/uid/TP40007072-CH5-SW13
[16]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW8
[17]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW7
