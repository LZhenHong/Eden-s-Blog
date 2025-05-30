---
title: Unity 热更 ILRuntime 基本原理
date: 2021-03-22 21:56
tags: Unity
published: true
---

> CIL: Common Intermediate Language，通用中间语言
> CLI: Common Language Infrastructure，通用语言基础结构
> JIT: Just-in-Time compilation，即时编译
> AOT: Ahead-of-Time，提前编译或静态编译

对 Unity 有一定的了解应该都知道 Unity 本身是不支持热更新的，但是在各种需求的驱使下，想要完全不用热更新几乎是不可能的，所以就诞生了很多热更新方案。有 tolua、xlua 这些成熟的 lua 解决方案，也有就是完全用 C# 实现的 ILRuntime 方案，因为热更新的代码也是用 C# 实现，没有 lua 的学习成本，现在 ILRuntime 的热更新方案越来越流行。

我们今天就着重介绍一下 ILRuntime 以及它的基本原理。

<!--more-->

## 为何 Unity 不支持热更新

要解释为何 Unity 不支持热更新就要从 Unity 是如何实现跨平台说起。Unity 会先将代码编译成叫做 CIL 的代码指令集，CIL 可以在任何支持 CLI 的环境中运行，Unity 最开始使用的 Mono 运行时来支持 CIL 的运行，现在也可以使用 Unity 自身实现的 IL2CPP 来支持 CIL 的运行，运行时可以将 CIL 指令集转换成平台的本地指令， 所以我们可以在 Unity 用 C# 实现一套代码然后在多平台上运行。

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/ilruntime_cil.png?raw=true' alt='ILRuntime CIL' />
</div>

通过上面的图我们看到整体的流程，首先我们通过 C# 代码编写游戏逻辑，Unity 打包会将 C# 编译成 CIL，然后通过 Mono 运行时运行在原生平台上，这样就实现了游戏的跨平台。

现在我们集中在 Mono 运行时上，我们需要了解一下 Mono 是如何将 CIL 编译成原生平台的机器码，Mono 提供了两种编译方式：JIT 和 AOT，JIT 会在运行才进行编译，AOT 会提前将代码编译好随后直接运行。既然 Mono 提供了 JIT，从技术上的角度来说，是可以进行热更新，为什么 Unity 不支持呢？原因就是 iOS、PS、Xbox 等平台是不允许 JIT 的，Unity 要支持这些平台，即使其他平台可以实现热更新，但是 Unity 官方也没有提供热更新方案。

## 程序域 AppDomain

Unity 在运行期间会默认构建一个程序域 AppDomain，程序域中是可以加载多个程序集 Assembly。例如：Unity 的程序域中会存在 System.dll、UnityEngine.UI.dll 等。

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/ilruntime_appdomain.png?raw=true' alt='ILRuntime AppDomain' />
</div>

Unity 会将未放在 StreamingAssets 路径下的程序集都加载到默认的程序域中，如果将热更新的 DLL 文件放在其他目录下，随后再去加载热更新 DLL，这种方式热更新的 DLL 不会生效，Unity 使用的还是之前的热更新 DLL 文件。如果不考虑不支持 JIT 的平台，其实也可以用利用 C# 动态加载 DLL 来实现热更新。如下所示：

```csharp
string dllPath = "{DLL_Path}";
var dllUri = new Uri(dllPath);
UnityWebRequest webRequest = UnityWebRequest.Get(dllUri);
yield return webRequest.SendWebRequest();
if (webRequest.isNetworkError || webRequest.isHttpError)
{
    Debug.LogError($"Load Hotfix DLL error at path: {dllPath}");
    yield return null;
}
byte[] mDllBytes = webRequest.downloadHandler.data;
webRequest.Dispose();

try {
    Assembly assembly = Assembly.Load(mDllBytes);
    var types = assembly.GetTypes();
    for (var innerType in types)
    {
        if (innerType.Name == "Class_Name")
        {
            var instance = Activator.CreateInstance(innerType);
            MethodInfo method = innerType.GetMethod("Method_Name");
            if (method != null)
            {
                var returnValue = method.Invoke(instance, null);
                Debug.Log("Return value: " + returnValue);
            }
        }
    }
}
catch (Exception exception)
{
    Debug.LogError(exception.Message);
}
```

