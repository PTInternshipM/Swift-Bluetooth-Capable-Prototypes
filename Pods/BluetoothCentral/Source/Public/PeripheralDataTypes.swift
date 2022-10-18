//
//  PeripheralDataTypes.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2020/6/16.
//

import Foundation

extension Peripheral {
    
    /// 蓝牙设备的服务状态，只有在 `ready` 的情况下，才能够收发数据。
    public enum ServiceState {
        case notReady
        case preparing
        case ready
        case error(underlyingError: Swift.Error)
    }
    
    /// 蓝牙设备的连接状态
    public enum ConnectionState: Int {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }
    
    /// 蓝牙设备没有连接的原因
    public enum NotConnectedReason: Int {
        case connecting
        case disconnecting
        case disconnected
        
        init?(_ connectionState: ConnectionState) {
            switch connectionState {
            case .connecting:
                self = NotConnectedReason.connecting
            case .disconnecting:
                self = NotConnectedReason.disconnecting
            case .disconnected:
                self = NotConnectedReason.disconnected
            default:
                return nil
            }
        }
    }
    
    /// 蓝牙设备服务不可用的具体错误
    public enum ServiceError: Swift.Error {
        case bluethoothUnavailable(reason: UnavailabilityReason)
        case peripheralNotConnected(reason: NotConnectedReason)
        case serviceNotStart
        case preparingPeripheralServices
        case notFoundCharacteristic(uuid: String)
        case underlyingError(Error)
    }
}
