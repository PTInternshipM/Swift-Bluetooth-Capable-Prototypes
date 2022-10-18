//
//  Scanner.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2/24/20.
//

import Foundation
import CoreBluetooth

final class Scanner {

    // MARK: - Internal Stuff
    
    fileprivate enum State: Int {
        case idle
        case scanning
    }
    
    fileprivate var centralManager: CBCentralManager
    fileprivate var scanningTimer: DispatchTimer?
    fileprivate var discoveries = [PeripheralDiscovery]()

    fileprivate var progressHandler: ((CentralManager.PeripheralDiscoveryChange) -> Void)?
    fileprivate var completionHandler: (([PeripheralDiscovery]) -> Void)?
    
    fileprivate let lock = MutexLock()
    fileprivate var startTimestamp: TimeInterval = 0
    
    fileprivate var _state = State.idle
    fileprivate var state: State {
        lock.lock()
        let state = _state
        lock.unlock()
        return state
    }
    
    // MARK: - Accessible Within Framework
    
    var scanFilter = CentralManager.ScanFilter()
    
    init(manager: CBCentralManager) {
        self.centralManager = manager
    }
    
    /// Throw `CentralManager.ScanError`
    func startScan(withMode mode: CentralManager.ScanMode, filter: CentralManager.ScanFilter, onProgress: ((CentralManager.PeripheralDiscoveryChange) -> Void)?, onCompletion: @escaping ([PeripheralDiscovery]) -> Void) throws {
        do {
            try transitionToScanningState()
            scanFilter = filter
            progressHandler = onProgress
            completionHandler = onCompletion
            
            startTimestamp = CFAbsoluteTimeGetCurrent()
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey: filter.isUpdateDuplicatesEnabled]
            centralManager.scanForPeripherals(withServices: filter.serviceUUIDs, options: options)
            processWorkingMode(mode)
        } catch let error {
            throw error
        }
    }

    func stop() {
        guard state == .scanning else { return }
        endScan()
    }

}

fileprivate extension Scanner {
    
    // MARK: - Private Functions
    
    func processWorkingMode(_ mode: CentralManager.ScanMode) {
        switch mode {
        case .infinitely:
            return
        case .fixedDuration(let duration):
            guard duration > 0.001 else { return }
            startScanningTimer(duration)
        }
    }
    
    /// 开始扫描计时，扫描时间到，就停止扫描。
    func startScanningTimer(_ duration: TimeInterval) {
        guard duration > 0 else { return }
        
        scanningTimer = DispatchTimer()
        scanningTimer?.schedule(withTimeInterval: duration, repeats: false, handler: { [weak self] (_) in
            self?.endScan()
        })
    }
    
    @objc func endScan() {
        invalidateScanningTimer()
        centralManager.stopScan()
        
        let discoveries = self.discoveries
        self.discoveries.removeAll()
        _state = .idle
        
        runTaskOnMainThread { [weak self] in
            self?.completionHandler?(discoveries)
        }
    }
    
    func invalidateScanningTimer() {
        if let timer = scanningTimer {
            timer.invalidate()
            scanningTimer = nil
        }
    }
    
    func transitionToScanningState() throws {
        guard state == .idle else {
            throw CentralManager.ScanError.scanning
        }
        
        let centralState = centralManager.unifiedState
        guard centralState == .poweredOn else {
            throw CentralManager.ScanError.bluetoothUnavailable(UnavailabilityReason(state: centralState))
        }
        
        _state = .scanning
    }
}

extension Scanner: CentralDiscoveryDelegate {
    
    // MARK: - CentralPeripheralDiscoveryDelegate Implementation
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        
        guard state == .scanning else { return }
        
        let discoveryTimestamp = CFAbsoluteTimeGetCurrent()
        let aPeripheral = Peripheral(peripheral: peripheral)
        let discovery = PeripheralDiscovery(
            advertisementData: advertisementData,
            peripheral: aPeripheral,
            rssi: rssi,
            timeOffset: discoveryTimestamp - startTimestamp
        )
        if let filter = scanFilter.customFilter, !filter(discovery) {
            return
        }
        
        // 如果扫描暂存数组中包含了已发现的蓝牙设备，则更新已有蓝牙设备信息。反之，则添加一个新记录。
        if let existIndex = discoveries.firstIndex(of: discovery) {
            discoveries[existIndex] = discovery
            runTaskOnMainThread { [weak self] in
                self?.progressHandler?(.updated(discovery, existIndex))
            }
        } else {
            discoveries.append(discovery)
            runTaskOnMainThread { [weak self] in
                self?.progressHandler?(.new(discovery))
            }
        }
    }
}
