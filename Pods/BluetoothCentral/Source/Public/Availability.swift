//
//  Availability.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2/24/20.
//

import Foundation
import CoreBluetooth

/// Bluetooth LE 可用性
public enum Availability: Equatable {

    /// Bluetooth LE 当前可用
    case available
    
    /// Bluetooth LE 当前不可用，及其原因
    case unavailable(reason: UnavailabilityReason)

    init(state: CentralState) {
        switch state {
        case .poweredOn:
            self = .available
        default:
            self = .unavailable(reason: UnavailabilityReason(state: state))
        }
    }
    
    func toUnifiedState() -> CentralState {
        switch self {
        case .available:
            return .poweredOn
        case .unavailable(reason: let reason):
            return reason.toUnifiedState()
        }
    }
    
    public static func == (lhs: Availability, rhs: Availability) -> Bool {
        switch (lhs, rhs) {
            case (.available, .available):
                return true
            case (.unavailable(let lhs), .unavailable(let rhs)):
                return lhs == rhs
            default:
                return false
        }
    }
}


/// Bluetooth LE 不可用的原因。
public enum UnavailabilityReason: CustomDebugStringConvertible {
    
    /// 蓝牙已关闭
    case poweredOff
    
    /// 蓝牙正在重置
    case resetting
    
    /// App 未被授权蓝牙访问
    case unauthorized
    
    /// 此设备上不支持 Bluetooth LE
    case unsupported
    
    /// 未知的临时状态，Core Bluetooth 初始化完成，或重置后，此状态会被更新。
    case unknown

    init(state: CentralState) {
        switch state {
        case .poweredOff:
            self = .poweredOff
        case .resetting:
            self = .resetting
        case .unauthorized:
            self = .unauthorized
        case .unsupported:
            self = .unsupported
        case .unknown:
            self = .unknown
        case .poweredOn:
            fatalError("UnavailabilityReason 不能为poweredOn")
        }
    }

    public var debugDescription: String {
        switch self {
        case .poweredOff:
            return "蓝牙已关闭"
        case .resetting:
            return "系统正在重置蓝牙"
        case .unauthorized:
            return "App 未被授权蓝牙访问"
        case .unsupported:
            return "设备上不支持 Bluetooth LE"
        case .unknown:
            return "未知的临时状态，Core Bluetooth 初始化完成，或重置后，此状态会被更新"
        }
    }
    
    func toUnifiedState() -> CentralState {
        switch self {
        case .poweredOff:
            return .poweredOff
        case .resetting:
            return .resetting
        case .unauthorized:
            return .unauthorized
        case .unsupported:
            return .unsupported
        case .unknown:
            return .unknown
        }
    }
}

