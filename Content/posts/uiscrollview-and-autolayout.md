---
title: UIScrollView And Autolayout
date: 2016-11-12 12:00
tags: iOS
published: true
hideInList: false
feature: 
isTop: false
---

这一篇介绍如何将 Autolayout 应用到 UIScrollView 上。

在 [UIScrollView Tutorial: Getting Started][2] 这篇文章中的 **Scrolling and Zooming a Large Image** 这节中，给 UIScrollView 添加 top／bottom／leading／trailing 的约束，确定 UIScrollView 的 frame。再给 UIScrollView 中的 UIImageView 添加 constant 为 0 的 top／bottom／leading／trailing 约束，运行之后，UIScrollView 中的 contentSize 就是图片的大小，可以滚动查看所有内容。

<!-- more -->

添加的约束如下图。

![UIScrollViewWithAutolayout][7]

看到这里比较好奇 UIScrollView 是如何使用 Autolayout 来自动计算 `contentSize` 的。所以去网上搜了一下相关资料，加上一些自己的理解整理出来这篇文章。

## Key Point

UIScrollView 使用 Autolayout 主要是用来自动确定自身的 `frame` 与 `contentSize`，`frame` 是根据 UIScrollView 自己的约束来确定，而 `contentSize` 是根据子视图与 UIScrollView 之间的约束来确定的。所以，UIScrollView 的子视图添加的约束一定要能确定 UIScrollView 的 `contentSize`。

这点跟 self-sizing cell 有点相似，cell 可以根据完整的内部约束来确定自己的高度，只是 cell 的宽度与 UITableView 的宽度是相同的，所以我们不需要显示地去表明子视图具体的宽度，只需要确定 leading 和 trailing 的约束就可以确定子视图的 width，再添加好垂直方向上的约束，系统就可以根据我们添加的约束自动算出 cell 的高度。

> The trick to getting Auto Layout to work on a UITableViewCell is to ensure you have constraints to pin each subview on all sides - that is, each subview should have leading, top, trailing and bottom constraints.

上面这段来自 [Self-sizing Table View Cells][6]。表示 cell 自动算高度需要的约束条件，感兴趣的话可以了解一下。

## In Depth Explanation

一般来说，Autolayout 认为视图的 top／bottom／leading／trailing 边界是可见 (我的理解是这里的可见相对于 UIScrollView 的 content view  的边界而言的，因为这个 content view 是不可见的) 的边界。也就是说，如果你把一个视图固定在 superview 的左边界，你其实是把视图固定在 superview 的 bounds 的最小 x 值。改变 superview 的 bounds 的 origin 值不会改变视图的位置。

UIScrollView 通过改变 bounds 的 origin 值来滚动它的内容。为了让 UIScrollView 能与 Autolayout 协同工作，UIScrollView 的 top／bottom／leading／trailing 边界代表 UIScrollView 的 content view 的边界。

> * Position and size your scroll view with constraints external to the scroll view.
> * Use constraints to lay out the subviews within the scroll view, being sure that the constraints tie to all four edges of the scroll view and do not rely on the scroll view to get their size.

上面两点来自 [UIScrollView And Autolayout][1]。解释起来就是 UIScrollView 需要自己来确定自身的大小和位置，不能依靠子视图的约束。UIScrollView 的子视图需要自己明确自己的大小，不能依赖 UIScrollView 来决定大小。

拿我在最前面提到的例子来解释一下：

1. 我们先给 UIScrollView 添加 top／bottom／leading／trailing 的约束，这样就可以确定 UIScrollView 自身的 `frame`。这里没有用到子视图的信息来确定 `frame`。
2. 我们添加 UIImageView 到 UIScrollView 中，然后给 UIImageView 设置图片内容。
3. 给 UIImageView 添加 top／bottom／leading／trailing 的 constant 为 0 的约束。确定 UIScrollView 的 `contentSize`。

这样就👌👌了，UIImageView 有一个固有内容大小，默认与图片的大小相等，所以这里我们不需要明确指出 UIImageView 的宽高，只需要添加与 UIScrollView 边界的间距来确定 `contentSize` 的大小。

如果这里我们添加的是 UIView 的话，就需要添加 width／height 的约束来明确指出 UIView 的大小，例如：添加 width=50，height=50 的约束来指明 UIView 大小，然后再添加与 UIScrollView 的约束。我们可以这样理解：添加在 UIScrollView 自身的约束，是作用在 UIScrollView 可见的边界上。子视图与 UIScrollView 之间的约束中，是作用于子视图与不可见的 content view 上，而这个 content view 的大小是不确定的，需要根据子视图之间的约束来得出。

## For Example

这跟我们平常使用 Autolayout 有点不太一样。下面举例来说明 Autolayout 在 UIScrollView 上使用的不同。

