---
title: 反转链表
date: 2016-10-16 22:28
tags: DS
published: true
---

背景：今天百度面试被问到线性链表的反转，~~哈哈哈哈哈~~ 不会，数据结构算法之类的永远是心中的伤痛，自己慢慢想啊想，还是想出了一个比较 low 的解决方法，回到家自己上网搜了一下解决方法，有四种解决方法之多：

<!-- more -->

* 使用数组
* 使用 3 个指针（我想出了这个 😉😉）
* 插入法
* 递归 ~~NBest~~

### 第一种：数组

使用数组比较简单，将单链表储存为数组，然后按照数组的索引逆序进行反转。

这里就不说了。

### 第二种：3 个指针

```c
Node *list = createList();
Node *p, *q, *k;
p = list->next;
q = p->next;
k = q->next;
p->next = NULL; // 将第一个节点的 next 指针置空，代表新链表尾节点
while (k) {
   q->next = p;
   p = q;
   q = k;
   k = k->next;
}
q->next = p; // 最后两个节点，在循环外进行处理
list->next = q; // 将头节点的 next 指针指向新链表的首节点
```
更具体的分析可以看这里给出的链接。 [🔗][1]

### 第三种：插入法

这种方法就是将节点依次插入到头节点后面。

```c
Node *list = createList();
Node *p = list->next;
Node *q;
while (p->next) {
   q = p->next;
   p->next = q->next;
   q->next = list->next;
   list->next = q;
}
```
了解思路加上画一些图，就能写出这些代码。

这里还可以新建另一个头节点，然后将链表的节点逐个插入头节点的后面，这样应该比上面要好实现一点。

### 第四种：递归

递归最难的一步就是将问题抽象出相似的子问题。

我们试想一下一个链表 `A -> B -> C -> D`，要将这个链表反转，我们可以先将 `B -> C -> D` 反转，然后再将 `A` 与三个反转好的链表进行反转，这样就完成链表的反转。要 `B-> C -> D` 反转，我们可以先反转 `C -> D`，然后再将 `B` 与反转好的 `C` 与 `D` 进行反转。这样看来我们就将问题抽象成相识的子问题。

```c
static Node *newFisrtNode = NULL;
Node *reverseLinkList(Node *list) {
    // 只有一个节点，直接返回，并且这里应该是新链表的第一个节点
    if (!list || !list->next) {
        newFisrtNode = list; // 这里是新链表的第一个节点
        return list;
    }
    Node *p = reverseLinkList(list->next);
    p->next = list;
    list->next = NULL;
    return list;
}

int main(int argc, const char * argv[]) {
    Node *list = createList();
    reverseLinkList(list->next);
    
    list->next = newFisrtNode;
    Node *p = list->next;
    while (p) {
        printf("%d -> ", p->value);
        p = p->next;
    }
    return 0;
}
```
这里其实还可以用栈来做，因为递归和栈基本上是可以互换使用的。

### 总结

这些代码中只考虑了一般情况，有一些特殊情况没有处理，例如：链表为空或者只有一个节点等。

通过这次面试也让我认识到了自己的不足：

1. 因为自己的项目经历比较少，所以在 APP 结构的规划和设计存在很大的不足。
2. 对一些知识点了解的不够透彻，只有一些模糊的印象。
3. 一些 ObjC 和 iOS 底层知识点，自己也只是一知半解。
4. Last but not least. 数据结构和算法 😭😭。

By the way，一面与二面的面试官非常'赖斯'，十分感谢他们 🙏🙏。

### 相关链接

* [看图理解单链表的反转][1]

[1]: http://blog.csdn.net/feliciafay/article/details/6841115


