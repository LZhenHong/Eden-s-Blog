---
title: Cocos 的初级小坑
date: 2017-08-25 12:39
tags: Cocos
published: true
hideInList: false
feature: 
isTop: false
---
又是很久没有写博客了，所以再次写一篇来凑凑字数 😜，主要还是把自己最近刚知道的知识记录下来，方便以后来查看。

因为开始做游戏开发，所以就开始学习 Cocos 相关的内容。最近在几个地方踩了坑，虽然是很小的知识点，但是记录下来也算是记录成长的历程 😶😶。

<!-- more -->

## ignoreContentAdaptWithSize

这个其实不能算踩的坑，主要是当时看到这个觉得很奇怪，因为原来有做过 iOS 开发，觉得这种方式不能理解，当时在项目中看到这个代码的时候也是纠结了蛮久的，前段时间实在不爽，就把这个大概了解了下。因为 Cocos 是开源的，所以，要了解一个函数的详细用法，除了上网 Google 以外，还可以看源码。这在开发 iOS 是做不到的，虽然 iOS 的官方文档超级详细，但还是没有源码来的清晰。

这个方法是 ccui.Widget 的方法，在文档中的描述就是会触发控件是否忽略自定义的 `contentSize`，在这个类中这个方法的定义如下：

```javascript
ignoreContentAdaptWithSize: function(ignore) {
    if (this._unifySize) {
        this.setContentSize(this._customSize);
        return;
    }

    if (this._ignoreSize === ignore)
        return;

    this._ignoreSize = ignore;
    this.setContentSize(ignore ? this.getVirtualRendererSize() : this._customSize);
}
```

在这个方法的实现中，我们可以看到，在最后一行代码根据传递的 bool 值来判断是否使用自定义的 `contentSize` 值，其实在 `setContentSize` 方法中也会根据 `this._ignoreSize` 来判断是否使用自定义的 `contentSize`，这里在改变了 `this._ignoreSize` 的值之后，要触发 `setContentSize` 方法来改变控件的 `contentSize`。在 ccui.Widget 中会在初始化时调用这个方法，并传递 true，意味着继承自 ccui.Widget 的控件默认都会使用 `getVirtualRendererSize` 方法返回的 `contentSize` 来作为控件的大小。

关于 `getVirtualRendererSize` 方法，每个控件的实现方式不同，下面举两个控件的实现方式：

```javascript
// UIButton.js:180
getVirtualRendererSize: function() {
    if (this._unifySize)
        return this._getNormalSize();

    if (!this._normalTextureLoaded) {
        if (this._titleRenderer && this._titleRenderer.getString().length > 0) {
            return this._titleRenderer.getContentSize();
        }
    }
    return cc.size(this._normalTextureSize);
}
```

从 Button 的实现可以看出，在忽略 `this._unifySize` 的情况下，如果 Button 没有加载过纹理，就用设置的文字的大小来作为 Button 的大小。如果加载过纹理，则使用纹理的 `contentSize` 来作为 Button 的 `contentSize`。

```javascript
// UIText.js:341
getVirtualRendererSize: function() {
    return this._labelRenderer.getContentSize();
}
```

Text 的实现方式相比于 Button 就更简单了，直接使用文字的大小来设置 Text 的大小。

### 强行小结

在使用 ccui.Widget 的控件时，在控件大小需要跟图片大小、文字大小等相同时，我们就可以不用管这个方法，因为在初始化时就会调用此方法并传递 true。如果我们需要自定义控件的 `contentSize`，就需要手动调用这个方法，并传递 false，这样我们设置的 `contentSize` 才会生效。可以使用 `isIgnoreContentAdaptWithSize` 方法来获取是否忽略自定义的 `contentSize`。其实大部分情况下，默认方式就能满足我们的需求，这样也算是提高了一点点效率吧。

## ignoreAnchorPointForPosition

这算是结结实实踩的坑，在这个地方浪费了蛮多时间的，因为在界面上控件显示不出来，也不能像 iOS 开发那样有 Reveal 这样的工具，所以只能一点点去打印，但是打印的锚点依然是 (0.5, 0.5)。~~WTF 🙄~~

这个方法是在 Node 中定义的，这个方法在文档中的描述是：控制在设置 Node 位置时，锚点是否是始终为 (0, 0)；文档还说这个方法是内部使用的方法，只在 Layer 和 Scene 中使用，不要在外部调用此方法。在 Node 中的具体定义如下：

```javascript
ignoreAnchorPointForPosition: function(newValue) {
    if (newValue !== this._ignoreAnchorPointForPosition) {
        this._ignoreAnchorPointForPosition = newValue;
        this._renderCmd.setDirtyFlag(cc.Node._dirtyFlags.transformDirty);
    }
}
```
这个方法会先设置 `this._ignoreAnchorPointForPosition` 的值，这个值在 Node 中默认为 false，但是在 Layer 和 Scene 中为 true。在 CCNode.js:157 中的注释描述到占据整个屏幕的控件像 Layer 和 Scene 需要将这个值设为 true。随后设置 CCNodeCanvasRenderCmd 的 flag，需要重新改变控件的 transform，在 CCNodeCanvasRenderCmd 的 `setDirtyFlag` 方法中，会将这个 CCNodeCanvasRenderCmd 放入 cc.renderer 的 `_transformNodePool` 中，随后在 cc.renderer 的 `transform` 方法中遍历 `_transformNodePool` 调用 CCNodeCanvasRenderCmd 的 `updateStatus` 方法，在 CCNodeCanvasRenderCmd 的 `updateStatus` 方法中调用 CCNodeCanvasRenderCmd 的 `transform` 方法，在这个方法中根据一些设置，其中包括 node 的 `_ignoreAnchorPointForPosition` 来调整 node 的锚点。

