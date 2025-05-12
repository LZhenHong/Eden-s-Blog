---
title: Objective-C 字面量
date: 2017-09-01 19:46
tags: ObjC
published: true
hideInList: false
feature: 
isTop: false
---

有段时间没看关于 iOS 的东西了，前段时间在翻 Instapaper 的时候看到了 [NSVALUE AND BOXED EXPRESSIONS][2] 这篇文章，就随便看了看，正好自己对这些也不是很了解，就记录下来。

在 Apple LLVM Compiler 4.0 支持嵌套表达式 (Boxed Expressions)。即可以用 @(<expressions>) 的方式生成相应的对象，例如：@1 相当于 `[NSNumber numberWithInt:1];`，@1 称为 NSNumber 字面量。ObjC 中还有集合字面量，以及通过下标来访问 OC 对象。下面介绍在 OC 中字面量的使用。

<!-- more -->

## NSNumber 字面量

`NSNumber` 字面量支持有符号、没有符号的整数 (char, short, int, long, long long)，支持浮点数 (float, double)，也支持布尔值 (BOOL, C++ bool)。在 Objective-C 中，任何字母、数字和布尔值的字面量前面有 @ 都会被当成指向用 @ 后面的值创建的 `NSNumber` 对象。

```
void main(int argc, const char *argv[]) {
    // character literals.
    NSNumber *theLetterZ = @'Z';          // equivalent to [NSNumber numberWithChar:'Z']

    // integral literals.
    NSNumber *fortyTwo = @42;             // equivalent to [NSNumber numberWithInt:42]
    NSNumber *fortyTwoUnsigned = @42U;    // equivalent to [NSNumber numberWithUnsignedInt:42U]
    NSNumber *fortyTwoLong = @42L;        // equivalent to [NSNumber numberWithLong:42L]
    NSNumber *fortyTwoLongLong = @42LL;   // equivalent to [NSNumber numberWithLongLong:42LL]

    // floating point literals.
    NSNumber *piFloat = @3.141592654F;    // equivalent to [NSNumber numberWithFloat:3.141592654F]
    NSNumber *piDouble = @3.1415926535;   // equivalent to [NSNumber numberWithDouble:3.1415926535]

    // BOOL literals.
    NSNumber *yesNumber = @YES;           // equivalent to [NSNumber numberWithBool:YES]
    NSNumber *noNumber = @NO;             // equivalent to [NSNumber numberWithBool:NO]

#ifdef __cplusplus
    NSNumber *trueNumber = @true;         // equivalent to [NSNumber numberWithBool:(BOOL)true]
    NSNumber *falseNumber = @false;       // equivalent to [NSNumber numberWithBool:(BOOL)false]
#endif
}
```

NSNumber 只支持数字前面带 @，举个例子：

```
#define INT_MAX   2147483647  /* max value for an int */
#define INT_MIN   (-2147483647-1) /* min value for an int */
```

NSNumber 字面量支持 `@INT_MAX`，但是不支持 `@INT_MIN`，因为 `INT_MIN` 是一个表达式，`@INT_MIN` 称为嵌套表达式。NSNumber 字面量不支持 `long double`，所以类似于 `@123.23L` 这个写法是不合法，编译器会报错。

以前，BOOL 值只是 `signed char` 的 `typedef`，YES 是 (BOOL)1，NO 是 (BOOL)0。但是为了支持 `@YES` 和 `@NO` 这种写法，这些宏被重新定义：

```
#if __has_feature(objc_bool)
#define YES             __objc_yes
#define NO              __objc_no
#else
#define YES             ((BOOL)1)
#define NO              ((BOOL)0)
#endif
```

Objective-C++ 还支持 `@true` 和 `@false` 表达式，跟 `@YES` 和 `@NO` 是相同的。

## 嵌套表达式

### NSString

现在 iOS 开发中使用 OC 字符串，都可以很简单的创建：`NSString *str = @"some string.";`，但是这个其实是 @ 加上一个 C 类型的字符串生成 `NSString`，这个也就是 `NSString` 字面量。跟前面的 `NSNumber` 很像，当 @ 后面跟的表达式是 `(char *)` 或者是 `(const char *)` 类型的，这个嵌套表达式的结果就是指向 `NSString` 对象的指针，这个 `NSString` 对象跟 C 字符串包含相同的字符，并且是以 `\0` 结尾和 UTF-8 编码。有个例子是将 C 字符串风格的命令行参数转成 `NSString`：

```
// Partition command line arguments into positional and option arguments.
NSMutableArray *args = [NSMutableArray new];
NSMutableDictionary *options = [NSMutableDictionary new];
while (--argc) {
    const char *arg = *++argv;
    if (strncmp(arg, "--", 2) == 0) {
        options[@(arg + 2)] = @(*++argv);   // --key value
    } else {
        [args addObject:@(arg)];            // positional argument
    }
}
```

我们需要保证嵌套表达式中的 C 字符串是有效的，不能是 `NULL`，在运行时传递 `NULL` 会导致抛出异常。编译器也会尽可能拒绝向嵌套表达式中传递 `NULL`。

