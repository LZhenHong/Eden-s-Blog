---
title: App Programming Guide for iOS - Expected App Behaviors
date: 2016-11-01 13:02
tags: iOS
published: true
---

这一篇主要是总结自己在看 App Programming Guide for iOS 的一些收获。大部分内容都是来自 App Programming Guide for iOS。
 
Xcode 创建的新项目能直接运行在真机和模拟器上，但是你需要做一些自定义才能提交到 App Store 和给用户提供好的体验。

<!-- more -->

## Providing the Required Resources

* An Information property-list file：这个就是项目中的 **info.plist** 文件，这个文件中涉及了一些系统与你的 App 交互需要的信息。你可以直接编辑这个文件，也可以在你的项目 Info 选项页中进行编辑。
* A declaration of app‘s required capabilities：每个应用都需要表明你的应用的运行环境。App Store 会根据这些信息来决定你的应用是否可以运行在用户的设备上。你可以在项目 Info 选项页的 Required device capabilities 入口来编辑。
* One or more icons
* One or more launch images

### The App Bundle

当你编译 iOS App 的时候，Xcode 会将其打包成一个 bundle。一个典型的 App Bundle 包含以下内容：

|                File                |       Example        |                                                                                             Description                                                                                              |
| :--------------------------------: | :------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
|           App 可执行文件           |        MyApp         |                                                                可执行文件包含你的编译代码，可执行文件的名称跟你的 App 除去扩展名一样                                                                 |
| The information property list file |      Info.plist      |                                               Info.plist 文件中包含 App 的配置信息，涉及了一些系统与你的 App 交互需要的信息。这个文件必须叫 Info.plist                                               |
|  Storyboard files (or nib files)   | MainBoard.storyboard |                                                                                    SB 包含需要展示的视图和控制器                                                                                     |
|      Ad hoc distribution icon      |    iTunesArtwork     |                                                                                           ？？？暂时不清楚                                                                                           |
|          Settings bundle           |   Settings.bundle    | 如果你想在系统 Settings app 展示自定义的页面，你就需要包含这个 Setting bundle，这个 bundle 包含 property list 和其他资源来自定义你的 setting 界面。 [Preferences and Settings Programming Guide.][2] |

### The Information Property List File

Xcode 会使用 General／Capabilities／Info 选项页的信息在编译期来生成 Info.plist 文件。这个文件被 App Store 和 iOS 系统使用来决定应用的运行环境和定位主要资源。

对于一些比较基本的选项，你可以在 General／Capabilities／Info 选项页来配置。如果 Xcode 没有提供图形化界面，你就需要在 Xcode property list 的编辑器提供正确的键值对。

* Declare your app’s required capabilities in the Info tab：这个表明你的应用的最低运行系统，App Store 会用这个来避免比较低的系统来下载你的应用。
* Apps that require a persistent Wi-Fi connection must declare that fact：这个对应 Info.plist 文件中的 **UIRequiresPersistentWiFi** 键，设置这个键对应的值为 YES 来避免 iOS 系统关闭活跃的 Wi-Fi 连接。所有使用网络的应用都推荐添加这个键。
* Newsstand apps must declare themselves as such：在 Info.plist 文件中添加 **UINewsstandApp** 键来表明你的应用是在 Newsstand 应用中展示内容的。For more see [iOS 杂志类应用开发 - NewsstandKit][3].
* Apps that define custom document types must declare those types：使用 Info 选项页的 Document Types 的选项来定义应用支持的文件的 UTI 和 icon。iOS 系统会使用这些信息决定你的应用是否能够处理特定的文件类型。For more see [UIActivityViewController Tutorial: Sharing Data][4].
* Apps can declare any custom URL schemes they support：在 Info 选项页的 URL Types 选项来定义应用能处理的 URL Schemes。For more see [Using URL Schemes to Communicate with Apps][5].
* Apps must provide purpose strings (sometimes called “usage descriptions”) for accessing user data and certain app features：当访问用户的隐私数据(位置、通讯录等等)时，你需要向用户申请权限。这样你就需要在 Info.plist 文件中描述你需要访问隐私数据的原因。如果你的应用在申请权限的时候没有提供对应的原因，App 会直接闪退。

### Declaring the Required Device Capabilities

每个应用都需要表明最低支持的 iOS 操作系统。你可以在 Info.plist 文件中添加 **UIRequiredDeviceCapabilities** 键来表明应用额外的要求，这个键对应的值是字典／数组。

### App Icons

Xcode 在创建新项目的时候，会自动为应用的图标创建一个 image asset，Xcode 会在编译期在 Info.plist 文件添加相应的键值对。

### App Launch (Default) Images

系统启动应用的时候会先显示启动图片，当你的应用准备好系统会移除启动图片。当应用从后台回到前台，如果你应用的 UI 截图可用，系统会使用你的截图。同样 Xcode 在创建新项目的时候，会自动为应用的启动图片创建一个 image asset，Xcode 会在编译期在 Info.plist 文件添加相应的键值对。

## Supporting User Privacy

只有经过用户的同意应用才能访问用户的隐私数据。iOS 系统会保护 位置／联系人／日历事件／提醒事项／照片等等。你需要在 Info.plist 文件中提供访问隐私数据的原因，当你获取权限的时候，填写的原因会展示给用户看。在 iOS 10 之后你必须要在 Info.plist 文件中添加访问隐私数据的原因。

For more see **[Expected App Behaviors][1]** Table 1-2.

## Internationalizing Your App

为了国际化你的应用，你需要提供下列国际化的文件：

* Storyboard files
* Strings files
* Image files
* Video and audio files

## Related Link

* [Expected App Behaviors][1]

[1]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/ExpectedAppBehaviors/ExpectedAppBehaviors.html#//apple_ref/doc/uid/TP40007072-CH3-SW9
[2]:https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/UserDefaults/Introduction/Introduction.html#//apple_ref/doc/uid/10000059i
[3]: http://www.jianshu.com/p/935d18c5b5ae
[4]: https://www.raywenderlich.com/133825/uiactivityviewcontroller-tutorial
[5]: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW1
