//
//  SwiftySensorsDeviceList.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 14/10/2022.
//

import Foundation
import SwiftySensors

/// KEEP IN MIND THAT I CHANGED CODE IN THE LIBRARY
/// Bij de SensorManager regel 144 wordt er ook de depracated CBCentralManagerState gebruikt
class SwiftySensorsDeviceList: FrameworkDeviceList {
    
    static var name: String = "SwiftySensors"
    
    @Published var devices: [Device] = []
    
    var devicesMap: [UUID: Device] = [:]
    
    init() {
        
    }
    
    func scan() {
        SensorManager.instance.state = .aggressiveScan
        SensorManager.instance.setServicesToScanFor([])
        SensorManager.logSensorMessage = { message in
            print(message)
        }
        SensorManager.instance.onSensorDiscovered.subscribe(with: self) { [weak self] sensor in
            print("Sensor gevonden AAAAAAAAA")
            self?.devicesMap[sensor.peripheral.identifier] = sensor.mapToDevice()
            if let values = self?.devicesMap.values {
                self?.devices = Array(values)
            }
        }
    }
    
    func stop() {
        SensorManager.instance.state = .off
    }
    
    func clear() {
        SensorManager.instance.state = .off
        devices = []
    }
    
    deinit {
        SensorManager.instance.state = .off
    }
}

extension Sensor {
    func mapToDevice() -> Device {
        peripheral.readRSSI()
        return Device(name: peripheral.name ?? "Unknown", rssi: 0)
    }
}
