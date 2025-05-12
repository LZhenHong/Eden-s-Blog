---
title: 关于 UITableView 的滑动优化问题
date: 2016-08-31 19:02
tags: iOS
published: true
hideInList: false
feature: 
isTop: false
---

UITableView 应该是 iOS 开发中最重要的控件，当我们要展示多个相似的模型数据的时候，毫无疑问 UITableView 是最好的选择，Apple 已经将 UITableView 的优化做到非常极致了，满足我们简单的模型数据展示基本上是没有问题的。但是很多时候，我们展示的不是简简单单的文字数据，还有其他对性能消耗很大的数据，例如：图片等。在数据不多的情况下，遵循 UITableView 的标准使用方式就能满足要求。像 Twitter / Weibo 这样的数据模型很复杂，数量也很多的情况下，我们就需要通过各种手段来优化 UITableView 的滚动流畅度。

<!-- more -->

## 第一步

发现 UITableView 滑动不流畅之后，我们首先考虑的就是，给 UITableViewCell 的 `estimatedRowHeight` 属性设置值，或者实现 `-tableView:estimatedHeightForRowAtIndexPath:` 代理方法。

UITableView 在第一次显示的时候，会调用  `-tableView:heightForRowAtIndexPath:` 代理方法来获取所有 cell 的高度，以此确定 UITableView 的 `contentSize`。当我们的 cell 非常多，cell 的布局又非常复杂，计算高度需要耗费很多时间，此时 UITableView 的显示就会卡顿，我们给 UITableView 添加预设高度，UITableView 会利用这个预设高度来计算 UITableView 的 `contentSize`，而不是调用 `-tableView:heightForRowAtIndexPath:`，只有在 cell 要出现的时候才会去调用 `-tableView:heightForRowAtIndexPath:` 来获取真正的高度。

最近项目中用到了像 Instagram 发现页面，在进入详情页面之前，UITableView 需要滚动到指定位置。😆😆 So Easy! 在 `-viewWillAppear:` 调用 UITableView 的 `-scrollToRowAtIndexPath:atScrollPosition:animated:` 方法就好了，cmd+R 运行看效果，效果挺好，但是数据很多，在详情页面出现的时候会卡顿 1～2 秒，我们需要优化 UITableView，当然就是给 UITableView 设置预设高度，cmd+R，没有之前那么卡，还能接受，但是有个问题了，进入详情页面之后，UITableView 的 `contentOffset` 不对，我只是加了预设高度而已 😭😭。

👐👐 没办法只有万能的 Google 大法和 StackOverflow 大法能拯救我，查找了一大圈，在 **[这里][8]** 找到了答案，原因是在 `-viewWillAppear:` 方法中，UITableView 的 `bounds` 和 `frame` 都不确定，计算 UITableView 的 `contentOffset` 需要用到其中之一。解决办法就是在 `-viewDidLayoutSubviews` 方法中调用 UITableView 的 `-scrollToRowAtIndexPath:atScrollPosition:animated:` 方法。在 iOS 7 上我们还需要在 `-viewDidLayoutSubviews` 方法的末尾调用 `[self.view layoutIfNeeded];` 来防止 iOS 7 上崩溃，在 **[这里][7]** 了解更多。

OK，已经处理到这样，应该没有问题了，运行程序，进入详情页面 UITableView 的位置没问题，项目这里有点赞的功能，问题又来了，点赞完之后需要刷新 UITableViewCell，这时我们能看到一个非常神奇的现象，就是刷新这一行 cell 之后，UITableView 会滚动一段距离。~~WTF，这是什么鬼。~~因为我们给的预设高度只是一个近似值，刷新 UITableView 貌似会使用到预设高度，而不是使用真正的高度，所以这里 UITableView 会滚动，同样 Google 了一大圈，都说将 cell 的高度缓存起来，然后在 `-tableView:estimatedHeightForRowAtIndexPath:` 方法中返回，正好项目中用到了 **[UITableView+FDTemplateLayoutCell][5]** 来计算 cell 的高度，计算完高度之后会缓存起来，我们就利用这个来设置 UITableView 的预设高度。使用一个 flag 来标记是否利用 `UITableView+FDTemplateLayoutCell` 来返回预设高度。大概的实现代码：

```
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath 
                          atScrollPosition:UITableViewScrollPositionNone 
                                  animated:NO];
    flag = NO; // flag 在 init 的时候设置为 YES
    [self.view layoutIfNeeded]; // fix iOS7 crash
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView fd_heightForCellWithIdentifier:identifier
                                          cacheByKey:uniqueCacheKey
                                       configuration:nil];
}

// 给定固定的值会导致 tableView 在 reload 的时候出现跳跃问题
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (flag) { return 650.0; }
    // 这里的 identifier 和 cacheByKey 使用的值需要与上一个方法使用的值一致
    return [tableView fd_heightForCellWithIdentifier:identifier
                                          cacheByKey:uniqueCacheKey
                                       configuration:nil];
}
```

