//
//  RVSBlueThothDeviceList.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 13/10/2022.
//

import Foundation
import RVS_BlueThoth

class RVSBlueThothDeviceList: FrameworkDeviceList {
    
    static var name: String = "RVS_BlueThoth"
    
    @Published var devices: [Device] = []
    
    var devicesMap: [String: Device] = [:]
    
    var centralManager: RVS_BlueThoth
    
    init() {
        centralManager = RVS_BlueThoth()
        centralManager.delegate = self
        centralManager.allowEmptyNames = true
    }
    
    func scan() {
        centralManager.startScanning(withServices: nil, duplicateFilteringIsOn: false)
    }
    
    func stop() {
        centralManager.stopScanning()
    }
    
    func clear() {
        centralManager.stopScanning()
        devices = []
    }
    
    deinit {
        centralManager.stopScanning()
        devices = []
    }
}

extension RVSBlueThothDeviceList: CGA_BlueThoth_Delegate {
    
    func handleError(_ error: CGA_Errors, from: RVS_BlueThoth) {
        print("hier1")
            
    }
    
    func updateFrom(_ centralManager: RVS_BlueThoth) {
        print("hier2")
        centralManager.stagedBLEPeripherals.forEach { DiscoveryData in
            self.devicesMap[DiscoveryData.identifier] = DiscoveryData.mapToDevice()
            self.devices = Array(self.devicesMap.values)
        }
    }
    
    func centralManagerPoweredOn(_ centralManager: RVS_BlueThoth) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, didConnectThisDevice: CGA_Bluetooth_Peripheral) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, willDisconnectThisDevice: CGA_Bluetooth_Peripheral) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, deviceInfoChanged: CGA_Bluetooth_Peripheral) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, deviceReadyForWrite: CGA_Bluetooth_Peripheral) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, device: CGA_Bluetooth_Peripheral, changedService: CGA_Bluetooth_Service) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, device: CGA_Bluetooth_Peripheral, service: CGA_Bluetooth_Service, characteristicWriteComplete: CGA_Bluetooth_Characteristic) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, device: CGA_Bluetooth_Peripheral, service: CGA_Bluetooth_Service, changedCharacteristicNotificationState: CGA_Bluetooth_Characteristic) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, device: CGA_Bluetooth_Peripheral, service: CGA_Bluetooth_Service, changedCharacteristic: CGA_Bluetooth_Characteristic) {

    }
    
    func centralManager(_ centralManager: RVS_BlueThoth, device: CGA_Bluetooth_Peripheral, service: CGA_Bluetooth_Service, characteristic: CGA_Bluetooth_Characteristic, changedDescriptor: CGA_Bluetooth_Descriptor) {

    }
}

extension RVS_BlueThoth.DiscoveryData {
    func mapToDevice() -> Device {
        Device(name: localName == "" ? "Unknown" : localName, rssi: rssi)
    }
}
