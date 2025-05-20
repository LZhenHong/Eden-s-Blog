---
title: 详解 property
date: 2016-08-28 05:03
tags: ObjC
published: true
---

在利用 Objective-C 的开发中，我们需要创建许多的类，类包括成员变量和成员方法／类方法 (Objective-C 中没有类成员变量)。但是大部分 Obj-C 的类文件中都看不到成员变量的申明，我们更多看到的是形如： `@property (nonatomic, copy) NSString *name;` 。这是因为当我们这样写之后，Xcode 会自动为我们添加成员变量，并生成相应成员变量的存取方法。

<!-- more -->

* 手动编写成员变量／存取方法
```objectivec
@interface XYDog: NSObject {
    NSString *_name;
}
- (void)setName:(NSString *)name;
- (NSString *)name;
@end

@implementation XYDog
- (void)setName:(NSString *)name {
    _name = [name copy];
}

- (NSString *)name {
    return _name;
}
@end
```

* Xcode 自动生成
```objectivec
@interface XYDog: NSObject
@property (nonatomic, copy) NSString *name;
@end

@implementation XYDog
@end
```

仅通过 @property，Xcode 就自动生成手动编写的代码，这大大提高了开发效率。

## @property 之后的关键字

* 原子性：默认情况下，编译器合成的方法会通过锁定机制保证原子性
    * atomic：加锁，使用同步锁的开销较大，iOS 开发一般情况下不会用此关键字，Mac OS X 开发使用该关键字不会有性能瓶颈。
    * nonatomic：不加锁。

* 读/写权限：
    * readwrite：同时具有 `getter` 和 `setter`。
    * readonly：只有 `getter`。

* 内存管理：
    * assign：只针对 「储量类型」 的简单赋值操作 (int／double／CGFloat／CGRect)。
    * strong：为这种属性设置新值时，setter 会 retain 新值，release 旧值，再将新值设置给实例变量。
    * weak：为这种属性设置新值时，setter 不会 retain 新值，也不会 release 旧值，当引用的对象被释放时，该属性会被自动设为 nil。
    * unsafe_unretained：与 assign 相同，适用于对象类型，不会 retain 引用的对象，引用的对象被销毁后，不会被自动设为 nil。
    * copy：为这种属性设置新值时，不会 retain 新值，而会将其拷贝一份，在设置给实例变量。当属性类型为 `NSString *` 时，经常用这个关键字。

* 方法名：
    * getter=<name> 指定获取方法名，`@property (nonatomic, assgin, getter=isOn) BOOL on;`
    * setter=<name> 指定设置方法名。

## 自己申明成员变量

这是不是意味我们就不需要再关心成员变量的创建了？并不是。Xcode 在某些情况下，不会生成成员变量：

1. 重写了 readonly 属性的 getter
2. 重写了 readwrite 属性的 setter 和 getter
3. 在 .m 文件中用 @dynamic 标记的属性
在这些情况下，Xcode 会认为我们自己要管理成员变量，所以就不会合成成员变量。

在这几种情况下，假如我们需要成员变量的话，就得自己申明成员变量，这里有两种方法：

* 第一种

```objectivec
@interface XYDog: NSObject
@property (nonatomic, readonly) NSString *name;
@end
@implementation XYDog {
    NSString *_name;
}
- (NSString *)name {
    if (![_name isEqualToString:@"yys"]) {
        return @"lzh";
    }
    return _name;
}
@end
```

* 第二种

```objectivec
@interface XYDog: NSObject
@property (nonatomic, readonly) NSString *name;
@end
@implementation XYDog
@synthesize name = _name;
- (NSString *)name {
    if (![_name isEqualToString:@"yys"]) {
        return @"lzh";
    }
    return _name;
}
@end
```

这种方法还是告诉 Xcode 帮我们合成成员变量。

## 注意事项

我们访问成员变量的通常用的是形如 `dog.name` 的点语法，这不是 Objective-C 语言的特性，而是 Xcode 特性，Xcode 会把这样的语法翻译成调用 setter 或者 getter，因此我们能获得或者设置成员变量的值。

直接访问成员变量的语法是 `dog->name`，Objective-C 对象本质上是 C 语言的结构体，所有这里就是访问结构体的成员变量。同样在 .m 文件中用 `_name` 访问同样也是直接访问成员变量。

我们在 .m 文件中重写 setter 和 getter 方法时，有几点需要注意：

1. 不要在 getter 中使用形如 `self.name` 的语句来访问成员变量，Xcode 会将这个翻译成 getter 方法的调用，这里就会造成死循环。
2. 同样不要在 setter 中使用形如 `self.name = @"Jerry";` 的语句来设置成员变量的值，原因同上。
3. 我们应该使用 `_name` 或者 `_name = @"xxx;"` 来访问和设置成员变量的值。

