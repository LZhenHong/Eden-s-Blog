---
title: 实现 NSFastEnumeration
date: 2017-03-08 11:28
tags: ObjC
published: true
hideInList: false
feature: 
isTop: false
---

关于 `NSFastEnumeration` 的基本介绍可以看这篇 [使自定义的类支持 iOS 的枚举方式][7]。

不多说废话，直接进主题。

<!-- more -->

## 内部实现

要实现 `NSFastEnumeration`  协议，我们先看下内部实现，将下面的代码 `clang -rewrite-objc main.m` 成 C++ 代码。

```objectivec
NSArray *array = @[@1, @2, @3];
for (NSNumber *number in array) {
   NSLog(@"%@", number);
}
```

得到的 main.cpp 文件，我将代码改了一下，看起来比较友好一点。

```c
NSArray *array = @[@1, @2, @3];
NSNumber *number;

// NSFastEnumerationState
struct __objcFastEnumerationState enumState = { 0 };
// stackbuf
id __rw_items[16];

id l_collection = (id)array;
// 调用 countByEnumeratingWithState:objects:count: 方法
_WIN_NSUInteger limit = [l_collection countByEnumeratingWithState:&enumState objects:(id *)__rw_items count:(_WIN_NSUInteger)16];

// 判断是否遍历完毕，每次返回的是一个 C 数组，如果是 0 的话就不遍历
if (limit) {
    unsigned long startMutations = *enumState.mutationsPtr;
    // 不停的调用 countByEnumeratingWithState:objects:count: 方法，直到遍历完成
    do {
        unsigned long counter = 0;
        // 遍历获得的数组
        do {
            if (startMutations != *enumState.mutationsPtr) { // 判断数组是否被改变
                objc_enumerationMutation(l_collection); // 抛出异常
            }
            number = (NSNumber *)enumState.itemsPtr[counter++];
            NSLog(@"%@", number);
        } while (counter < limit);
    } while (limit = [l_collection countByEnumeratingWithState:&enumState objects:(id *)__rw_items count:(_WIN_NSUInteger)16]);
    number = ((NSNumber *)0);
} else {
    number = ((NSNumber *)0);
}
```

从上面的代码中我们看到内部实现，两个 `do-while` 循环去遍历容器对象。第一个 `do-while` 循环是不断调用 `countByEnumeratingWithState:objects:count:` 判断返回的数值，查看容器对象是否遍历完成。第二个 `do-while` 是去遍历 `enumState` 中 `itemPtr` 指向的 C 数组。我们可以将容器对象中的元素分成多次通过 C 数组返回，这里 `itemPtr` 和 `countByEnumeratingWithState:objects:count:` 返回的数值组成第二个 `do-while` 循环要遍历的 C 数组。

## 编码实现 NSFastEnumeration 协议

在看过内部实现之后，我们在实现 `countByEnumeratingWithState:objects:count:` 方法的时候就知道如何编写代码。

实现 `countByEnumeratingWithState:objects:count:` 方法有两种方式，一种是容器对象中的元素在内存存储是连续的，那么可以将 `NSFastEnumerationState` 的 `itemPtr` 直接设成这个容器的首地址，但是注意必须要是 C 数组。另一种是内存存储中不是连续的，例如：链表，这时候就需要用到 `countByEnumeratingWithState:objects:count:` 提供的 `stackbuf` 数组，同时 `state->itemPtr = stackbuf;`

接下来看下具体代码实现：

### 在内存空间中是连续的

```objectivec
@interface TestArray: NSObject
@end

@implementation TestArray {
    std::vector<NSNumber *> _numberList;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len {
    // 一次性将所有的元素都返回
    if (state->state == 0) { // 1
        __unsafe_unretained const id *const_array = _list.data();
        state->itemsPtr = (__typeof__(state->itemsPtr))const_array; // 2
        state->state = 1; // 3
        state->mutationsPtr = &state->extra[0]; // 4
        return _numberList.size(); // 5
    } else {
        return 0; // 6
    }
}
@end
```

1. 利用 `NSFastEnumeration` 的 `state` 来判断是否是第一次调用 `countByEnumeratingWithState:objects:count:` 方法，在前面的 C++ 代码中，我们看到第一次调用此方法的时候，`NSFastEnumeration` 结构体都被初始化成 0；
2. 将内部容器对象转换成 C 数组，然后设置给 `NSFastEnumeration` 的 `itemPtr` 成员；
3. 将 `NSFastEnumeration` 的 `state` 设置成 1，代表不是第一次调用此方法；
4. 令 `mutationsPtr` 设成固定值，这里没有对遍历容器对象改变做保护；
5. 返回 `itemPtr` 指向的 C 数组的长度；
6. 返回 0 表示遍历已经完成。

### 在内存空间中是不连续的

```objectivec
@interface TestLinkedList: NSObject
@end

@implementation TestLinkedList {
    struct Node *head;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len {
    if (state->state == 0) {
        state->mutationsPtr = &state->mutationsPtr;
        state->extra[0] = (long)head; // 1
        state->state = 1;
    }

    struct Node *currentNode = (struct Node *)state->extra[0];
    NSUInteger count = 0;

    state->itemsPtr = stackbuf; // 2

    while (currentNode && count < len) { // 3
        *stackbuf++ = currentNode->value;
        currentNode = currentNode->next;
        count++;
    }

    if (currentNode) {
        state->extra[0] = (long)currentNode->next; // 4
    }

    return count;
}
@end
```

这里的例子是从 [Implementing Fast Enumeration][2] 复制过来的。

1. 第一次遍历的时候将 head 存进 `extra`，原因下面解释；
2. 因为这里是不连续的内存空间，所以我们需要用到 `stackbuf` 数组，将 `itemPtr` 指向 `stackbuf` 数组；
3. 这里不仅要判断当前的节点是否为 NULL，还要判断是否超出了 `stackbuf` 的长度，这也是为什么要将节点存入 `extra` 的原因，因为有可能不能一次性遍历完成；
4. 将当前节点的下一个节点存入 `extra`，以便下一次调用 `countByEnumeratingWithState:objects:count:` 的时候使用。

## 更多

更多示例：[Implementing Fast Enumeration][2] 和 [FastEnumerationSample][6].

需要注意的是在 [Implementing Fast Enumeration][2] 这篇文章中利用 `state->mutationsPtr = (unsigned long *)self;` 来确保容器对象不会被改变是有一点问题的，关于这个有人在 [Twitter][4] 上说了。如果使用了 `isa-swizzling`，就可能会出现问题，所以使用 `state->mutationsPtr = &state->extra[0]; ` 或者 ` state->mutationsPtr = &state->mutationsPtr;` 是比较好一点的选择。

## 相关链接

* [Implementing Fast Enumeration][2]
* [Does anyone know how to implement the NSFastEnumeration protocol?][3]
* [Implementing countByEnumeratingWithState:objects:count:][1]
* [Objective-C Fast Enumeration 的实现原理][5]

[1]: https://www.cocoawithlove.com/2008/05/implementing-countbyenumeratingwithstat.html
[2]: https://www.mikeash.com/pyblog/friday-qa-2010-04-16-implementing-fast-enumeration.html
[3]: http://stackoverflow.com/a/4872564/5350993
[4]: https://twitter.com/gparker/status/316460848916865024
[5]: http://blog.leichunfeng.com/blog/2016/06/20/objective-c-fast-enumeration-implementation-principle/
[6]: https://developer.apple.com/library/ios/#samplecode/FastEnumerationSample/Introduction/Intro.html
[7]: https://lzhenhong.github.io/2017/02/27/Support-iOS-Enumeration/
