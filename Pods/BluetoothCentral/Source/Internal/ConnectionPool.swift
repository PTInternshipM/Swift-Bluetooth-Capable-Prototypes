//
//  ConnectionPool.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2/26/20.
//

import Foundation
import CoreBluetooth

protocol ConnectionPoolDelegate: class {
    func connectionPool(_ connectionPool: ConnectionPool, peripheralDidDisconnect peripheral: Peripheral)
}

/// 负责蓝牙连接集中管理，
/// 设计来自 [BluetoothKit](https://github.com/rhummelmose/BluetoothKit/blob/master/Source/BKConnectionPool.swift)。
final class ConnectionPool {
    
    fileprivate var manager: CBCentralManager
    fileprivate var _connectionAttempts = [ConnectionAttempt]()
    fileprivate var _connectedPeripherals = [Peripheral]()
    
    var connectedPeripherals: [Peripheral] {
        return _connectedPeripherals
    }
    
    weak var delegate: ConnectionPoolDelegate?

    init(manager: CBCentralManager) {
        self.manager = manager
    }

    func connectWithTimeout(_ timeout: TimeInterval, peripheral: Peripheral, onSuccess: @escaping CentralManager.ConnectionSuccessBlock, onFailure: @escaping CentralManager.ConnectionFailureBlock) {
        
        guard !existsInConnectedPeripherals(peripheral) else {
            triggerFailure(.alreadyConnected, for: peripheral, failureBlock: onFailure)
            return
        }
        guard !existsInConnectionAttempts(peripheral) else {
            triggerFailure(.connecting, for: peripheral, failureBlock: onFailure)
            return
        }
        
        let centralState = manager.unifiedState
        guard centralState == .poweredOn else {
            triggerFailure(.bluetoothUnavailable(UnavailabilityReason(state: centralState)), for: peripheral, failureBlock: onFailure)
            return
        }
        
        let timer = DispatchTimer()
        timer.schedule(withTimeInterval: timeout, repeats: false) { [weak self] (_) in
            guard let `self` = self else { return }
            guard let attempt = self.removeConnectionAttempt(by: timer) else { return }
            self.failConnectionAttempt(attempt, error: .timeout)
        }
        
        let connectionAttempt = ConnectionAttempt(peripheral: peripheral, timer: timer, successHandler: onSuccess, failureHandler: onFailure)
        _connectionAttempts.append(connectionAttempt)
        manager.connect(peripheral.peripheral, options: nil)
    }
    
    func disconnectPeripheral(_ peripheral: Peripheral) -> Bool {
        guard existsInConnectedPeripherals(peripheral) else {
            return false
        }
        manager.cancelPeripheralConnection(peripheral.peripheral)
        return true
    }

    func reset() {
        cancelConnectionAttemps()
        resetConnectedPeripherals()
    }
}

fileprivate extension ConnectionPool {
    
    func triggerFailure(_ error: CentralManager.ConnectionError, for peripheral: Peripheral, failureBlock: @escaping CentralManager.ConnectionFailureBlock) {
        runTaskOnMainThread { failureBlock(peripheral, error) }
    }
    
    func triggerSuccess(for peripheral: Peripheral, successBlock: @escaping CentralManager.ConnectionSuccessBlock) {
        runTaskOnMainThread { successBlock(peripheral) }
    }
    
    // MARK: - Connection Peripherals Operations
    
    func existsInConnectedPeripherals(_ peripheral: Peripheral) -> Bool {
        return _connectedPeripherals.contains(peripheral)
    }
    
    func connectedPeripheral(by peripheral: CBPeripheral) -> Peripheral? {
        return _connectedPeripherals.filter({ $0.peripheral.identifier == peripheral.identifier }).first
    }
    
    func removeConnectedPeripheral(_ peripheral: Peripheral) {
        if let index = _connectedPeripherals.firstIndex(of: peripheral) {
            _connectedPeripherals.remove(at: index)
        }
    }
    
    // MARK: - Connection Attempts Operations
    
    func existsInConnectionAttempts(_ peripheral: Peripheral) -> Bool {
        return _connectionAttempts.filter({ $0.peripheral == peripheral }).first != nil
    }
    
    func connectionAttempt(by peripheral: CBPeripheral) -> ConnectionAttempt? {
        let attempts = _connectionAttempts
        return attempts.filter({ $0.peripheral.identifier == peripheral.identifier }).first
    }

    func connectionAttempt(by timer: DispatchTimer) -> ConnectionAttempt? {
        let attempts = _connectionAttempts
        return attempts.filter({ $0.timer === timer }).first
    }
    
    @discardableResult
    func removeConnectionAttempt(by timer: DispatchTimer) -> ConnectionAttempt? {
        if let index = _connectionAttempts.firstIndex(where: { $0.timer === timer }) {
            return _connectionAttempts.remove(at: index)
        }
        return nil
    }

    func failConnectionAttempt(_ connectionAttempt: ConnectionAttempt, error: CentralManager.ConnectionError) {
        connectionAttempt.timer.invalidate()
        manager.cancelPeripheralConnection(connectionAttempt.peripheral.peripheral)
        triggerFailure(error, for: connectionAttempt.peripheral, failureBlock: connectionAttempt.failureHandler)
    }

    func cancelConnectionAttemps() {
        for attempt in _connectionAttempts {
            failConnectionAttempt(attempt, error: CentralManager.ConnectionError.cancelled)
        }
        _connectionAttempts.removeAll()
    }
    
    func resetConnectedPeripherals() {
        for peripheral in _connectedPeripherals {
            delegate?.connectionPool(self, peripheralDidDisconnect: peripheral)
        }
        _connectedPeripherals.removeAll()
    }
}

// MARK: CentralConnectionDelegate Implementation

extension ConnectionPool: CentralConnectionDelegate {
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let index = _connectionAttempts.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            return
        }
        let attempt = _connectionAttempts[index]
        attempt.timer.invalidate()
        _connectionAttempts.remove(at: index)
        _connectedPeripherals.append(attempt.peripheral)
        triggerSuccess(for: attempt.peripheral, successBlock: attempt.successHandler)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Swift.Error?) {
        guard let index = _connectionAttempts.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            return
        }
        
        let attempt = _connectionAttempts.remove(at: index)
        if error != nil {
            failConnectionAttempt(attempt, error: .failedWithUnderlyingError(error!))
        } else {
            failConnectionAttempt(attempt, error: .failedWithUnderlyingError(InternalError.unknown))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        guard let index = _connectedPeripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else { return }
        let connected = _connectedPeripherals.remove(at: index)
        delegate?.connectionPool(self, peripheralDidDisconnect: connected)
    }
}
