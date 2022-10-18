//
// Created by Timo van der Haar on 11/10/2022.
//

import Foundation
import RxBluetoothKit
import RxSwift

/// Keep in mind: I had to change code inside the package to make it work
class RxBluetoothKitDeviceList: FrameworkDeviceList {

    static let name: String = "RxBluetoothKit"

    @Published var devices: [Device] = []

    var devicesMap: [UUID: Device] = [:]

    let options = [
        // Does not seem to do anything
        "CBCentralManagerScanOptionAllowDuplicatesKey": true
    ] as [String: AnyObject]

    let centralManager: CentralManager

    var stateDisposable: Disposable? = nil
    var peripheralsDisposable: Disposable? = nil

    init() {
        centralManager = CentralManager(queue: .main, options: options)
    }

    func scan() {
        let startingState: BluetoothState = centralManager.state

        stateDisposable = centralManager
                .observeState()
                .startWith(startingState)
                .filter { $0 == .poweredOn}
                .subscribe { (state: BluetoothState) in
                    print("Powered on!")
                }

        peripheralsDisposable = centralManager
                .scanForPeripherals(withServices: nil)
                .subscribe { (scannedPeripheral: ScannedPeripheral) in
                    
                    if let name = scannedPeripheral.advertisementData.localName, name.contains("TW"){
                        print("MOMENTUM TW")
                              } else {
                            print("Something else")
                        }
                    
                    self.devicesMap[scannedPeripheral.peripheral.identifier] = scannedPeripheral.mapToDevice()
                    self.devices = Array(self.devicesMap.values)
                }
    }

    func stop() {
        stateDisposable?.dispose()
        peripheralsDisposable?.dispose()
    }

    func clear() {
        stateDisposable?.dispose()
        peripheralsDisposable?.dispose()
        devices = []
    }

    deinit {
        stateDisposable?.dispose()
        peripheralsDisposable?.dispose()
    }
}

extension ScannedPeripheral {
    func mapToDevice() -> Device {
        Device(name: advertisementData.localName ?? "Unknown", rssi: Int(truncating: rssi))
    }
}
