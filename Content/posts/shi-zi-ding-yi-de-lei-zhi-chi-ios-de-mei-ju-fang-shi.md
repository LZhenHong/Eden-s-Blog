---
title: 使自定义的类支持 iOS 的枚举方式
date: 2017-02-27 09:43
tags: ObjC
published: true
hideInList: false
feature: 
isTop: false
---

事先可以看一下 [Comparison of Objective-C Enumeration Techniques][1] 和 [NSFastEnumeration / NSEnumerator][2]，对比了 ObjC 中各种遍历方式。

<!-- more -->

在 iOS 中主要有 4 种类型的遍历：

* C 语言风格
* NSEnumerator
* 基于 block 的遍历
* NSFastEnumeration

## C 语言风格

```
NSArray *nums = @[@1, @2, @3];
for (int i = 0; i < nums.count, ++i) {
    NSLog(@"%@", nums[i]);
}
```

形如上面这样的利用 for 循环，然后使用下标去访问对象的方式，就是 C 语言风格的遍历。

要支持这种 C 语言风格遍历就需要实现 `objectAtIndexedSubscript:` 方法，这是因为编译器会将 `someArray[0]` 解析成 `[someArray objectAtIndexedSubscript:0]`。

```
@interface TestArray: NSObject
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
@end

@implementation TestArray {
    std::vector<NSNumber *> _numberList;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (idx >= _numberList.size()) {
        // 抛出异常
    }
    return _numberList[idx];
}
@end
```

如果要支持使用键作为下标来访问值，就需要实现 `objectForKeyedSubscript:` 方法。

## NSEnumerator

```
NSArray *numberArray = @[@1, @2, @3];
NSEnumerator *enumerator = [numberArray objectEnumerator];
NSNumber *number;
while (number = [enumerator nextObject]) {
    // 对 number 对象进行操作
}
```

这是 ObjC 原来遍历集合的标准方式，但是这种写法很冗长。虽然现在基本上不用这种方式了，还是来看一下如何支持这种方式的遍历。

要支持这种遍历方式主要还是实现一个 `objectEnumerator` 方法返回 `NSEnumerator` 对象。这里的 `NSEnumerator` 是抽象类，需要继承 `NSEnumerator` 然后实现 `-nextObject:` 方法。

```
@interface TestEnumerator: NSEnumerator
@property (nonatomic, readonly) TestArray *array;

- (instancetype)initWithTestArray:(TestArray *)array;
@end

@implementation TestEnumerator {
    NSUInteger _currentIndex;
}

- (instancetype)initWithTestArray:(TestArray *)array {
    if (self = [super init]) {
        _array = array;
        _currentIndex = 0;
    }
    return self;
}

- (id)nextObject {
    if (_currentIndex >= [self.array numberOfItems]) {
        return nil;
    } else {
        return array[_currentIndex++]; // 假设 TestArray 实现了 `objectAtIndexedSubscript:` 方法
    }
}

// 这里还需要注意的是 NSEnumerator 会自动实现 `-allObjects` 方法，将 `-nextObject` 方法返回的对象填入数组中
@end


@interface TestArray: NSObject
- (NSEnumerator *)objectEnumerator;
- (NSUInteger)numberOfItems;
@end

@implementation TestArray {
    std::vector<NSNumber *> _numberList;
}

- (NSUInteger)numberOfItems {
    return _numberList.size();
}

- (NSEnumerator *)objectEnumerator {
    return [[TestEnumerator alloc] initWithTestArray:self];
}
@end
```

`NSEnumerator` 也是遵守 `NSFastEnumeration` 协议，所以可以还可以使用 for-in 循环来遍历 `NSEnumerator` 对象。

## 基于 block 的遍历

```
NSArray *array = @[@1, @2, @3];
[array enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    NSLog(@"%@", object);
}];
```

这种遍历是现在经常使用的方式，而且这种方式还提供了很多有用的特性。

```
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block
```

上面这个方法就可以指定 `NSEnumerationOptions` 参数，可以反向遍历和并行遍历。同时系统会在这个方法的 block 里添加一个 `autoreleasepool`。

这里不太懂，苹果官方给出的例子也就是简单的实现了 `enumerateObjectsUsingBlock:` 方法。苹果官方例子：[FastEnumerationSample][3].

## NSFastEnumeration

```
NSArray *array = @[@1, @2, @3];
for (NSNumber *number in array) {
    NSLog(@"%@", number);
}
```

利用 for-in 遍历容器对象也是非常常见的遍历方法，并且这种方式也是最快的，要让自定义的对象支持这种遍历模式还是比较麻烦的。

支持这种遍历模式的对象需要遵守 `NSFastEnumeration` 协议，并实现方法：

```
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len;
```

接下来详细解释下这些参数的含义：

* state: 这是个 `NSFastEnumerationState` 的结构体，申明如下：

```
typedef struct {
    // 在第一次调用 `countByEnumeratingWithState:objects:count:` 方法时，state 为 0，
    // 这个在遍历的时候用不到，可以用来存储额外信息
    unsigned long state; 
    // C 数组，`countByEnumeratingWithState:objects:count:` 方法调用者要去遍历的数组
    id *itemsPtr;
    // 用来检测遍历期间数组是否被修改
    unsigned long *mutationsPtr;
    // 存储额外信息
    unsigned long extra[5]; 
} NSFastEnumerationState;
```
* stackbuf: `countByEnumeratingWithState:objects:count:` 方法调用者提供的数组，当我们数据结构是不连续的内存时，需要用到这个数组
* len: stackbuf 数组的长度，当使用到 stackbuf 数组时，需要用到 len 来检测

实现 `countByEnumeratingWithState:objects:count:` 这个方法，还需要挺多要写的，打算另写一篇来说如何实现。

## 相关链接

* [Comparison of Objective-C Enumeration Techniques][1]
* [NSFast​Enumeration / NSEnumerator][2]
* [FastEnumerationSample][3]

[1]: https://www.mikeash.com/pyblog/friday-qa-2010-04-09-comparison-of-objective-c-enumeration-techniques.html
[2]: http://nshipster.com/enumerators/
[3]: https://developer.apple.com/library/ios/#samplecode/FastEnumerationSample/Introduction/Intro.html