### 强行小结

在大多数情况下，计算控件的位置都会受到锚点的影响。并且默认情况下，锚点的值都是 (0.5, 0.5)。但是还是有特殊情况的，虽然锚点是 (0.5, 0.5)，但是 `this._ignoreAnchorPointForPosition` 为 true，这样控件的位置就不受锚点的影响。Layer 跟 Scene 都是这样，设置锚点为 (0.5, 0.5)，但是同样设置了 `this._ignoreAnchorPointForPosition` 为 true。继承自这两个控件的控件也会有这样的问题，例如：ScrollView 和 TableView，设置锚点对这两个控件的位置计算没有影响。需要锚点有影响的话就需要调用 `ignoreAnchorPointForPosition` 方法，并传递 true。

可以使用 `isIgnoreAnchorPointForPosition` 函数来获取 `this._ignoreAnchorPointForPosition`  的值。锚点只影响自身的位置，子控件始终以父控件的左下角为坐标原点。

## cc.TableView

关于 TableView 的坑，上面介绍的算一个，然后还有就是设置 TableView 的大小时，不能使用 `setContentSize` 去设置 TableView 的大小，TableView 继承自 ScrollView，其实这个是 ScrollView 的实现方式。在 iOS 中，设置控件大小的时候使用的是 `frame`，`contentSize` 是 UIScrollView 的特有属性，表示 UIScrollView 可滚动的区域大小。在 Cocos 中设置控件的大小使用的是 `contentSize`，但是在 ScrollView 和 TableView 这，`contentSize` 的含义变了，也是跟 iOS 中的 `contentSize` 相似，代表可滚动的区域大小。

看下 ScrollView 中的 `setContentSize` 函数的实现：

```javascript
setContentSize: function(size, height) {
    if (this.getContainer() !== null) {
        if (height === undefined)
            this.getContainer().setContentSize(size);
        else
            this.getContainer().setContentSize(size, height);
        this.updateInset();
    }
}
```
这里的 `setContentSize` 方法不会直接设置 ScrollView 的 `contentSize`，而是设置 container 的 `contentSize`，这个 container 默认是 Layer，代表 ScrollView 的内容。`setContentOffset` 改变的也是 container 的 `position`，所以 `setContentSize` 不能改变 ScrollView 和 TableView 的可视区域。改变可视区域的方法是 `setViewSize`，实现如下：

```javascript
setViewSize: function(size) {
    this._viewSize = size;
    cc.Node.prototype.setContentSize.call(this, size);
}
```
在创建 TableView 和 ScrollView 的时候，传递的 cc.size 就是可视区域的大小，如果没有给可视区域的大小，默认是 cc.size(200, 200)。

### 强行小结

虽然 Cocos 的 TableView 和 ScrollView 跟 iOS 中的 UITableView 和 UIScrollView 有很多相似的地方，但是还是有很多不同点，不能简单的以 iOS 中的方式来带入到 Cocos 中。

ScrollView 和 TableView 设置可视区域的函数是 `setViewSize`，设置内容大小的函数是 `setContentSize`。

## 不同对象引用同一对象

这个算是 JS 层面的坑，在 Cocos-JS 中采用的是 **John Resig's Simple Class Inheritance** 继承来实现的。我们来看一下在 Cocos-JS 的自定义 Node 的实现方式：

```javascript
var MyNode = (function() {

    var node = cc.Node.extend({
        data_: [],
        ctor: function() {
            this._super();
            // do something with data_.
        },
        onExit: function() {
            // release resources.
            this._super();
        }
    });

    return node;

})();
```

上面这段代码看起来是没有什么问题的，但是我们如果创建多个 MyNode 对象，并同时对 data\_ 进行了一些操作，我们就会发现 data\_ 的数据跟我们预想的数据不太一样。这是因为这两个对象的 data\_ 实际上实际上是同一个对象，这就导致其中一个 MyNode 对象对 data\_ 进行了操作会影响到另一个对象的 data\_ 数据。可以通过下面的方式来避免这个情况的发生：

```javascript
var MyNode = (function() {

    var node = cc.Node.extend({
        data_: null,
        ctor: function() {
            this._super();

            this.data_ = [];
            // do something with data_.
        },
        onExit: function() {
            // release resources.
            this._super();
        },
    });

    return node;

})();
```

一个类的属性如果是 array / function / object，这个属性的初始化需要放到 `ctor` 方法中。

## 相关链接

* [cocos2d-x AnchorPoint 锚点][1]
* [菜鸟学习Cocos2d-x 3.x——锚点][2]
* [Cocos2d-x JSB + Cocos2d-html5 跨平台游戏开发（一）—— 引擎选择][3]
* [Cocos2d-x JSB + Cocos2d-html5 跨平台游戏开发（二）—— 遇到的坑][4]

[1]: http://blog.csdn.net/xuguangsoft/article/details/8425623
[2]: http://www.jellythink.com/archives/727
[3]: https://boundary.cc/2014/02/cocos2d-x-jsb-cocos2d-html5-game-development-1-choice-of-engine/
[4]: https://boundary.cc/2014/05/cocos2d-x-jsb-cocos2d-html5-game-development-2-pitfalls/
