//
//  LittleBluetoothDeviceList.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 10/10/2022.
//

import Foundation
import LittleBlueTooth
import Combine
import CoreBluetooth

class LittleBluetoothDeviceList: FrameworkDeviceList {

    static var name: String = "LittleBlueTooth"

    @Published var devices: [Device] = []

    var littleBtConf: LittleBluetoothConfiguration
    var littleBt: LittleBlueTooth
    var disposeBag: Set<AnyCancellable> = []
    var devicesMap: [UUID: PeripheralDiscovery] = [:]

    init() {
        littleBtConf = LittleBluetoothConfiguration()
        littleBtConf.centralManagerOptions = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        littleBt = LittleBlueTooth(with: littleBtConf)

        littleBt
                .peripheralStatePublisher
                .sink { (state) in
                    print("Peripheral State: \(state)")
                }
                .store(in: &disposeBag)
    }

    func scan() {
        StartLittleBlueTooth
                .startDiscovery(for: littleBt, withServices: nil)
                .map { (discovery: PeripheralDiscovery) -> Void in
                    self.devicesMap[discovery.id] = discovery

                    self.devices = []
                    self.devicesMap.values.forEach { (v: PeripheralDiscovery) in
                        self.devices.append(v.mapToDevice())
                    }
                }
                .sink(receiveCompletion: { result in
                    print("Result: \(result)")
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        // Handle errors
                        print("Error: \(error)")
                    }
                }, receiveValue: { _ in

                })
                .store(in: &disposeBag)
    }

    func stop() {
        StartLittleBlueTooth.disconnect(for: littleBt)
        disposeBag.removeAll()
    }

    func clear() {
        disposeBag.removeAll()
        devices = []
    }

    deinit {
        disposeBag.removeAll()
    }
}

extension PeripheralDiscovery {
    func mapToDevice() -> Device {
        Device(name: name ?? "Unknown", rssi: rssi)
    }
}
