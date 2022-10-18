//
//  ConnectionAttempt.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2/26/20.
//

import Foundation
import CoreBluetooth

/// 保存蓝牙尝试连接的信息，连接成功后会被移除。
final class ConnectionAttempt: NSObject {

    let timer: DispatchTimer
    let peripheral: Peripheral
    let successHandler: CentralManager.ConnectionSuccessBlock
    let failureHandler: CentralManager.ConnectionFailureBlock

    init(peripheral: Peripheral, timer: DispatchTimer, successHandler: @escaping CentralManager.ConnectionSuccessBlock, failureHandler: @escaping CentralManager.ConnectionFailureBlock) {
        self.peripheral = peripheral
        self.timer = timer
        self.successHandler = successHandler
        self.failureHandler = failureHandler
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard object != nil, let castObject = object as? ConnectionAttempt else {
            return false
        }
        return castObject.peripheral == peripheral
    }
}
