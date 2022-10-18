//
//  Helper.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2020/5/28.
//

import Foundation

enum InternalError: Error {
    case unknown
}

func runTaskOnMainThread(_ taskBlock: @escaping () -> Void) {
    if Thread.isMainThread {
        taskBlock()
    } else {
        DispatchQueue.main.async { taskBlock() }
    }
}
