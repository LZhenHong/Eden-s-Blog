---
title: iOS 的响应者链条 ⛓️
date: 2016-12-03 14:26
tags: iOS
published: true
hideInList: false
feature: 
isTop: false
---
响应者链条在刚学 iOS 的时候有学过，但是平常开发也很少去仔细思考，也没有发生过很大的错误，所以就更加不会去考虑 What Under The Hood。

在实习的时候要做自定义 transition。我在 `UITransitionView` 上添加了一个 subview 作为背景 view，点击这个背景的 view，要 dismiss 掉 present 的 ViewController，给背景的 view 添加了一个 `UITapGestureRecognizer`，但是背景的 view 就是死活不响应点击。来来回回折腾了好久才找出原因：事件根本就没有传递给背景的 view 😭😭。

<!-- more -->

哎！还是基础不扎实的锅！！！就写下这篇来记录踩的坑。

## 响应者对象

当用户点击应用的控件时，硬件检测到物理接触并通知操作系统，`UIKit` 会创建相应的 `UIEvent` 对象，并将事件对象传递给正在运行的应用的事件队列。对于触摸事件，这个对象就是包含一系列 `UITouch` 对象的 `UIEvent` 对象。

我们需要处理这些事件，来给用户正确的反馈。在 iOS 中，继承自 `UIResponder` 的对象，都可以作为响应者链条上的节点来响应事件。`UIResponder` 定义了一系列接口来处理事件响应，`UIView`／`UIViewController`／`UIApplication` 都是继承自 `UIResponder` 类。这里注意 Core Animation 的 Layer 不是响应者对象，`CALayer` 是直接继承自 `NSObject`。

`UIResponder` 的继承层级关系：

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/UIKit-Framework.png?raw=true' alt='UIKit Framework' />
<div align=left>

## 确定 hit-testing view

既然知道 iOS 中有许多对象可以响应事件，我们就需要确定哪一个响应者对象是最适合处理一个事件对象。对于触摸事件来说，系统会首先将触摸事件分发给触摸事件发生的视图来确认这个视图是否能处理这个事件对象，这个视图称为 hit-test view。

寻找 hit-test view 的过程称为 hit-testing，这个过程会确定触摸事件发生的位置是否处于相关视图的边界内。如果在的话，就递归检测子视图。视图层级中包含触摸事件发生位置的最低层级的视图就是 hit-testing view。确认 hit-testing view 之后，`UIKit` 就会将事件传递给 hit-testing view，让 hit-testing view 来尝试处理这个事件。

我们通过一个示例来演示 hit-testing 的过程。下图是 Apple 官方的例子：

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/hit_testing_2x.png?raw=true' width=240 alt='Hit Testing' />
<div align=left>

假设用户点击了视图 E，系统按照以下顺序来查找 hit-test view：

1. 点击事件发生在视图 A 的边界内，所以检测子视图 B 和 C；
2. 点击事件不在视图 B 的边界内，但在视图 C 的边界范围内，所以检测子视图 D 和 E；
3. 点击事件不在视图 D 的边界内，但在视图 E 的边界范围内。

视图 E 是包含触摸点的视图层次架构中最底层的视图，所以它就是 hit-test view。

在 hit-testing 过程中，会调用 `hitTest:withEvent:` 方法，并传入 `CGPoint` 和 `UIEvent` 对象。这个 `hitTest:withEvent:` 方法先要调用 `pointInside:withEvent:` 方法。如果 `pointInside:withEvent:` 返回 YES，那么就会递归子视图的 `hitTest:withEvent:` 方法来进一步确定 hit-testing view。

如果方法 `pointInside:withEvent:` 返回 NO，那么这个 view 的整个分支都会被忽略。这就意味着超出父视图的子视图的范围，是没有办法接收到触摸事件。

## 响应者链条

在触摸事件下，`UIApplication` 对象最先从事件队列中取出最前面的事件，然后将其分发给 key window，随后 key window 将事件传递到 hit-testing view，让 hit-testing view 有第一机会来处理这个触摸事件，如果这个 hit-testing view 不能处理这个触摸事件，hit-testing view 就会将这个触摸事件沿着响应者链条传递，直到找到能处理这个触摸事件的响应者或者被丢弃。

响应者链条的构成与 App 的视图层级有密切的关系，所以，在 App 视图层级结构构建起来的同时，响应者链条也逐渐构建完成。

我们接下来看两个 Apple 官方的例子，如下图所示：

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/iOS_responder_chain_2x.png?raw=true' width=540 alt='iOS Responder Chain' />
<div align=left>

我们来分析一下右边的视图就可以了：

1. initial view 尝试处理触摸事件。如果它不能处理这个事件，它就传递给 `superView`，这个 `superView` 就是 initial view 的 `nextResponder`。
2. superView 尝试处理触摸事件。如果不能的话，就传递给管理这个 view 的 `UIViewController`，因为这个 view 是 `UIViewController` 的 top most view。
3. `UIViewController` 对象会尝试处理这个触摸事件。如果不能，`UIViewController` 就会将这个事件传递给自己 top most view 的 `superView`。
4. 这个 top most view 尝试处理这个触摸事件。如果不能，因为这个 view 也是 `UIViewController` 的 top most view，它就会将事件传递给 `UIViewController`。
5. `UIViewController` 对象尝试处理触摸事件。如果不能，它会将事件传递给 key window，因为这个 key window 的 `rootViewController` 是这个 `UIViewController` 对象。
6. key window 尝试处理触摸事件。如果不能，它会将事件传递给 `UIApplication` 对象。
7. `UIApplication` 对象尝试处理事件。如果不能，事件就被丢弃。

## 总结

在实际开发中，我们会碰到响应者对象不能响应事件时，可以先从一下几点排除：

* 先看响应者对象下面的属性是否设置正确：
    * `userInteractionEnabled != NO`
    * `hidden != YES`
    * `alpha != 0.0 ~ 0.01`
* `UIImageView` 的 `userInteractionEnabled` 默认是 NO，`UIImageView` 默认是不能接收事件，因此其子控件也不能接收触摸事件。
* 如果到了这一步就好好分析一下响应者链条吧。

这里仅仅介绍了如何寻找 hit-testing view 和响应者链条的构建。更多关于 `UIResponder` 的分析可以看 [UIKit: UIResponder | 南峰子的技术博客][2] 或者 [UIResponder Class Reference][5]。

## 相关链接

* [深入浅出 iOS 事件机制][1]
* [UIKit: UIResponder | 南峰子的技术博客][2]
* [Event Delivery: The Responder Chain][4]
* [UIResponder Class Reference][5]
* [iOS Events and Responder Chain][3]

[1]: http://zhoon.github.io/ios/2015/04/12/ios-event.html
[2]: http://southpeak.github.io/2015/03/07/cocoa-uikit-uiresponder/
[3]: https://www.zybuluo.com/MicroCai/note/66142
[4]: https://developer.apple.com/library/content/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/event_delivery_responder_chain/event_delivery_responder_chain.html#//apple_ref/doc/uid/TP40009541-CH4-SW2
[5]: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIResponder_Class
[6]: https://developer.apple.com/library/content/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/Art/hit_testing_2x.png
[7]: https://developer.apple.com/library/content/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/Art/iOS_responder_chain_2x.png
[8]: https://github.com/LZhenHong/BlogImages/blob/master/UIKit-Framework.png?raw=true

