//
//  Disposable.swift
//  ObservationLite
//
//  Created by Evan Xie on 2020/7/16.
//

import Foundation

/// 用于销毁资源的对象，类似一个 `token`, 为你提供销毁资源的实例。
public final class Disposable {
    
    let dispose: () -> Void
    
    public init(_ dispose: @escaping () -> Void) {
        self.dispose = dispose
    }
    
    deinit {
        dispose()
    }
    
    /// 交给 `disposeBag` 来销毁
    public func dispose(by disposeBag: DisposeBag) {
        disposeBag.add(self)
    }
}

/// 用来管理所有的 `disposables` 的销毁。
/// 当 DisposeBag 被销毁后，所有的 `disposables` 也会自动被销毁。
public final class DisposeBag {
    
    private var lock: NSRecursiveLock
    private var disposables: [Disposable]
    private var isDisposed = false
    
    public init() {
        lock = NSRecursiveLock()
        disposables = [Disposable]()
    }
    
    deinit {
        dispose()
    }

    /// 添加一个需要销毁的资源
    public func add(_ disposable: Disposable) {
        lock.lock()
        defer { lock.unlock() }
        if isDisposed { return }
        
        disposables.append(disposable)
    }

    private func dispose() {
        let disposables = removeDisposables()
        for disposable in disposables {
            disposable.dispose()
        }
    }

    private func removeDisposables() -> [Disposable] {
        lock.lock()
        defer { lock.unlock() }

        let disposables = self.disposables
        self.disposables.removeAll(keepingCapacity: false)
        self.isDisposed = true
        
        return disposables
    }
}
