---
title: C# 扩展方法
date: 2022-07-10 02:09
tags: C#
published: true
hideInList: false
feature: 
isTop: false
---
为什么想要把 C# 的方法扩展单独拿出来讲一下呢？

因为当我们学习一门新的编程语言时，很多时候都会拿这门编程语言跟我们熟悉的编程做对比。因为编程语言的设计者不同，编程思想和理念是存在很多差别的，就算是同样相同的面向对象的编程语言，也会在细节上存在各种差异。

<!-- more -->

我个人的编程经历是从 C 语言入门，然后就开始学习 Objective-C，在随后很长一段时间里都是和 OC 打交道，作为第一门面向对象的编程语言，OC 很大程度上影响了我的编程习惯和风格，以至于在学习其他编程语言时都会跟 OC 做对比，或者代入 OC 的编程习惯。

当我在 C# 中看到**扩展方法**时，很快就联想到 OC 里面的类扩展。他们都可以在不修改类源码的前提下，扩展类的实例方法，但是在实现方式上存在差异。因此想简单记录下 C# 的扩展方法使用以及与 OC 类扩展的异同点。

# 扩展实现

先了解一下 C# 中如何实现扩展方法：

```c#
using System;
using System.Security.Cryptography;
using System.Text;

namespace Extension
{
    public static class StringExt
    {
        /// <summary>
        /// 将字符串转换成 MD5
        /// </summary>
        /// <returns>加密后的 MD5 值</returns>
        public static string MD5(this string text)
        {
            var md5 = new MD5CryptoServiceProvider();
            byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(text));
            string md5Hash = BitConverter.ToString(bytes).Replace("-", "").ToLower();
            return md5Hash;
        }
    }
}
```

这种方式看起来的和我们自定义普通的静态工具类看起来没有什么区别，但是注意在方法的参数前面有一个 `this` 的修饰词，这个 `this` 关键字就是 C# 定义扩展方法的魔法。

如果没有 `this` 关键字，我们调用这个 MD5 方法的方式是 `StringExt.MD5(str);` 这样的。

在加上了 `this` 关键字之后，我们就可以像调用 string 的实例方法一样去调用 MD5 方法 `str.MD5();`，同样我们也可以像上面一样方式 `StringExt.MD5(str);` 调用。这样的调用方式看起来更符合直觉，对字符串进行 MD5 就应该像是字符串的实例方法。

# 扩展接口

如果我们需要为 C# 写一些工具类方法，扩展方法是很理想的实现方式。但是扩展方法的使用场景更强大，上面举的例子是针对于特定的类实现的扩展方法，但是扩展方法还可以针对于接口。例如： `System.Linq.Enumerable` 中有很多对接口 `IEnumerable<T>` 的扩展方法 (`Where/SortBy/ThenBy `等)。

下面的例子来自《Effective C#》P125：

```c#
public static class Comparable
{
    public static bool LessThan<T>(this T left, T right) where T : IComparable<T> => left.CompareTo(right) < 0;
}
```

这里示例是扩展 `IComparable` 接口，所有实现 `IComparable` 接口类的实例都可以使用 `LessThan` 方法，这个就是扩展方法强大的地方。虽然没有 Swift 扩展那么强大，但是也足够我们在扩展类的方法上有了另一种选择。

用扩展的方式来扩充类方法是最好的实践，我们可以利用 `namespace` 来区分不同分类的扩展方法。例如：把排序相关的扩展方法放在 Sort 命名空间下，把转换相关的扩展方法放在 Transform 命名空间下，这样使用者就是根据自身的需求来引入不同的命名空间，来扩展现有类的实例方法。在扩展方法的支持下，我们把一个类的实现分成基础类加上不同分类的扩展方法，这样的实现方法可以减少对原始类的修改或者编写新的派生类。

# 注意点

扩展方法的实现方法是因为 C# 编译器在编译过程中生成的中间语言 (IL) 会将扩展方法的实例调用转换成对静态方法的调用。所以 `str.MD5();` 在经过编译器编译之后与 `StringExt.MD5(str);` 是没有区别的。

当了解了编译器的实现扩展方法的方式之后，我们对扩展方法的特点也可以描述出来。

1. 可以利用扩展方法为枚举类型编写方法。

2. 如果扩展方法是针对于值类型，因为值类型的参数传递是复制，在扩展方法中的修改不会影响原始值，可以使用 `ref` 关键字解决。

3. 不能重写扩展方法 ，当有多个相同方法签名的扩展方法时，C# 编译器会选择第一个被找到的扩展方法。

4. 如果扩展方法与该类型中定义的方法具有相同的方法签名，C# 编译器在编译过程中选择方法实现时会优先选择类型中定义的方法，扩展方法不会被调用。

5. 不能访问类型中的私有变量，这个跟静态方法的限制是一样的。

# 相关链接

1. [扩展方法（C# 编程指南）][1]
1. [如何实现和调用自定义扩展方法（C# 编程指南）][2]
1. 《Effective C#》第 27 条、第 28 条

<!-- more -->

[1]: https://docs.microsoft.com/zh-cn/dotnet/csharp/programming-guide/classes-and-structs/extension-methods
[2]:  https://docs.microsoft.com/zh-cn/dotnet/csharp/programming-guide/classes-and-structs/how-to-implement-and-call-a-custom-extension-method
