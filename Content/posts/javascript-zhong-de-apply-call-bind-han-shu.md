---
title: Javascript 中的 apply/call/bind 函数
date: 2017-07-05 23:23
tags: JS
published: true
hideInList: false
feature: 
isTop: false
---

有很长一段时间没有写博客了，前一段时间做毕设，写论文，改论文，答辩，拍毕业照... 很多很多不喜欢的事情，再加上那段时间沉不下心，就很少有机会去写博客了。

这周一刚进公司，开始做游戏，原来对游戏开发也不太了解，进公司这几天也一直都在学习各种东西，JS 语法，常见的 Cocos API 等等。今天在看 Cocos 的东西时，对 Cocos 的继承不是很了解，就去网上搜资料，在看 [John Resiq 的继承写法解析][1]的时候，对 `apply` 函数的用法不是很了解，于是又去查资料，这篇博客主要是记录自己对三个函数的理解，也让自己开始继续写博客。

<!-- more -->

关于这些函数网上的解析数不胜数，我这个 JS 方面的 green-hand 来写这三个函数，主要还是记录下自己的理解。

这三个函数，其中 `apply` 与 `call` 函数的作用基本相同，就是改变某个函数运行时的上下文，只是这两个函数接收参数的方式不同。`apply` 函数接收的参数是包含多个参数的数组，`call` 函数接收的参数类型是多个参数的列表。

- `apply` 函数的调用方式：`func.apply(thisArg, [argsArray])`
- `call` 函数的调用方式：`func.call(thisArg, arg1, arg2, ...)`

## apply 与 call 的相同点

从上面的两个函数的调用方式，就能得知这两个函数都是 JS 中函数对象原型 (prototype) 的方法。来看一下这两个函数的具体用法：

### apply 函数的用法

这个函数接收两个参数，第一个参数代表需要替换的上下文对象，第二个参数代表调用对象的参数数组。

- 不带参数的函数使用 `apply` ：

  ```
  var name = "lzh";

  var o = {
      name: "eden"
  };

  function printName() {
      console.log(this.name);
  }

  printName(); // log: lzh
  printName.apply(o); // log: eden
  ```

- 多个参数的函数使用 `apply`，将多个参数打包成数组作为第二个参数传入 `apply` 函数：

  ```
  var name = "lzh";

  var o = {
      name: "eden"
  };

  function printHello(greeting, address) {
      console.log(greeting + ": " + this.name + ", Live in: " + address);
  }

  printHello("Hello. My name is", "ShenZhen"); // Hello. My name is: lzh, Live in: ShenZhen
  printHello.apply(o, ["Hello. My name is", "ShenZhen"]); // Hello. My name is: eden, Live in: ShenZhen
  ```

### call 函数的用法

这个函数接收多个参数，参数不限，第一个参数跟 `apply` 函数的第一个参数相同，代表要替换掉的上下文对象，后面的参数都是调用函数的参数。

- 不带参数的函数使用 `call`，这里跟 `apply` 的使用基本上没有区别：

  ```
  var name = "lzh";

  var o = {
      name: "eden"
  };

  function printName() {
      console.log(this.name);
  }

  printName(); // log: lzh
  printName.call(o); // log: eden
  ```

- 多个参数的函数使用 `call`，这里跟 `apply` 有不同，调用函数的参数传入方式，`apply` 函数是利用数组，`call` 函数的参数是需要逐个传入：

  ```
  var name = "lzh";

  var o = {
      name: "eden"
  };

  function printHello(greeting, address) {
      console.log(greeting + ": " + this.name + ", Live in: " + address);
  }

  printHello("Hello. My name is", "ShenZhen"); // Hello. My name is: lzh, Live in: ShenZhen
  printHello.call(o, "Hello. My name is", "ShenZhen"); // Hello. My name is: eden, Live in: ShenZhen
  ```

## apply 与 call 的不同点

其实从上面两个函数的用法就可以看出来，两个函数的作用是相同的，就是改变函数执行的上下文对象，只是在有多个参数函数的用法上有区别。在参数个数不确定的情况下，就使用 `apply` 函数；在参数确定的情况下，使用两个函数都可以。

