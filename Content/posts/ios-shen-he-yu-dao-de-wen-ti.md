---
title: iOS 审核遇到的问题
date: 2020-06-04 09:49
tags: iOS
published: true
---

最近游戏上线了 iOS 版本，期间来来回回提审了 2、3 次，最终没有经历太多波折顺利上线，写下这篇文章记录下审核期间遇到的问题，方便以后查看和提前避免一些问题。

<!-- more -->

## 机审

1. **ITMS-90683: Missing Purpose String in Info.plist** - 这个问题是游戏使用的一个选图片的第三方库用到了 `NSPhotoLibraryUsageDescription` 和 `NSLocationWhenInUseUsageDescription` 权限，但是在 Info.plist 中没有声明，造成机审没过。
2. **TMS-90809: Deprecated API Usage** - 这个是因为 Apple 的政策，新提交审核的应用不能再使用 `UIWebView`，必须换成 `WKWebView`，这个对照着 [Cocos 官方库的修改](https://github.com/cocos2d/cocos2d-x/commit/9df47ef6fdf30694ae4dccd53351c7dcbd9dfbec#diff-a9b7eb55473ca4904dafd82ad5aa03df)，将 Cocos 引擎的 `UIWebView` 升级到 `WKWebView`。
3. **ITMS-90191: Missing beta entitlement** - 这个问题是因为没有使用发布的证书打包，而是使用了 ad-hoc 证书，导致上传失败，使用发布证书打包就解决了问题。

## 人审

1. **Guideline 4.8 - Design - Sign in with Apple** - 这个也是 Apple 的政策，我们游戏接入了 Facebook 登录，Apple 的政策是如果你的游戏或者 App 有第三方的登录渠道，就必须也要接入 `Sign in with Apple`。解决方案：iOS 13 接入 AuthenticationServices，iOS 13 之前的设备不管。
2. **Guideline 2.3.6 - Performance - Accurate Metadata** - 这个是因为游戏填写的年龄评级不对。解决方案：修改年龄评级符合政策规范。
3. **Guideline 2.1 - Information Needed** - 这个是游戏提交审核的游戏内购买商品没有在游戏中体现，导致不能购买测试而被拒。解决方案：写测试代码，将所有的游戏内商品放在明显的位置，供 Apple 审核。
4. **Guideline 2.1 - Performance - App Completeness** - 这个刚好和上一点相反，这个是在游戏内出现的购买商品没有在 App Store Connect 后台提交审核，导致被拒。解决方案：将所有的游戏内购买商品都提交审核。

## 奇葩的事

我们在修改了所有问题之后通过了 Apple 的审核，因为之前审核的包有测试代码，不能直接发布，随后我们就修改了最新的 iOS 包，然后再次提审准备发布我们的正式包，但是这个包的审核发生了一些奇怪的事情。

![Apple 审核过程](https://github.com/LZhenHong/BlogImages/blob/master/iOS-review.png?raw=true)

可以看到我们在 5.22 提交了我们新的版本，Apple 随后就开始审核，在 5.23 告知我们被拒绝了，但是拒绝邮件并不像之前那样明确指出问题在哪，而是给出了下面图的理由。

![Apple 拒审邮件](https://github.com/LZhenHong/BlogImages/blob/master/iOS-resolution-center-mail.png?raw=true)

这个邮件说需要更多时间来审核，但是又告知我们被拒，我们之后也重复申诉了，但是 Apple 回的邮件内容与上图都是相似的。没办法我们也只能等，等了一周的时间，在第一张图可以看到，Apple 在 5.30 又开始审核我们的游戏，并且在 5.31 告知我们审核通过。

这个事情就很奇葩吧，但是也没办法，谁让咱们要靠着 Apple 吃饭呢 😔。

Apple 每次发版本都需要重新审核的，在后续的审核中碰到问题，也会更新上来。
