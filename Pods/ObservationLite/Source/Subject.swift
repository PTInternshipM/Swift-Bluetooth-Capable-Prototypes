//
//  Subject.swift
//  ObservationLite
//
//  Created by Evan Xie on 2020/7/16.
//

import Foundation

/// 既是事件发布者，又是事件订阅者。
///
/// - Important: 相对 `BehaviorSubject` 来说，只发布事件，但不保存事件。
public class PublishSubject<Event>: Observable<Event> {
    
    /// 转换成可观察的事件序列
    public func asObservable() -> Observable<Event> {
        return self
    }
    
    /// 发布事件
    public func publish(_ event: Event) {
        notifyObservers(event)
    }
}

/// 既是事件发布者，又是事件订阅者。
///
/// - Important: 相对 `PublishSubject` 来说，只发布事件，但会保存最新事件。
public class BehaviorSubject<Event>: PublishSubject<Event> {
    
    private var _event: Event
    
    public var event: Event {
        return _event
    }
    
    public init(event: Event, onDispose: @escaping () -> Void = {}) {
        _event = event
        super.init(onDispose)
    }
    
    /// 发布事件
    public override func publish(_ event: Event) {
        _event = event
        super.publish(_event)
    }
}
