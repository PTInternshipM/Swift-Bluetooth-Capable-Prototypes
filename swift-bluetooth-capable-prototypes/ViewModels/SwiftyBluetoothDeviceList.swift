
// Created by Timo van der Haar on 11/10/2022.
//

import Foundation
import SwiftyBluetooth

class SwiftyBluetoothDeviceList: FrameworkDeviceList {

    static var name: String = "SwiftyBluetooth"

    @Published var devices: [Device] = []

    let options: [String: Any] = [
        "CBCentralManagerScanOptionAllowDuplicates": true
    ]
    var devicesMap: [UUID: Device] = [:]

    func scan() {
        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: nil, options: options, timeoutAfter: 15) { scanResult in
            switch scanResult {
            case .scanStarted:
                print("Scan started!")
            case .scanResult(peripheral: let peripheral, advertisementData: _, RSSI: let RSSI):
                print("Peripheral found: \(peripheral.name ?? "Unknown")")
                self.devicesMap[peripheral.identifier] = peripheral.mapToDevice(RSSI)
                self.devices = Array(self.devicesMap.values)
            case .scanStopped(peripherals: _, error: _):
                print("Scan stopped!")
            }
        }
    }

    func stop() {
        SwiftyBluetooth.stopScan()
    }

    func clear() {
        devices = []
        SwiftyBluetooth.stopScan()
    }
}

extension Peripheral {
    func mapToDevice(_ rssi: Int?) -> Device {
        Device(name: name ?? "Unknown", rssi: rssi ?? 0)
    }
}
