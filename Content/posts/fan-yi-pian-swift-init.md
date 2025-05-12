---
title: 翻译篇 - Swift init()
date: 2016-08-28 05:16
tags: Swift
published: true
hideInList: false
feature: 
isTop: false
---

*PS：翻译水平有限，推荐看原文*

[下载 Playgroung 文件](http://merowing.info/2015/11/Initializers.playground.zip)

[原文链接.](http://merowing.info/2015/11/swift-init/)

因为 `Swift` 的强类型和不可变性，所以就有规则防止你在一个对象完全初始化之前访问属性。

我不喜欢在一个函数体内做太多的事情，所以我会将初始化函数分成多个函数，这样问题就来了。

<!-- more -->

让我们假定你有一个这样的类：

```
class Foo {
  let coreDataStack: CoreDataStack
  let mfpService = MFPService()
  let integrator: IntegrationService
  let flowController: FlowController
  let window: UIWindow
}
```
这样的类需要许多行来初始化所有的属性，所以我们会将初始化逻辑分成多个函数，可能像这样：

```
init(coreDataStack stack: CoreDataStack) {
  coreDataStack = stack
  integrator = setupIntegrator(stack, provider: mfpService)
  flowController = setupFlowController(stack)
  window = setupWindow(flowController.rootViewController)
}
```
这仅仅是常规的重构... 猜一猜，这样不能通过编译：
![](https://github.com/LZhenHong/BlogImages/blob/master/initializers.png?raw=true)


这样显得不那么 Cool. :]

我在 Twitter 上跟一些能干的人交流，寻找一些选择，下面是我觉得挺好的。

让我们来看一下这些选择

## 选择 1 - 对可选变量隐式解包

```
var integrator: IntegrationService!
```

这个选择经常会出错，我们选择 `Swift` 是因为它能写出更安全的代码。

请不要这样写。


## 选择 2 - 有副作用的懒加载

我们用隐藏的懒加载属性，但是可能会有副作用

```
class Foo_lazy {
  let coreDataStack: CoreDataStack
  let mfpService = MFPService()
  
  init(coreDataStack stack: CoreDataStack) {
    coreDataStack = stack
    let _ = integrator
    let _ = rootFlowController
    let _ = window
  }
  
  lazy var rootFlowController: FlowController = {
    return FlowController(coreDataStack: self.coreDataStack)
  }()
  
  lazy var window: UIWindow = {
    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window.backgroundColor = UIColor.whiteColor()
    window.rootViewController = self.rootFlowController.rootViewController
    window.makeKeyAndVisible()
    return window
  }()
  
  
  lazy var integrator: IntegrationService = {
    let coreDataProcessor = CoreDataReportProcessor(stack: self.coreDataStack)
    let integrator = IntegrationService(provider: self.mfpService) {
      coreDataProcessor.processReports($0)
    }
    return integrator
  }()
}
```
这个解决方法允许我们将代码分开，并且也运行得很好，但是这样也不是那么好，因为

* 属性不是真正的不可变，我们可以将其定义成隐私，如此不能在外面更改它们，但是他们仍然是可变的。
* 我不喜欢像这样会触发副作用的代码，这样看起来很不整洁。


## 选择 3 - 隐私的静态方法

我们可以定义隐私的静态方法，用它们来初始化属性(并且可以将它们放在隐私的类扩展中)：

```
class Foo_ext {
  let coreDataStack: CoreDataStack
  let mfpService = MFPService()
  let integrator: IntegrationService
  let flowController: FlowController
  let window: UIWindow
  
  init(coreDataStack stack: CoreDataStack) {
    coreDataStack = stack
    integrator = Foo_ext.SetupIntegrator(stack, provider: self.mfpService)
    flowController = Foo_ext.SetupFlowController(stack)
    window = Foo_ext.SetupWindow(self.flowController.rootViewController)
  }
}

private extension Foo_ext {
  static func SetupIntegrator(stack: CoreDataStack, provider: Provider) -> IntegrationService {
    let coreDataProcessor = CoreDataReportProcessor(stack: stack)
    let integrator = IntegrationService(provider: provider) {
      coreDataProcessor.processReports($0)
    }
    return integrator
  }
  
  static func SetupFlowController(stack: CoreDataStack) -> FlowController {
    return FlowController(coreDataStack: stack)
  }
  
  static func SetupWindow(controller: UIViewController) -> UIWindow {
    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window.backgroundColor = UIColor.whiteColor()
    window.rootViewController = controller
    window.makeKeyAndVisible()
    return window
  }
}
```
这是我现在最喜欢的方式：

* 确保不可变的属性
* 不会有副作用
* 非常整洁并且不会有编译错误

## 总结

还有一些 Twitter 上的朋友推荐的其他方法，[你可以在这里找到](https://gist.github.com/krzysztofzablocki/6a1b6afab974f442f5ff)

我也是才刚刚开始学 `Swift`，我必须说我越来越喜欢它，尤其是 `Swift 2.0`。

在有了20年的编程经历之后，重新变成新手很有趣，幸运的是，我们有伟大的愿意分享知识的社区。

非常感谢 [@jessyMeow](http://twitter.com/jessyMeow) 和 [@KostiaKoval](http://twitter.com/KostiaKoval) 指出比我原来方法更好的方法 :)

如果你有你喜欢的方法，请在 Twitter 上让我知道，我很愿意学习！

[Follow @merowing_ on Twitter](https://twitter.com/intent/follow?original_referer=http%3A%2F%2Fmerowing.info%2F2015%2F11%2Fswift-init%2F&ref_src=twsrc%5Etfw&region=follow_link&screen_name=merowing_&tw_p=followbutton)

