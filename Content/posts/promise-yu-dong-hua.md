---
title: Promise 与动画
date: 2022-07-02 23:45
tags: TypeScript
published: true
---

学习编程语言的过程都是相似的，先介绍语言基础类型、流程控制、函数格式等。编程的过程基本上就是流程的控制，判断状态，执行不同的逻辑，类、对象、方法是行为的封装。我们在刚接触编程会写很多 if-else、switch，为了减少 if-else 和 switch 的使用，会有继承、设计模式的应用。

<!-- more -->

在流程控制中有一种特别的存在，就是异步处理，在我个人的编程生涯很长一段时间里都是以回调或者委托的方式处理。回调的方式可以把逻辑写在一处，同时可以很轻松得到异步处理的上下文，但是多个异步处理的情况就会导致回调地狱。委托的方式则会把回调逻辑分开，上下文需要另外维护。

如何控制好异步处理的逻辑是很重要的，回调方式和委托的方式大部分情况下都不是最优解。现在有更好的 Promise 解决方案，再结合 `async/await` 的语法糖，让我们得以以同步的方式来处理异步逻辑，更好控制异步逻辑的流程。

~~Promise 真的是一学就后悔，后悔学晚了。~~

# Promise 简介

Promise 可以很方便对异步操作进行封装。Promise 提供的链式接口可以很便捷顺序组装、合并组装异步操作。

```typescript
function main() {
    requestData((isSucc, data, error) => {
        if (isSucc) {
            console.log(data);
        } else {
            console.error(error);
        }
    });
}

function requestData(complete: (isSucc: boolean, data?: any, error?: any) => void) {
    sendRequest((data) => {
        complete(true, data)
    }, (error) => {
        complete(false, null, error);
    });
}

function sendRequest(success: (data: any) => void, failure: (error: any) => void) {
    // Send request to server.
    // 伪代码
    if (succ) {
        success(data);
    } else {
        failure(error);
    }
}
```

这里以一个简单的网络请求为例，网络请求是程序开发中最常见的异步操作。这种回调方案是刚接触编程常用的处理方式。这种方式看起来也没有太大的问题，把网络请求的结果处理另外封装成单独的函数，看起来也是很简洁的。但是这样我们在处理多个异步操作时，就会发现我们要理顺异步操作的流程，就需要不停的在回调里跳转。如果不把处理异步处理封装成单独的函数，就会出现回调地狱的情况。

下面来看 Promise 的解决方案。

```typescript
function main() {
    requestDataAsync().then(console.log, console.error);
}

function requestDataAsync(): Promise<any> {
    return new Promise((resolve, reject) => {
        sendRequest((data) => {
            resolve(data);
        }, (error) => {
            reject(error);
        })
    });
}

function sendRequest(success: (data: any) => void, failure: (error: any) => void) {
    ...
}
```

Promise 的解决方案跟异步回调的处理方式貌似没有太大的区别，但是这只是一个异步处理，如果有多个异 Async 函数，Promise 是可以直接在 then 方法里返回下一个异步处理的 Promise ，这样异步处理就可以顺序执行。

在异步处理的流程里，Promise 可以清晰表明每一步异步处理。可以很方便调整异步处理的顺序，也可以快速新增或删除某一个异步处理，这是在回调方式中难以办到的。

# 动画的回调

程序为了给用户更好的体验和表现，会在程序中加入很多动画以优化程序表现和用户体验。动画是不易发现的异步操作，我们经常会在播放动画后，执行某种操作。类似于上面的网络请求例子，当有多个动画执行，如何控制动画的执行顺序和回调的运行时机是动画中非常重要的部分。

我们以两种常见的动画场景举例：

## 多个动画顺序播放，播放完成执行回调

```typescript
function main() {
    let players: Player[] = [p1, p2, p3, p4, p5];
    playAnimations(players, () => {
        console.log('Animation over!');
    });
}

function playAnimations(players: Player[], callback: Function) {
    if (players.length > 0) {
        player = players.shift();
        playerMoveAnimation(player, playAnimations(players, callback));
    } else {
        callback();
    }
}

function playerMoveAnimation(player: Player, callback: Function) {
    player.playMoveAnimation(callback);
}
```

