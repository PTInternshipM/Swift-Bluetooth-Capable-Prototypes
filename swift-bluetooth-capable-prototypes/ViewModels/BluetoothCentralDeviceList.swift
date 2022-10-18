//
//  BluetoothCentralDeviceList.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 17/10/2022.
//

import Foundation
import BluetoothCentral
import ObservationLite

class BluetoothCentralDeviceList: FrameworkDeviceList {
    
    static var name: String = "BluetoothCentral"
    
    @Published var devices: [Device] = []
    
    let disposeBag = DisposeBag()
    let centralManager = CentralManager()
    var devicesMap: [UUID: Device] = [:]
    
    init() {
        
    }
    
    func scan() {
        print("Scanning with BluetoothCentral")
        centralManager.availabilityEvent.subscribe { [weak self] Availability in
            print(Availability)
        }
        .dispose(by: disposeBag)
        
        let filter = CentralManager.ScanFilter(serviceUUIDs: []) { discovery -> Bool in
            return true
        }
        centralManager.startScan(withMode: .fixedDuration(15.0), filter: filter, onProgress: { [unowned self] change in
            switch change {
            case let .updated(discovery, _), let .new(discovery):
                print("Updated")
                self.devicesMap[discovery.peripheral.identifier] = discovery.mapToDevice()
                self.devices = Array(self.devicesMap.values)
            }
        }, onCompletion: { [unowned self] discoveries in
                print("Completion")
            }) { [unowned self] error in
                print("Error: \(error)")
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

extension PeripheralDiscovery {
    func mapToDevice() -> Device {
        Device(name: localName ?? "Unknown", rssi: rssi)
    }
}
