---
title: 如何实现 iOS MarkDown 编辑器
date: 2020-03-23 01:57
tags: iOS
published: true
hideInList: true
feature: 
isTop: false
---
从刚开始学习 iOS 的时候就很想做一款 MarkDown 的编辑工具，但是一直也没有下定决心去搞，最近想开始重新学习 iOS，就想到从 MarkDown 编辑器的实现方式学起，把这段时间学到的东西记录下来，方便以后查看。

<!-- more -->

## 实现方式

在 iOS 中实现 MarkDown 编辑器一般有两种方案：

1. 完全使用 WebView 来实现，从 MarkDown 的编辑到 MarkDown 效果的预览都是使用 WebView 来实现，通过 JavaScript 代码来处理 Objective-C 与 WebView 交互。这种就是能实时看到 MarkDown 的预览效果。
2. 使用 iOS 原生的 UITextView 处理 MarkDown 的编辑，用 WebView 来预览 MarkDown 效果，这种方式就不能像上面马上能看到实时的 MarkDown 效果，需要手动触发 WebView 的预览。在 Mac 和 iPad 上可以使用两个界面来分别展示编辑界面和预览界面，但是 iPhone 这种小屏幕使用这种方式就体验不是很好。

所以如何选择方案需要从技术和体验上一起考虑。

<!-- link -->
[1]: https://github.com/xitu/gold-miner/blob/master/TODO/choosing-right-markdown-parser.md
[2]: https://www.zhihu.com/question/28756456
[3]: https://commonmark.org
[4]: https://github.com/fletcher/MultiMarkdown-5
[5]: https://juejin.im/entry/57ad8e5ac4c97100546b2cab