在这种动画情况下，我们在上一次动画执行完的回调里执行下一次回调，举例的还是一样的动画，可以用递归的方式处理。如果每次动画都是不相同的，则很容易导致回调地狱。

## 多个动画同时播放，播放完成执行回调

```typescript
function main() {
    let players: Player[] = [p1, p2, p3, p4, p5];
    let callback = () => {
        console.log('Animation over!');
    };
    players.forEach((player, index) => {
        let func = index == (players.length - 1) ? callback : null;
        playerMoveAnimation(player, func);
    });
}

function playerMoveAnimation(player: Player, callback?: Function) {
    ...
}
```

上述代码在执行回调时，判断是不是最后一个动画，如果是最后一个动画，则把回调传入，否则传入空值。这种还是最简单的情况，我们假设每个动画的时间是一样的。但是如果每个动画的时长不同，如何在动画时长最长的动画播放完成之后执行回调，是需要花一番工夫的，我们需要获取到每次动画的动画时长，然后根据动画时长判断是否需要传入回调。

# 动画的 Promise 实现方式

针对于上面举例的动画案例。我们用 Promise 如何优雅的解决。

## 多个动画顺序播放，播放完成执行回调

```typescript
function main() {
    let players: Player[] = [p1, p2, p3, p4, p5];
    let promise = players.reduce((pre, cur) => pre.then(playerMoveAnimationAsync(cur)), Promise.resolve());
    promise.then(_ => console.log('Animation over!'));
}

function playerMoveAnimationAsync(player: Player) {
    return new Promise(resolve => {    
        player.playMoveAnimation(resolve);
    });
}
```

通过将每个动画转换成 Promise 的形式，然后利用 Promise 的 then 将每个动画 Promise 连接起来，Promise 会在执行完之后再执行 then 方法，这样就实现了动画播放，我们只需要监听最后的 Promise 的 then 方法，执行我们的回调，就实现了动画需求。

相较于普通的回调处理方式，Promise 的方案更为简洁，同时动画的调整也会变得更为便捷。

## 多个动画同时播放，播放完成执行回调

```typescript
function main() {
    let players: Player[] = [p1, p2, p3, p4, p5];
    let promises = players.map(player => playerMoveAnimationAsync(player));
    Promise.resolve().then(_ => Promise.all(promises)).then(_ => console.log('Animation over!'));
}

function playerMoveAnimationAsync(player: Player) {
    ...
}
```

这里通过 `Promise.all` 方法来处理动画 Promise 数组，`Promise.all` 这个方法会在所有的 Promise 执行完成，才会执行 then 方法。

这个方法完美契合我们同时执行动画的需求，而且不用担心每个动画的动画时长不一样，因为这个方法会等待所有 Promise 执行完成，所以会在动画时长最长的动画运行完再执行回调。

# Promise 的注意点

上面的举例都只考虑了 Promise 正常执行的情况，如果 Promise 抛出 reject，如何应对是需要注意的点。如果在每个 Promise 的 then 方法单独处理 reject 回调，会显得很有点繁琐，也可能会出现很多重复代码。如果统一用 catch 处理，又会难以辨别 reject 是哪个 Promise 抛出的。

如果封装的 Promise 只给自己使用，我们可以了解 Promise 内部是如果处理 resolve 和 reject 的。但是封装的 Promise 要提供给他人使用，就需要统一 resolve 和 reject 的处理标准，并且一直遵守，当有统一的共识存在。如何应对 reject 以及针对不同的 reject 恢复程序状态，就会显得很轻松。

# 最后

在程序的世界里，是没有银弹可以解决一切问题，只有针對特定需求的最佳解决方案。所以，多学习了解各种技术，是程序员进阶的必不可少的步骤。

