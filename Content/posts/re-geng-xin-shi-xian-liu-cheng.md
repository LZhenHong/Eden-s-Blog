---
title: 热更新实现流程
date: 2020-04-03 00:59
tags: Cocos
published: true
---

最近游戏的热更新出了一些问题，导致崩溃率有点上升，并且热更新有些文件没有生效。游戏中用的热更新模块是 Cocos 引擎提供的，就花了点时间去翻了 Cocos 的源码文件 AssetsManagerEx.cpp，了解了 Cocos 引擎处理热更新的流程以及问题，也借此机会思考下热更新的处理逻辑。

<!-- more -->

## Cocos 热更新的 Manifest 文件
在 Cocos 的热更新中有一个重要的 Manifest 文件，检查热更新和下载热更新相关的信息都包含在这个文件中，App 包内有一个本地的 Local Manifest，同时里面有个 "remoteManifestUrl" 字段指向远程的 Remote Manifest，这个 Remote Manifest 当有热更新资源时会更新，Cocos 检查有新的热更新就会下载这个 Remote Manifest，然后判断是否新的热更新，有的话则下载新的热更新文件。随后将 Remote Manifest 缓存成 Cache Manifest。

### Local Manifest
```json
{
  "packageUrl": "http://xxx.com/",
  "remoteManifestUrl": "http://xxx.com/AppUpdate/project?version=1.0.0",
  "remoteVersionUrl": "http://xxx.com/AppUpdate/version?version=1.0.0",
  "version": "1.0.0.0",
  "engineVersion": "Cocos2d-JS v3.16"
}
```
这个一般是 App 包内的 Manifest 文件，这里主要申明的是 Version，热更新资源 CDN 地址， Remote Manifest 地址和 Version Url。

### Remote Manifest
```json
{
    "packageUrl": "http://xxx.com/cdn",
    "remoteManifestUrl": "http://xxx.com/AppUpdate/project?version=1.0.0",
    "remoteVersionUrl": "http://xxx.com/AppUpdate/version?version=1.0.0",
    "version": "1.0.0.2",
    "engineVersion": "Cocos2d-JS v3.16",
    "groupVersions": {
        "1": "1.0.0.1",
        "2": "1.0.0.2"
    },
    "assets": {
        "src_1.0.0.1_f1b1d1040801913b99fd15ed208ed830.zip": {
            "md5": "f1b1d1040801913b99fd15ed208ed830",
            "compressed": true,
            "group": "1"
        },
        "src_1.0.0.2_e3d58ae365a5a1c2fe2220f3c5968c8e.zip": {
            "md5": "e3d58ae365a5a1c2fe2220f3c5968c8e",
            "compressed": true,
            "group": "2"
        }
    },
    "searchPaths": []
}
```
这个是在 1.0.0 版本发过两次热更的 Remote Manifest 文件，主要的是 version 字段、groupVersions 字段和 assets 字段，version 字段表示当前的热更新版本，这个是判断是否有新的热更资源最重要的字段，assets 对应的是热更新的 CDN 资源，下载热更热更新资源要使用到 packageUrl 和 assets 字段的组合。

## Cocos 热更新步骤

1. 加载 App 包内的 Local Manifest，Cocos 会使用这个文件来判断是否有新的热更新资源。在加载 Local Manifest 的同时会尝试去加载 Cache Manifest，如果 Cache Manifest 存在，则会先判断这两个 Manifest 的 Version 字段。如果本地的 Manifest 文件比缓存的 Manifest 的文件 Version 要大或者等于，则删除热更新目录，Cocos 认为 App 的代码比热更新的代码要更新。如果本地的 Manifest 文件比缓存的 Manifest 文件的 Version 要小，则使用 Cache Manifest 去跟 Remote Manifest 做对比。如果没有 Cache Manifest，就继续用 Local Manifest 做对比。
2. 调用 jsb.AssetsManager 的 checkUpdate 方法开始检查是否有新的热更新资源。在检查之前会下载一个 Version Manifest 文件，这个文件主要的字段就是 Version 字段，Cocos 通过这个字段来判断是否有新的热更新资源，如果本地 Manifest 的 Version 比这个 Version Manifest 的 Version 要大或者等于的话，就直接删除临时热更新目录，并直接完成热更新流程。如果本地 Manifest 的 Version 比 Version Manifest 的 Version 要小，就开始下载 Remote Manifest。
3. 下载好 Remote Manifest 之后，开始比较 Remote Manifest 和 Local Manifest 的 Version 字段，Remote Manifest 的 Version 比 Local Manifest 的小或者等于，就直接删除临时热更新目前，完成热更新流程。如果 Remote Manifest 比 Local Manifest 要大，则开始现在热更新资源包。
4. 开始下载热更新的时，Cocos 会检查是否有未完成的热更新包，同时也会检查 MD5 值有变化的热更新包，生成一个下载队列。AssetsManager 中有一个 _maxConcurrentTask 属性来控制同时下载热更新包的数量。
5. 下载好一个热更新包之后，就开始解压 Zip 包，等所有的热更新 Zip 包下载完成后，就将热更新资源从临时路径拷贝到指定的缓存热更新路径。随后通知代理热更新下载完毕。

## Cocos 热更新问题

按照理想的情况，Cocos 的热更新是可以正常运行。但是在游戏上线一段时间后，我们发现 Cocos 的热更新是存在问题的。如果一次性下载多个热更新包，Cocos 不能保证热更新包下载完成的先后顺序，这个就导致了如果两个热更新包包含同一个代码文件，但是新的代码文件比旧的代码文件先下载好，就会导致旧的代码文件将新的代码文件覆盖。这里的解决办法就是将 _maxConcurrentTask 属性设为 1，让 Cocos 每次只下载一个热更新包，这样来保证热更新包下载的顺序。Cocos 热更新组件还是有个问题，就是热更新组件维护热更新包下载顺序用的 **unordered_map**，并且插入热更新包资源用的是 `push_back`，这个就导致虽然热更新包是串行下载的，但是下载的顺序不能保证，解决方案是将维护下载顺序队列的维护成 **map**。

## 热更新的优化

从 Cocos 的热更新系统，我自己也受了一点启发。虽然 Cocos 的热更新系统基本功能都有，但是还是存在一些问题，热更新是没办法回滚的，重发的热更也需要有新热更触发下载才会触发 MD5 值变化的下载，同时下载多个热更新包如何保证顺序，热更新流程的优化可以从这几方面入手。
