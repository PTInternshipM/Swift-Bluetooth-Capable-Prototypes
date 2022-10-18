# ObservationLite
**ObservationLite** 是一个非常轻量级的事件发布与事件观察的 Swift 库，功能也很简单。当你不想引入 *RxSwift* 或其它异步编程的库时，只想实现简单的事件发布与订阅的话，**ObservationLite** 是一个比较好的选择。



## Requirements

- iOS 9.0+ | macOS 10.10+ | tvOS 9.0+ | watchOS 3.0+

- Xcode 11

  

## Integration

#### CocoaPods (iOS 9+)

You can use [CocoaPods](http://cocoapods.org/) to install `ObservationLite` by adding it to your `Podfile`:

```ruby
platform :ios, '9.0'
use_frameworks!
target 'MyApp' do
    pod 'ObservationLite', '1.0.1'
end
```



## 事件发布

事件发布有两个类: *PublishSubject* 和 *BehaviorSubject*。它们的区别：

- *PublishSubject*:   不记录最近发布的事件
- *BehaviorSubject*:  会记录最近发布的一个事件

例如：

```swift
let batteryLevelEventPublisher = BehaviorSubject(event: 0.0)
let chargingEventPublisher = PublishSubject<Bool>()

batteryLevelEventPublisher.publish(0.8)
chargingEventPublisher.publish(true)
```



## 事件监听

```swift
var chargingEvent: Observable<Bool> {
    return  chargingEventPublisher.asObservable()
}
    
var batteryLevelEvent: Observable<Double> {
    return batteryLevelEventPublisher.asObservable()
}

batteryLevelEvent.subscribe { (batteryLevel) in
    // Handle battery level event
}.dispose(by: disposeBag)

chargingEvent.subscribe { (isCharging) in
    // Handle new event
}.dispose(by: disposeBag)
```



## Observer 的释放

当你订阅的时候，*Observer* 其实就是你提供的闭包。那什么时候释放它呢，这里就引入了 *RxSwift* 中的 *DisposeBag*。

订阅的时候，我们会将 *Clousure* 交由 **disposeBag** 去管理。当 **disposeBag** 被释放后，它管理的所有 *disposes*，都会触发销毁动作。