### 嵌套枚举

尽管枚举值是整数，但是枚举还是不能直接作为嵌套字面量使用，这样是为了避免前缀是 @ 符号的 Objective-C 关键字。枚举值必须放在嵌套表达式中，下面的例子表明了在字典中使用 `AVAudioRecorder` 枚举：

```
enum {
  AVAudioQualityMin = 0,
  AVAudioQualityLow = 0x20,
  AVAudioQualityMedium = 0x40,
  AVAudioQualityHigh = 0x60,
  AVAudioQualityMax = 0x7F
};

- (AVAudioRecorder *)recordToFile:(NSURL *)fileURL {
  NSDictionary *settings = @{ AVEncoderAudioQualityKey : @(AVAudioQualityMax) };
  return [[AVAudioRecorder alloc] initWithURL:fileURL settings:settings error:NULL];
}
```

`@(AVAudioQualityMax)` 这种语法将 AVAudioQualityMax 转换成为整数类型，并转换成相应的值。如果枚举像下面一样申明了类型，则编译器会选择 `NSNumber` 正确的创建方法：

```
typedef enum: unsigned char {
    Red,
    Green,
    Blue
} Color;
NSNumber *red = @(Red), *green = @(Green), *blue = @(Blue); // => [NSNumber numberWithUnsignedChar:]
```

## 集合字面量

使用字面量方式创建集合对象，需要注意避免 **nil**，如果在编译时期发现 **nil**，编译器会发出警告。在运行时期发现 **nil**，会抛出错误。

### NSArray

使用字面量创建数组 `NSArray *array = @[@"Hello", NSApp, [NSNumber numberWithInt:42]];`

用字面量创建集合对象更加安全。数组字面量语法实际上是调用 `+[NSArray arrayWithObjects:count:]` 方法，这个方法会保证所有数组中的对象都是**非 nil**。`+[NSArray arrayWithObjects:]` 这个方法使用 **nil** 作为结束符号，可能会造成不可预期的结果。

数组对象还支持 C 语言的下标语法：

```
NSMutableArray *array = ...;
NSUInteger idx = ...;
id newObject = ...;
id oldObject = array[idx];
array[idx] = newObject;         // replace oldObject with newObject
```

访问数组的下标是整数类型，编译器会根据是读取元素还是覆写元素展开成不同的方法。如果是读取元素，则会转换成 `objectAtIndexedSubscript:` 方法。如果是覆写元素，这会转换成 `setObject:atIndexedSubscript:` 方法。对于 `NSArray` 来说，访问 `[0, array.count)` 之外的位置编译器会抛出异常。对于 `NSMutableArray` 来说，给范围之内的位置赋值，会替换成这个值，但是给范围之外的位置赋值会抛出异常。没有给可变的数组提供插入、增加、删除元素的语法。

### NSDictionary

使用字面量创建字典：

```
NSDictionary *dictionary = @{
    @"name" : NSUserName(),
    @"date" : [NSDate date],
    @"processInfo" : [NSProcessInfo processInfo]
};
```

字典字面量也相似，字典字面量使用 `+[NSDictionary dictionaryWithObjects:forKeys:count:] ` 方法来创建字典对象，这个方法会保证所有的键值都**非 nil**。`+[NSDictionary dictionaryWithObjectsAndKeys:]` 方法也是使用 **nil** 来作为结束符。

`NSDictionary` 的键必须要实现 `<NSCopying>` 协议，值必须要是 Objective-C 的对象。

字典对象同样支持下标范围元素：

```
NSMutableDictionary *dictionary = ...;
NSString *key = ...;
oldObject = dictionary[key];
dictionary[key] = newObject;    // replace oldObject with newObject
```

访问字典的下标使用的对象，同样下标语法会根据读取还是覆写翻译成不用的方法。如果是读取元素，则会转换成 `objectForKeyedSubscript:` 方法。如果是覆写元素，这会转换成 `setObject:forKeyedSubscript:` 方法。

### NSValue

NSValue 可以保存任何的数字类，例如：int/float/char，还可以保存对象和结构体，NSValue 永远都是不可变的。NSValue 是一个抽象类，真正发挥作用的是 NSValue 的子类，可以继承自 NSValue 类，但是 NSValue 不为子类提供存储空间，需要子类自己实现。此外，NSValue 子类还需要实现两个简单的方法。任何继承自 NSValue 的子类需要覆写 `valueWithBytes:objCType:` 和 `getValue:` 方法，这两个方法需要操作你提供的值的内存空间。NSValue 没有指定初始化函数，所以自定义的初始化函数只需要调用 `super` 的 `init` 方法就好了。NSValue 还遵守 `NSCopying` 和 `NSSecureCoding` 协议，如果子类需要支持 copying 和 coding，实现这两个协议的方法。

如果需要 NSValue 支持集合，NSValue 还需要重写 `hash` 方法。