> 更多关于 **UITableView+FDTemplateLayoutCell**，可以看这篇 **[优化UITableViewCell高度计算的那些事][9]** 博客，强烈推荐。

## 第二步

在初学的时候，我们经常会在这个 `-tableView:cellForRowAtIndexPath:` 数据源方法中绑定模型数据，这个方法调用的次数非常频繁，我们需要尽可能快的返回 UITableViewCell 实例。所以，我们尽量不在这个方法中绑定 cell 的模型数据，而在 `-tableView:willDisplayCell:forRowAtIndexPath` 代理方法中来绑定数据，这个方法会在 cell 显示之前调用。

## 第三步

这一步跟第二步几乎相同，就是在 `-tableView:heightForRowAtIndexPath:` 这个代理方法尽快返回，不要在这个方法中做太多的运算。

## 第四步

这一步主要是总结一些平常常用的优化技巧，这些都是我在网上看到的，感谢那些乐意分享知识的人。

**Image Cache**
将我们在 cell 上显示的 image 缓存起来，这个已经老生常谈了，而且做到这一步也不是特别困难

* `[UIImage imageNamed:@"abc"];` 这个是系统提供的方法，会在第一次引用这张图片的时候去应用的 main bundle 里加载适应屏幕分辨率的图片，并且系统会将这张图片缓存起来，之后再用这张图片就会使用缓存，而不用再去加载。但是这个方法会有一点小问题，就是你不能控制缓存图片的销毁，系统会在适当的时候来清除没有使用的图片数据。如果你只使用这个图片一次，之后就不会使用并且希望能马上释放，使用 `imageWithContentsOfFile:` 方法，这个方法不会在缓存中保存图片数据。
* 利用 ObjC 开发 iOS 的时候，加载网络图片通常用的是 [SDWebImage][6]，这个库会在内存中和磁盘中缓存图片资源，再次利用图片会优先在缓存中查找。PS: Swift 可以使用 [Kingfisher][10]。

**AutoLayout**
平常我们在编写 UI 布局的时候，一般有两个方法

* 纯代码手写：灵活多变，但是在编写复杂 UI 界面时，代码会非常冗长且没有什么意义。
* 利用 Xib 或者 StoryBoard：布局 UI 界面非常快，但是在多人合作的时候会有许多问题，~~因为每次打开这些文件就会更改内容，即使你什么都没做，所以~~你可能有许多冲突需要解决，并且这些文件的冲突还不好解决。这些文件本质上是 XML 文件，Xcode 将其识别为 UI 界面，但是我们解决冲突的时候是编辑 XML 文件，所以到底需要保留那一部分代码，常常让我们非常困惑。

抱歉说了这么多废话 😅😅

我们经常需要自定义 UITableViewCell 的子类，UITableViewCell 的布局有时会很复杂，因为要适配多种屏幕，所以，利用 Autolayout 无疑是挺好的选择，尤其是利用 Xib 和 SB 编写 UI 的时候。但是，当你的布局非常复杂同样会影响 UITableView 的滚动流畅度，因为系统需要花大量的时间去计算 UI 界面的布局，更具体的原因可以看 **[这里][4]**。当你想要将 UITableView 优化到极致，不妨可以考虑一下优化 AutoLayout。

**Layer Opaque**
尽量将 CALayer 的这个属性设为 YES，这样系统就不会渲染在这个 view 之后的 view，也不会将 view 与其混合。可以设置 cell 的 `backgroundColor` 属性，这个会跟系统自带的 highlight 冲突，因为系统自带的 highlight 依赖于透明度。当 cell 不可点击的时候，这样非常有用。

**Row Height Cache**
当 UITableViewCell 子类的布局非常复杂，计算高度就会很耗时，我们在计算过一次之后，就可以将高度数据缓存起来，等到再次需要的时候就直接从缓存中获取，而不需要再耗费时间去计算。再次推荐 **[UITableView+FDTemplateLayoutCell][5]**。
 
## 最后

这篇断断续续写了好几天，废话很多，主要记录自己的心得。非常感谢您能看到这。😘😘
不出意外的话，还会有一篇来记录 UITableView 的优化。

## 相关链接

* [Using Auto Layout in UITableView for dynamic cell layouts & variable row heights][1]
* [Glassy Scrolling with UITableView][2]
* [How can I speed up a UITableView?][3]

[1]: http://stackoverflow.com/questions/18746929/using-auto-layout-in-uitableview-for-dynamic-cell-layouts-variable-row-heights/18746930#18746930
[2]: http://www.fieryrobot.com/blog/2008/10/01/glassy-scrolling-with-uitableview/
[3]: http://stackoverflow.com/questions/6172158/how-can-i-speed-up-a-uitableview
[4]: http://draveness.me/layout-performance/
[5]: https://github.com/forkingdog/UITableView-FDTemplateLayoutCell
[6]: https://github.com/rs/SDWebImage
[7]: http://stackoverflow.com/a/28244609
[8]: http://stackoverflow.com/a/22428455
[9]: http://blog.sunnyxx.com/2015/05/17/cell-height-calculation/
[10]: https://github.com/onevcat/Kingfisher