我们看一个**[面试题][5]**来看一下这两个函数的具体区别。这个面试题的题目是：「定义一个 log 函数，然后它可以代理 `console.log` 的方法」。我们首先想到的是在 log 函数中直接调用 `console.log` 方法，这种方式在只有一个参数的情况下能满足要求，但是有个参数，这个方式就只能打印第一个参数。

```
function log(msg)　{
    console.log(msg);
}

log("lzh"); // lzh
log("lzh", "eden"); // lzh
```

更好的方式是使用 `apply` 函数，将 log 函数的隐藏参数 `arguments` 作为参数传递给 `console.log` 函数。下面代码是实现方式：

```
function log() {
    // 在这里我有将参数列表中的 console 替换成其他对象，结果虽然是正确的
    // 但是最好还是使用 console，因为不知道函数内部究竟有没有使用 console
    console.log.apply(console, arguments);
}

log("lzh", "eden"); // lzh eden
```

这道面试题还有一部分：在每次输出的时候，在每一个 log 消息前添加一个 "(app)" 的前辍。

```
function log() {
    // var args = [].slice.call(arguments);
    var args = Array.prototype.slice.call(arguments); // 这里使用 apply 也是可以的
    args.unshift('(app)');

    console.log.apply(console, args);
};
```

## bind 函数

首先我们来看下面的代码：

```
var o = {
    name: "lzh",
    printName: function() {
        console.log(this.name);
    }
};
o.printName(); // lzh

var name = "eden";
var f = o.printName;
f(); // eden
```

从上面的输出结果就可以看出，将对象 o 的 `printName` 属性赋值给 f，再调用 f，此时输出的结果就不一样了，这是因为当调用 f 函数的时候，会查找。如果我们需要函数的上下文是某个指定的上下文对象，我们就需要使用 `bind` 来对函数进行一些操作。可以利用上面提到的 `apply` ／ `call`  函数，但是这两个函数会立马执行。在本节提到 `bind` 函数会生成新的函数，不会马上执行。

上面的例子可以使用下面的代码来解决，这时 f 函数的上下文对象就是 o 而不是全局对象：

```
var o = {
    name: "lzh",
    printName: function() {
        console.log(this.name);
    }
};
o.printName(); // lzh

var name = "eden";
var f = o.printName.bind(o);
f(); // lzh
```

`bind` 函数的主要作用是创建绑定函数，使得这个函数不管怎么调用始终具有相同的 `this` 值。就像上面的示例代码。

我原来以为 JS 中的函数中的对象都是在执行时才确定的，直到看到这篇文章 **[JavaScript 深入之词法作用域和动态作用域][8]**，才意识到自己原来的理解错了。在 [Function.prototype.bind()][6] 有一段话：

> bind() 最简单的用法是创建一个函数，使这个函数不论怎么调用都有同样的 this 值。JavaScript新手经常犯的一个错误是将一个方法从对象中拿出来，然后再调用，希望方法中的 this 是原来的对象。（比如在回调中传入这个方法）如果不做特殊处理的话，一般会丢失原来的对象。

这样的话并不能直接理解为 JS 函数的上下文对象是在调用时决定的，相反 JS 的作用域是采用静态作用域，函数的作用域是基于函数创建的位置。下面的例子就能证明：

```
// 来自 https://github.com/mqyqingfeng/Blog/issues/3
var value = 1;
function foo() {
    console.log(value);
}

function bar() {
    var value = 2;
    foo();
}
bar(); // 1
```

### 上下文切换导致对象丢失

至于在 Cocos-JS 开发中经常使用的回调会导致上面说的对象的丢失，这种情况跟上面代码中的情况不同，因为这里涉及了函数执行上下文的问题，而不仅仅只是一个变量。在 [JavaScript 深入之执行上下文栈][11] 提到 JS 引擎会创建一个上下文调用栈，每当一个函数执行时，会向这个栈中压入当前上下文。每个上下文都有三个重要的属性，如下图：**变量对象**、**作用域链**和 **this**，只有进入上下文中，这个上下文的变量对象才可以被访问。

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/Contexts.png?raw=true' width=300 alt='JS Contexts.' />
</div>

