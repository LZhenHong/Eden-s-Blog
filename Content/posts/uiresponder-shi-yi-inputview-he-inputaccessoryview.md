---
title: UIResponder 拾遗：inputView 和 inputAccessoryView
date: 2016-12-08 21:34
tags: iOS
published: true
---

前几天在看响应者链条的时候，看到 `UIResponder` 有两个很有用的属性，但是自己不熟悉，就是 `inputView` 和 `inputAccessoryView`。原来自己练手的时候，需要这样的功能，但是自己不知道这两个属性，导致自己花费了很多时间。所以，就写下这篇，算是对不知道的知识的补充。

<!-- more -->

## UITextField 的 inputView 和 inputAccessoryView

### UITextField 的 inputView

默认情况下，当 `UITextField` 对象成为第一响应者的时候，系统会唤出系统键盘来接收用户的输入。

但是在有些时候，我们不希望唤出系统键盘，而是我们自定义的 view 来接收用户的输入，在这种情况下，`inputView` 就派上用场了。`inputView` 的作用就是让开发者提供自定义的 view 来获取用户的输入，当 `UITextField` 对象成为第一响应者的时候，系统会尝试唤出 `inputView`，如果 `inputView` 存在，就唤出开发者提供的 `inputView`；如果 `inputView` 不存在，也就是说这个属性的值是 nil（`inputView` 默认就是 nil），系统会唤出系统键盘。

现在假设当我们点击 `UITextField` 之后，显示出来的是一个 `UIDatePicker`。大概的实现代码：

```objectivec
@interface ViewController ()
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, strong) UIDatePicker *datePicker;
@end

@implementation ViewController

- (UIDatePicker *)datePicker {
    if (!_datePicker) {
        _datePicker = [[UIDatePicker alloc] init];
        _datePicker.datePickerMode = UIDatePickerModeCountDownTimer;
    }
    return _datePicker;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField.inputView = self.datePicker;
}

@end
```

### UITextField 的 inputAccessoryView 
接下来说一下 `inputAccessoryView` 的作用，这个属性就是在 `inputView` 或者系统键盘上添加一个辅助的 view，例如下图高亮部分（图片截取自奇点）：

<div align=center>
<img src='https://github.com/LZhenHong/BlogImages/blob/master/inputAccessory_Example.png?raw=true' width=200 alt='inputAccessory Example' />
<div align=left>

我们自己来添加一个 `inputAccessoryView`，大概的代码实现：

```objectivec
@interface ViewController () 
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, strong) UIToolbar *toolBar;
@end

@implementation ViewController

- (UIToolbar *)toolBar {
    if (!_toolBar) {
        _toolBar = [[UIToolbar alloc] init];
        _toolBar.bounds = (CGRect){CGPointZero, self.view.bounds.size.width, 49};
        UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:NULL];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(done)];
        _toolBar.items = @[spaceItem, rightItem];
    }
    return _toolBar;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField.inputAccessoryView = self.toolBar;
}

- (void)done {
    NSString *text = [NSString stringWithFormat:@"%.2lf s", self.datePicker.countDownDuration];
    if (self.textField.isFirstResponder) {
        self.textField.text = text;
        [self.textField resignFirstResponder];
    }
}

@end
```

`UITextView` 的自定义 `inputView`／`inputAccessoryView` 与 `UITextField` 类似。

## UIReponder 的 inputView 和 inputAccessoryView

### UIReponder 的 inputView

我们看一下  `inputView` 和 `inputAccessoryView` 在 `UIResponder` 的声明：

```objectivec
// Called and presented when object becomes first responder.  Goes up the responder chain.
@property (nullable, nonatomic, readonly, strong) __kindof UIView *inputView NS_AVAILABLE_IOS(3_2);
@property (nullable, nonatomic, readonly, strong) __kindof UIView *inputAccessoryView NS_AVAILABLE_IOS(3_2);
```

这里我们看到 `UIResponder` 将这两个属性声明为 `readonly`，所以当我们使用例如：`UIButton` 的时候，我们就需要继承这些类，然后重新将这两个属性声明称 `readwrite`。

假设我们点击一个 button 时，要显示一个 `UIDatePicker`，大概的代码实现：

```objectivec
@interface TSButton : UIButton
@property (nonatomic, strong, readwrite, nullable) UIView *inputView;
@property (nonatomic, strong, readwrite, nullable) UIView *inputAccessoryView;
@end

@implementation TSButton
// 1
- (BOOL)canBecomeFirstResponder {
    return YES;
}
// 2
- (BOOL)canResignFirstResponder {
    return YES;
}
@end

@interface ViewController ()
@property (nonatomic, weak) IBOutlet TSButton *showDatePickerButton;
@property (nonatomic, strong) UIDatePicker *datePicker;
@end

@implementation ViewController

- (UIDatePicker *)datePicker {
    if (!_datePicker) {
        _datePicker = [[UIDatePicker alloc] init];
        _datePicker.datePickerMode = UIDatePickerModeCountDownTimer;
    }
    return _datePicker;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.showDatePickerButton.inputView = self.datePicker;
}

- (IBAction)showDatePicker {
     // 3
    [self.showDatePickerButton becomeFirstResponder];
}

@end
```

我们在这里要注意有注释的地方，除却 `UITextField` 和 `UITextView` 之外，因为这两个控件会自动成为第一响应者，其他的 `UIResponder` 子类想要成为第一响应者有两步要做：

1. 覆写 `canBecomeFirstResponder` 并返回 YES；
2. 主动调用 `becomeFirstResponder` 方法。

因为只有成为第一响应者，系统才会去唤出 `inputView` 与 `inputAccessoryView`，所以我们需要主动调用 `becomeFirstResponder` 方法。

## reloadInputViews 用法

当对象是第一响应者时，调用这个方法来刷新 `inputView` 和 `inputAccessoryView`。这些 view 会立马被替换，没有动画。如果对象不是第一响应者，则这个方法就没有任何效果。

## 与 inputView 和 inputAccessoryView 相关的通知

我们有时会监听与系统键盘相关的通知，以便在系统键盘出现的时候，来调整我们的 UI 界面。同样，自定义的 `inputView` 出现或者消失时也会触发键盘相关的通知。我们同样可以监听  `UIKeyboardWillShowNotification`, `UIKeyboardDidShowNotification`, `UIKeyboardWillHideNotification`, 和 `UIKeyboardDidHideNotification` 通知来调整 UI 视图。这里需要注意的是，当有 `inputAccessoryView` 时，通知的 `userInfo` 中的高度数据，是 `inputView` 的高度加上 `inputAccessoryView` 的高度。


## 最后

在 `UIResponder` 还有 `inputViewController` 和 `inputAccessoryViewController` 属性，这两个属性跟自定义键盘有关。下面是它们在 `UIResponder` 中的声明：

```objectivec
// For viewController equivalents of -inputView and -inputAccessoryView
// Called and presented when object becomes first responder.  Goes up the responder chain.
@property (nullable, nonatomic, readonly, strong) UIInputViewController *inputViewController NS_AVAILABLE_IOS(8_0);
@property (nullable, nonatomic, readonly, strong) UIInputViewController *inputAccessoryViewController NS_AVAILABLE_IOS(8_0);
```

## 相关链接

* [Custom Views for Data Input][1]
* [The Responder Chain Is Made Up of Responder Objects][2]

[1]: https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html#//apple_ref/doc/uid/TP40009542-CH12-SW5
[2]: https://developer.apple.com/library/content/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/event_delivery_responder_chain/event_delivery_responder_chain.html#//apple_ref/doc/uid/TP40009541-CH4-SW1
