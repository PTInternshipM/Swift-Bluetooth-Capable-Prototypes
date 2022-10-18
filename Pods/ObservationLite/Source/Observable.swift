//
//  Observable.swift
//  ObservationLite
//
//  Created by Evan Xie on 2020/7/16.
//

import Foundation

/// 可观察的事件序列, 引用 RxSwift 的概念
open class Observable<Event> {
    
    public typealias Observer = (Event) -> Void
    
    private var uniqueID = (0...).makeIterator()
    private let lock = NSRecursiveLock()
    private var onDispose: () -> Void
    
    fileprivate var observers: [Int: (Observer, DispatchQueue)] = [:]
    
    public init(_ onDispose: @escaping () -> Void = {}) {
        self.onDispose = onDispose
    }
    
    /// 在指定 `DispatchQueue` 订阅事件，并返回可销毁的 `disposable`。
    public func subscribe(observer: @escaping Observer, on queue: DispatchQueue = .main) -> Disposable {
        lock.lock()
        defer { lock.unlock() }
        
        let id = uniqueID.next()!
        observers[id] = (observer, queue)
        
        let disposable = Disposable { [weak self] in
            self?.observers[id] = nil
            self?.onDispose()
        }
        
        return disposable
    }
}

extension Observable {
    
    func notifyObservers(_ event: Event) {
        observers.forEach {
            let observer = $0.value.0
            let queue = $0.value.1
            if isCurrentQueue(queue) {
                observer(event)
            } else {
                queue.async { observer(event) }
            }
        }
    }
    
    private func isCurrentQueue(_ queue: DispatchQueue) -> Bool {
        let key = DispatchSpecificKey<UInt32>()
        queue.setSpecific(key: key, value: arc4random())
        defer { queue.setSpecific(key: key, value: nil) }
        
        return DispatchQueue.getSpecific(key: key) != nil
    }
}