### Use Autolayout in Common View

(红色 view 是 UIView)
![FirstExample][8]

大概的代码实现，数值是我随便给的，运行结果不一定和上面一样。

```objectivec
self.view.backgroundColor = [UIColor blueColor];
  
UIView *redView = [[UIView alloc] init];
redView.backgroundColor = [UIColor redColor];
[self.view addSubview:redView];
[redView mas_makeConstraints:^(MASConstraintMaker *make) {
   make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(100, 50, 100, 50));
}];
    
UIView *yellowView = [[UIView alloc] init];
yellowView.backgroundColor = [UIColor yellowColor];
[redView addSubview:yellowView];
[yellowView mas_makeConstraints:^(MASConstraintMaker *make) {
   make.edges.equalTo(redView).insets(UIEdgeInsetsMake(200, 50, 20, 20));
}];
```

如果我们需要确定黄色 view 的 `frame`，添加如上的约束就可以得到。这是我们平常使用 Autolayout 添加的约束，如果视图可以根据自身内容得出固有内容大小，例如：UILabel／UIButton／UIImageView 等，那么只需要确定视图的位置就 👌。

### Autolayout in UIScrollView

```objectivec
self.view.backgroundColor = [UIColor blueColor];
    
self.scrollView = [[UIScrollView alloc] init];
self.scrollView.bounces = NO;
self.scrollView.clipsToBounds = NO;
self.scrollView.backgroundColor = [UIColor redColor];
[self.view addSubview:self.scrollView];
    
[self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
   make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(100, 50, 100, 50));
}];
    
UIView *yellowView = [[UIView alloc] init];
yellowView.backgroundColor = [UIColor yellowColor];
[self.scrollView addSubview:yellowView];
[yellowView mas_makeConstraints:^(MASConstraintMaker *make) {
   make.top.equalTo(self.scrollView).offset(200);
   make.bottom.equalTo(self.scrollView).offset(-200);
   make.leading.equalTo(self.scrollView).offset(50);
   make.trailing.equalTo(self.scrollView).offset(-200);
   // Important
   make.width.and.height.equalTo(@100);
}];
```

(红色的 view 是 UIScrollView)
![SecondExampleUIScrollVie][9]

这是上面代码的运行结果，我把 scrollView 的 `clipsToBounds` 设置为 NO，方便我们查看。如果我们不添加 `make.width.and.height.equalTo(@100);` 这行代码的话，黄色 view 是不会出现的，因为 scrollView 的 `contentSize` 不确定。

我们结合下面这张图来分析一下。(红色的 view 是 UIScrollView)

![SecondExample][10]

黑色边框代表 scrollView 的 `contentSize` ，我们不能假设这个值是已知的，这个是未知量，需要我们给出完整的约束来计算。所以，`contentSize` 不知道，不用黑色约束的话，就无法得出黄色 view 的大小，黄色 view 就不显示。

## Summary

UIScrollView 的子视图需要自己明确自己的大小，不能依赖 UIScrollView 来决定大小。UIScrollView 是需要依靠子视图的约束来确定 `contentSize` 的，所以在 UIScrollView 上使用 Autolayout 需要注意子视图的约束是否足够完整来确定 `contentSize`。

UIScrollView 与同级视图或者父视图之间的约束只能确定 UIScrollView 的 `frame`，不能确定 `contentSize`。

## Related Link

* [UIScrollView And Autolayout][1]
* [UIScrollView Tutorial: Getting Started][2]
* [史上最简单的UIScrollView+Autolayout出坑指南][3]
* [UIScrollview与Autolayout的那点事][4]
* [AutoLayout Tips][5]

[1]: https://developer.apple.com/library/content/technotes/tn2154/_index.html#//apple_ref/doc/uid/DTS40013309-CH1-MIXED_APPROACH
[2]: https://www.raywenderlich.com/122139/uiscrollview-tutorial
[3]: https://bestswifter.com/uiscrollviewwithautolayout/
[4]: http://adad184.com/2015/12/01/scrollview-under-autolayout/
[5]: https://github.com/nixzhu/dev-blog/blob/master/autolayout-tips.md#tip-2
[6]: https://www.raywenderlich.com/129059/self-sizing-table-view-cells
[7]: https://github.com/LZhenHong/BlogImages/blob/master/UIScrollViewWithAutolayout.png?raw=true
[8]: https://github.com/LZhenHong/BlogImages/blob/master/FirstExample.png?raw=true
[9]: https://github.com/LZhenHong/BlogImages/blob/master/SecondExampleUIScrollView.png?raw=true
[10]: https://github.com/LZhenHong/BlogImages/blob/master/SecondExample.png?raw=true
