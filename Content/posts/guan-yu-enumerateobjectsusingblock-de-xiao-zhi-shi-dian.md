---
title: 关于 enumerateObjectsUsingBlock 的小知识点
date: 2016-09-08 11:40
tags: ObjC
published: true
hideInList: false
feature: 
isTop: false
---

在 StackOverflow 上看到 **[这篇讨论][1]** 的时候，让我发现了自己的盲区，所以写下这篇文章记录一下。

有一次在项目中使用的 `enumerateObjectsUsingBlock` 遍历数组的时候，使用了 return，当时没有多想，在 code review 的时候被同事指出，当时觉得不妥就改掉了，今天突然想起就去搜了一下。项目中好像没有直接跳出方法，而是执行到循环外面（这里的需求是当遍历到最后一个直接跳出循环，return 在 `enumerateObjectsUsingBlock` 相当于 continue，所以项目中会造成直接跳出循环）。

<!--more -->

### ObjC 中遍历容器数据

在 ObjC 中有好几种遍历容器数据的方式，这里讨论一下常用的三种。


#### C 语言风格

这种不需要多说，直接上代码

```objectivec
NSArray *names = @[@"lzh", @"ysh", @"yys"];
for (int i = 0; i < names.count; ++i) {
   NSString *name = names[i];
   NSLog(@"%@", name);
}
```

#### ObjC 风格

这种相信会 ObjC 的人都会，也直接上代码。这里本质是使用了 NSFastEnumeration，在 **[这里][3]** 了解更多

```objectivec
NSArray *names = @[@"lzh", @"ysh", @"yys"];    
for (NSString *name in names) {
   NSLog(@"%@", name);
}
```

在上面两种遍历中，我们还可使用 `continue` 和 `break` 来控制循环的跳转逻辑。

#### ObjC 中的 block 方式

我们看一下如何在 `enumerateObjectsUsingBlock:` 这里控制跳转逻辑

* stop 参数的作用：停止遍历，但是会执行完 block 的代码才会退出循环

 ```objectivec
NSArray *names = @[@"lzh", @"ysh", @"yys"];
[names enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isEqualToString:@"lzh"]) {
       *stop = YES; // 这里并不会马上退出循环，而是执行完 block 中的代码才退出循环
    }
    NSLog(@"Name %@\n", obj);
}];
```

运行结果：
![1.png][9]

* return 的作用：相当于前两种循环的 `continue`，会跳过此次循环

```objectivec
NSArray *names = @[@"lzh", @"ysh", @"yys"];
[names enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isEqualToString:@"lzh"]) {
       return; // 跳出此次循环
    }
    NSLog(@"Name %@\n", obj);
}];
```

运行结果：
![2.png][10]

* 马上退出循环

```objectivec
NSArray *names = @[@"lzh", @"ysh", @"yys"];
[names enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isEqualToString:@"ysh"]) {
        *stop = YES;
        return; // 立马跳出循环，并退出
    }
    NSLog(@"Name %@\n", obj);
}];
```

运行结果：
![3.png][11]

#### 补充循环遍历的了解

在看了 **[iOS 中集合遍历方法的比较和技巧][2]** 之后觉得自己对 ObjC 中的循环遍历还是了解的不好，决定再补上学到的知识。

其他几种循环遍历：
* makeObjectsPerformSelector
* KVC 集合运算符
* enumerateObjectsUsingBlock
* enumerateObjectsWithOptions(NSEnumerationConcurrent)
* dispatch_apply

##### 倒序遍历

```objectivec
NSArray *strings = @[@"1", @"2", @"3"];
for (NSString *string in [strings reverseObjectEnumerator]) {
    NSLog(@"%@", string);
}
```

`reverseObjectEnumerator` 这个方法只会在循环第一次的调用。

```objectivec
[array enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Sark *sark, NSUInteger idx, BOOL *stop) {
    [sark doSomething];
}];
```

##### 并发遍历

对于与顺序无关的遍历，我们可以使用并发来遍历容器数据。

##### block 枚举比 for 循环的好处

使用 block 来枚举时，block 内部会自动添加一个 autoreleasepool：

```objectivec
[array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    // 这里有一个 @autoreleasepool 包围着
}];
```

在普通 for 循环和 for-in 循环中没有，新版的 block 版本枚举器更加方便。for 循环中遍历产生大量 autorelease 变量时，就需要手动加局部 autoreleasepool。

### 总结

这篇文章没有什么含量，只是将自己不知道的知识点记录下来。😅😅

## 相关链接

* [What is the BOOL *stop argument for enumerateObjectsUsingBlock: used for?][1]
* [iOS 中集合遍历方法的比较和技巧][2]
* [黑幕背后的Autorelease][4]

[1]: http://stackoverflow.com/questions/12357904/what-is-the-bool-stop-argument-for-enumerateobjectsusingblock-used-for
[2]: http://blog.sunnyxx.com/2014/04/30/ios_iterator/
[3]: http://nshipster.com/enumerators/
[4]: http://blog.sunnyxx.com/2014/10/15/behind-autorelease/

[9]: https://github.com/LZhenHong/BlogImages/blob/master/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202016-09-08%20%E4%B8%8B%E5%8D%881.28.56.png?raw=true
[10]: https://github.com/LZhenHong/BlogImages/blob/master/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202016-09-08%20%E4%B8%8B%E5%8D%881.35.05.png?raw=true
[11]: https://github.com/LZhenHong/BlogImages/blob/master/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202016-09-08%20%E4%B8%8B%E5%8D%881.37.50.png?raw=true
