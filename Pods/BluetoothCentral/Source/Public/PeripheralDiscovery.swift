//
//  PeripheralDiscovery.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2/21/20.
//

import Foundation
import CoreBluetooth

/// 扫描发现的蓝牙设备信息
public struct PeripheralDiscovery: Equatable {
    
    public let advertisementData: [String: Any]
    public let peripheral: Peripheral
    public let rssi: Int
    
    /// 发现蓝牙设备的时间差：当前时间戳减去开始扫描的时间戳.
    /// 也就是指明是在第几秒发现的。
    public let timeOffset: TimeInterval
    
    public var localName: String? {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }
    
    init(advertisementData: [String: Any], peripheral: Peripheral, rssi: NSNumber, timeOffset: TimeInterval) {
        self.advertisementData = advertisementData
        self.peripheral = peripheral
        self.rssi = rssi.intValue
        self.timeOffset = timeOffset
    }

    public static func == (lhs: PeripheralDiscovery, rhs: PeripheralDiscovery) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }
}