如果你只想使用 NSValue 来包装你的数据结构，你可以不需要创建 NSValue 子类，使用分类是更好的选择。下面定义了 `Polyhedron` 结构体，并使用 NSValue 的分类方法来获得和储存 `Polyhedron` 结构体：

```
typedef struct {
    int numFaces;
    float radius;
} Polyhedron;

@interface NSValue (Polyhedron)
@property (readonly) Polyhedron polyhedronValue;

+ (instancetype)valuewithPolyhedron:(Polyhedron)value;
@end

@implementation NSValue (Polyhedron)
+ (instancetype)valuewithPolyhedron:(Polyhedron)value {
    return [self valueWithBytes:&value objCType:@encode(Polyhedron)];
}

- (Polyhedron)polyhedronValue {
    Polyhedron value;
    [self getValue:&value];
    return value;
}
@end
```

## 自定义的 C 结构体支持 Boxed Value

上面说了嵌套表达式支持 `NSValue`，而 `NSValue` 是支持结构体的，唯一的要求就是将结构体标记为 `objc_boxable`。

```
struct __attribute__((objc_boxable)) Point {
    // ...
};

typedef struct __attribute__((objc_boxable)) _Size {
    // ...
} Size;

typedef struct _Rect {
    // ...
} Rect;

struct Point p;
NSValue *point = @(p);          // ok
Size s;
NSValue *size = @(s);           // ok

Rect r;
NSValue *bad_rect = @(r);       // error

typedef struct __attribute__((objc_boxable)) _Rect Rect;

NSValue *good_rect = @(r);      // ok
```

为了支持老版本的框架或者是第三方框架，需要使用 `typedef` 来添加这个特性，像这样 `typedef struct __attribute__((objc_boxable)) _Rect Rect;`。

## 警告

使用字面量和嵌套表达式创建的对象，在运行时不能保证唯一性，也不能保证是重新分配的内存。因此直接使用地址来判断对象是否相等是有问题的，例如：== \ != \ < \ <= \ > \ >= 这些运算符。应该使用 `isEqual:` 或者 `compare:` 方法来判断。

<!-- This caveat applies to compile-time string literals as well. Historically, string literals (using the @"..." syntax) have been uniqued across translation units during linking. This is an implementation detail of the compiler and should not be relied upon. If you are using such code, please use global string constants instead (NSString * const MyConst = @"...") or use isEqual:. -->

还有一点就是要注意检查是否支持新语法：

```
#if __has_feature(objc_array_literals)
    // new way.
    NSArray *elements = @[ @"H", @"He", @"O", @"C" ];
#else
    // old way (equivalent).
    id objects[] = { @"H", @"He", @"O", @"C" };
    NSArray *elements = [NSArray arrayWithObjects:objects count:4];
#endif

#if __has_feature(objc_dictionary_literals)
    // new way.
    NSDictionary *masses = @{ @"H" : @1.0078,  @"He" : @4.0026, @"O" : @15.9990, @"C" : @12.0096 };
#else
    // old way (equivalent).
    id keys[] = { @"H", @"He", @"O", @"C" };
    id values[] = { [NSNumber numberWithDouble:1.0078], [NSNumber numberWithDouble:4.0026],
                    [NSNumber numberWithDouble:15.9990], [NSNumber numberWithDouble:12.0096] };
    NSDictionary *masses = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:4];
#endif

#if __has_feature(objc_subscripting)
    NSUInteger i, count = elements.count;
    for (i = 0; i < count; ++i) {
        NSString *element = elements[i];
        NSNumber *mass = masses[element];
        NSLog(@"the mass of %@ is %@", element, mass);
    }
#else
    NSUInteger i, count = [elements count];
    for (i = 0; i < count; ++i) {
        NSString *element = [elements objectAtIndex:i];
        NSNumber *mass = [masses objectForKey:element];
        NSLog(@"the mass of %@ is %@", element, mass);
    }
#endif

#if __has_attribute(objc_boxable)
    typedef struct __attribute__((objc_boxable)) _Rect Rect;
#endif

#if __has_feature(objc_boxed_nsvalue_expressions)
    CABasicAnimation animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.fromValue = @(layer.position);
    animation.toValue = @(newPosition);
    [layer addAnimation:animation forKey:@"move"];
#else
    CABasicAnimation animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.fromValue = [NSValue valueWithCGPoint:layer.position];
    animation.toValue = [NSValue valueWithCGPoint:newPosition];
    [layer addAnimation:animation forKey:@"move"];
#endif
```

## 参考链接

* [Objective-C Literals][1]
* [NSVALUE AND BOXED EXPRESSIONS][2]
* [Objective-C LLVM 4.0 的新特性][3]
* [NSValue Class][4]

[1]: http://clang.llvm.org/docs/ObjectiveCLiterals.html#boxed-c-structures
[2]: https://lowlevelbits.org/nsvalue-and-boxed-expressions/
[3]: http://blog.csdn.net/kindazrael/article/details/8091201
[4]: https://developer.apple.com/documentation/foundation/nsvalue?language=objc