## ILRuntime

ILRuntime 的使用是需要区分两个 VS 工程，一个是 Unity 生成的主工程，另一个就是生成 DLL 文件的热更工程，ILRuntime 通过解析 DLL 文件实现热更新。

根据 ILRuntime 官网上的介绍："ILRuntime 借助 Mono.Cecil 库来读取 DLL 的 PE 信息，以及当中类型的所有信息，最终得到方法的 IL 汇编码，然后通过内置的 IL 解译执行虚拟机来执行 DLL 中的代码。"

DLL 的内容就是 IL 指令，CIL 类似一个面向对象的组合语言，并且它是完全基于堆栈的，它运行在虚拟机上。从 ILRuntime 官网上的定义可知，ILRuntime 实现了 IL 解释执行虚拟机和自己的 IL 托管栈来模拟代码的执行，在 ILRuntime 解释执行期间，所有的对象都是用 StackObject 表示的，没有新类型的生成，所以不存在运行时编译的情况，由此可以实现热更新的动态加载。

## ILRuntime 使用

### 简单使用

```csharp
ILRuntime.Runtime.Enviorment.AppDomain appdomain;

void Start()
{
    StartCoroutine(LoadILRuntime());
}

IEnumerator LoadILRuntime()
{
    appdomain = new ILRuntime.Runtime.Enviorment.AppDomain();

    var dllUri = new Uri(dllPath);
    UnityWebRequest webRequest = UnityWebRequest.Get(dllUri);
    yield return webRequest.SendWebRequest();

    if (webRequest.isNetworkError || webRequest.isHttpError)
    {
        Debug.LogError($"Load Hotfix DLL error at path: {dllPath}");
        yield return null;
    }
    byte[] dll = webRequest.downloadHandler.data;
    webRequest.Dispose();

    var pdbUri = new Uri(pdbPath);
    webRequest = UnityWebRequest.Get(pdbUri);
    yield return webRequest.SendWebRequest();

    if (webRequest.isNetworkError || webRequest.isHttpError)
    {
        Debug.Log($"Load Hotfix PDB error at path: {pdbPath}");
        yield return null;
    }
    byte[] pdb = webRequest.downloadHandler.data;
    webRequest.Dispose();

    System.IO.MemoryStream fs = new MemoryStream(dll);
    System.IO.MemoryStream p = new MemoryStream(pdb);
    appdomain.LoadAssembly(fs, p, new Mono.Cecil.Pdb.PdbReaderProvider());    

    OnILRuntimeInitialized();
}

void OnILRuntimeInitialized()
{
    appdomain.Invoke("Hotfix.Game", "Initialize", null, null);
}
```

要使用 ILRuntime 首先要创建一个 `ILRuntime.Runtime.Enviorment.AppDomain` 热更新域，通过这个热更新域加载热更新 DLL，随用调用热更新 DLL 的入口。在游戏运行期间，只保留一个热更新域，与热更新 DLL 的交互都需要使用这个 AppDomain。

### CLR 绑定

默认情况下，热更新 DLL 中访问主工程和 Unity 的接口，是通过反射的方式来实现的。通过反射的方式调用接口的效率会比直接调用低很多，同时调用期间会产生很多临时变量，造成额外的 GC Alloc，会引起性能问题。

因为上述原因，ILRuntime 使用 CLR 绑定机制来尽可能规避上述问题。CLR 绑定是借助了 ILRuntime 的 CLR 重定向机制来实现，CLR 重定向的实现原理是 ILRuntime 的 IL 解释器发现需要调用某个方法时，可以将这个方法的调用指定到另一个方法的实现，由此实现方法的挟持。

CLR 重定向方法的编写需要对 ILRuntime 的底层非常了解，并且工作量巨大，因为热更新 DLL 不可避免调用主工程和 Unity 的接口，这样就需要实现很多重定向的方法。幸运的是 ILRuntime 提供了工具来自动生成 CLR 绑定代码。

