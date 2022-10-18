//
//  ErrorLocalizedDescriptions.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2020/5/29.
//

import Foundation

extension CentralManager.ScanError {
    
    public var localizedDescription: String {
        switch self {
        case .bluetoothUnavailable(let reason):
            return "\(reason.debugDescription)，无法扫描"
        case .scanning:
            return "正在扫描中，别急"
        }
    }
}

extension CentralManager.ConnectionError {
    
    public var localizedDescription: String {
        switch self {
        case .bluetoothUnavailable(let reason):
            return "\(reason.debugDescription)，不法连接蓝牙设备"
        case .connecting:
            return "蓝牙设备正在连接中，别急"
        case .alreadyConnected:
            return "蓝牙设备已经连接上啦，不用再连啦"
        case .timeout:
            return "连接蓝牙设备超时"
        case .cancelled:
            return "连接蓝牙设备被取消"
        case .failedWithUnderlyingError(let error):
            return "连接蓝牙失败，遇到内部错误: \(error)"
        }
    }
}
