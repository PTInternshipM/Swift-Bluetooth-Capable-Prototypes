//
//  CmdBluetoothDeviceList.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 17/10/2022.
//

import Foundation
import CmdBluetooth

/// KEEP IN MIND THAT I HAD TO CHANGE CODE IN THE PACKAGE FOR IT TO WORK
/// DE CBCentralManagerScanOptionAllowDuplicatesKey STAAT OOK STANDAARD OP FALSE EN KAN NIET AANGEPAST WORDEN
class CmdBluetoothDeviceList: FrameworkDeviceList {
    
    static var name: String = "CmdBluetooth"
    
    @Published var devices: [Device] = []
    
    var devicesMap: [UUID: Device] = [:]
    
    var centralManager: CmdCentralManager
    
    init() {
        centralManager = CmdCentralManager.manager
    }
    
    func scan() {
        centralManager.scanWithServices(nil, duration: 1500) { [weak self] discovery in
            guard let `self` = self else { return }
            
            if let name = discovery.peripheral.name, name.contains("Movesense 202930001338") {
                print("MoveSense gevonden!")
            }
            
            self.devicesMap[discovery.peripheral.identifier] = discovery.mapToDevice()
            self.devices = Array(self.devicesMap.values)
        } completeHandle: {
            print("Completed!")
        }
    }
    
    func stop() {
        centralManager.stopScan()
    }
    
    func clear() {
        centralManager.stopScan()
        devices = []
    }
    
    deinit {
        centralManager.stopScan()
    }
}

extension CmdDiscovery {
    func mapToDevice() -> Device {
        Device(name: peripheral.name ?? "Unknown", rssi: Int(RSSI))
    }
}