```csharp
[MenuItem("ILRuntime/Generate CLR Binding Code by Analysis")]
static void GenerateCLRBindingByAnalysis()
{
    // 用新的分析热更 dll 调用引用来生成绑定代码
    ILRuntime.Runtime.Enviorment.AppDomain domain = new ILRuntime.Runtime.Enviorment.AppDomain();
    using (System.IO.FileStream fs = new System.IO.FileStream("{Hotfix_dll_path}", System.IO.FileMode.Open, System.IO.FileAccess.Read))
    {
        domain.LoadAssembly(fs);

        // Crossbind Adapter is needed to generate the correct binding code
        InitILRuntime(domain);
        ILRuntime.Runtime.CLRBinding.BindingCodeGenerator.GenerateBindingCode(domain, "Assets/ILRuntime/Generated");
    }
    AssetDatabase.Refresh();
}

static void InitILRuntime(ILRuntime.Runtime.Enviorment.AppDomain domain)
{
    // 这里需要注册所有热更DLL中用到的跨域继承Adapter，否则无法正确抓取引用
    domain.RegisterCrossBindingAdaptor(new MonoBehaviourAdapter());
    domain.RegisterCrossBindingAdaptor(new CoroutineAdapter());
    domain.RegisterCrossBindingAdaptor(new TestClassBaseAdapter());
    domain.RegisterValueTypeBinder(typeof(Vector3), new Vector3Binder());
}
```

在 CLR 绑定代码生成之后，需要将这些绑定代码注册到 AppDomain 中才能使 CLR 绑定生效，但是一定要记得将 CLR 绑定的注册写在 CLR 重定向的注册后面，因为同一个方法只能被重定向一次，只有先注册的那个才能生效。

### 其他

关于热更新 DLL 与主工程的交互还有委托、跨域继承、反射和 CLR 重定向。更详细的内容可以访问 ILRuntime 的[官方文档][1]。

## ILRuntime 注意点

1. 目前 ILRuntime 在处理逻辑数学计算的时候，效率低于 Lua，本质上是因为一个是 stack 虚拟机，一个是 register 虚拟机。所以尽量把数学计算多的部分转移到框架层。Hotfix 中不要写大量复杂的计算，特别是在 Update 之类的方法中。
2. Xcode 调试会经常出现爆栈，因为 iPhone 的线程栈空间很小，稍微深一点的调用就会出现爆栈，可以将 Xcode 工程调成 Release 模式。
3. 热更代码需要尽量减少 foreach 的使用，由于原理限制，在热更中使用 foreach 无法避免产生 GC Alloc，请使用支持 for 循环的数据结构，或者用 List 等支持 for 遍历的结构辅助 Dictionary 等无法 for 遍历的结构。
4. 关闭 Development Build 选项来发布 Unity 项目。在 Editor 中或者开启 Development Build 选项发布会开启 ILRuntime 的 Debug 框架，以提供调用堆栈行号以及调试服务，这些都会额外耗用不少性能，因此正式发布的时候可以不加载 pdb 文件，以节省更多内存。

## 相关链接
* [ILRuntime 官方文档][1]
* [Unity3D 为何能跨平台？聊聊 CIL (MSIL)][5]
* [谁偷了我的热更新？Mono，JIT，iOS][6]
* [Unity ILRuntime 详解][2]
* [使用 ILRuntime 遇到的一些问题][3]
* [Unity DLL 实现热更新][4]
* [Unity 将来时：IL2CPP 是什么？][7]

[1]: https://ourpalm.github.io/ILRuntime/public/v1/guide/index.html
[2]: https://www.zhihu.com/column/zblade
[3]: https://zhuanlan.zhihu.com/p/260216935
[4]: https://blog.csdn.net/baidu_28955655/article/details/52661698
[5]: https://www.zhihu.com/column/p/20525151
[6]: https://zhuanlan.zhihu.com/p/21328671
[7]: https://zhuanlan.zhihu.com/p/19972689
