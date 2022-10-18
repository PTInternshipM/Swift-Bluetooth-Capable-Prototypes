//
//  CentralDelegateProxy.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2/25/20.
//

import Foundation
import CoreBluetooth

/// 根据职责将 `CBCentralManagerDelegate` 拆分，分别委托给不同的职责类。同时避免 delegate 方法在 framework 作用域以外可访问。
///
/// 设计来自 [BluetoothKit](https://github.com/rhummelmose/BluetoothKit/blob/master/Source/BKCBCentralManagerDelegateProxy.swift)。
final class CentralDelegateProxy: NSObject, CBCentralManagerDelegate {

    weak var stateDelegate: CentralStateDelegate?
    weak var discoveryDelegate: CentralDiscoveryDelegate?
    weak var connectionDelegate: CentralConnectionDelegate?

    // MARK: - State Delegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        InternalAvailability.updateAvailability(Availability(state: central.unifiedState))
        stateDelegate?.centralManagerDidUpdateState(central)
    }
    
    // MARK: - Discovery Delegate
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveryDelegate?.centralManager(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
    
    // MARK: - Connection Delegate

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionDelegate?.centralManager(central, didConnect: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionDelegate?.centralManager(central, didFailToConnect: peripheral, error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionDelegate?.centralManager(central, didDisconnectPeripheral: peripheral, error: error)
    }
    
    // MARK: - Other Not Implemented Delegate
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Not implemented
    }
    
//    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
//    }
}

protocol CentralStateDelegate: AnyObject {
    func centralManagerDidUpdateState(_ central: CBCentralManager)
}

protocol CentralDiscoveryDelegate: AnyObject {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber)
}

protocol CentralConnectionDelegate: AnyObject {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
}