```
// HTTPService.js
var httpService = (function() {
    var service = {};
    
    service.getData = function(callback) {
        if (callback) {
            callback(data); // 1
        }
    };
    
    return service;
})();

// Test.js
var mainView = cc.Node.extend({
    data_: null,
    onEnter: function() {
        this._super();
        
        var self = this; // 2
        httpService.getData(function(data) {
            // this.data_ = data;
            self.data_ = data;
        });
    }
});
```

假设在 mainView 的 `onEnter` 方法中发送网络请求获取数据，因为网络请求是异步的，所以我们获取数据之后的操作需要以回调的方式实现。这个回调的调用是在 `HTTPService.js` 类中注释 1 那，但是在回调中如果像注释那里那样 `this.data_ = data;` 这样实现会有问题，因为在 `HTTPService.js` 类中，上下文已经切换了，所以 this 值不再是 `Test.js` 中的 this 值，因此会报错，this 获取不到 data_。如果像注释 2 那样写，self 不再依赖上下文，当调用回调时，需要使用 self，会到注释 2 获取，而不是直接取当前上下文的值，这是因为 JS 使用的是静态作用域。当然还可以像下面这样使用 `bind` 来实现，这样回调里面的 this 一直就会是 `Test.js` 中的 this。

```
// Test.js
var mainView = cc.Node.extend({
    data_: null,
    onEnter: function() {
        this._super();
        
        httpService.getData(function(data) {
            this.data_ = data;
        }.bind(this));
    }
});
```

### bind 函数小提示
在[深入浅出妙用 Javascript 中 apply、call、bind][2]这篇博客中还提到，多次使用 `bind` 函数没有效果，看下面的例子：

```
// 来自 http://www.cnblogs.com/sanshi/archive/2009/07/08/1519036.html
var bar = function() {
    console.log(this.x);
};
var foo = { x: 3 };
var sed = { x: 4 };
var func = bar.bind(foo).bind(sed);
func(); // 3

var fiv = { x: 5 };

var func = bar.bind(foo).bind(sed).bind(fiv);
func(); // 3
```

## 总结

关于这三个函数的主要作用就是改变函数的上下文对象，其中 `apply` 和 `call` 函数会立马执行函数，这两个函数的区别就是接收的参数类型不同；而 `bind` 函数会生成新的函数，这在函数的回调非常有用。

关于 JS 的继承，可以参考 [JavaScript 继承详解][7]，这一系列文章对 JS 的继承介绍得很详细。

## 相关链接

* [深入浅出妙用 Javascript 中 apply、call、bind][2]
* [JavaScript 深入之词法作用域和动态作用域][8]
* [JavaScript 深入之执行上下文栈][11]
* [JavaScript 深入之变量对象][12]
* [JavaScript 深入之作用域链][13]
* [Function.prototype.apply()][3]
* [Function.prototype.call()][4]
* [Function.prototype.bind()][6]
* [John Resiq 的继承写法解析][1]
* [JavaScript 继承详解][7]

[1]: http://wiki.jikexueyuan.com/project/cocos2d-x-from-cplusplus-js/john-resiq-inheritance-of-written-resolution.html
[2]: https://www.cnblogs.com/coco1s/p/4833199.html
[3]: https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Function/apply
[4]: https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Function/call
[5]: https://segmentfault.com/a/1190000000375138?page=1#articleHeader1
[6]: https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Function/bind
[7]: http://www.cnblogs.com/sanshi/archive/2009/07/08/1519036.html
[8]: https://github.com/mqyqingfeng/Blog/issues/3
[11]: https://github.com/mqyqingfeng/Blog/issues/4
[12]: https://github.com/mqyqingfeng/Blog/issues/5
[13]: https://github.com/mqyqingfeng/Blog/issues/6

<!-- 参考 -->
[9]: https://www.jianshu.com/p/6280d0f12feb
[10]: https://www.jianshu.com/p/9ecb728c5db9


