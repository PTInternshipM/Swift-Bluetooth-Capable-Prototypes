//
// Created by Timo van der Haar on 11/10/2022.
//

import Foundation
import CombineCoreBluetooth

class CombineCoreBluetoothDeviceList: FrameworkDeviceList {

    static var name: String = "CombineCoreBluetooth"

    @Published var devices: [Device] = []

    let centralManager: CentralManager = .live()
    var cancellables: Set<AnyCancellable> = []
    var devicesMap: [UUID: PeripheralDiscovery] = [:]

    func scan() {
        let _ = centralManager.scanForPeripherals(withServices: nil, options: CentralManager.ScanOptions(allowDuplicates: true))
                .scan([], { list, discovery -> [PeripheralDiscovery] in
                    if let name = discovery.advertisementData.localName, name.contains("PX") {
                        print("Discovered Bouwers & Wilkins PX")
                    } else {
                        print("Something else")
                    }

                    let innerList = list + [discovery]

                    DispatchQueue.main.async {
                        innerList.forEach { (v: PeripheralDiscovery) in
                            self.devicesMap[v.id] = v
                        }
                        self.devices = []
                        self.devicesMap.values.forEach { (p: PeripheralDiscovery) in
                            self.devices.append(p.mapToDevice())
                        }
                    }


                    return innerList
                })
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] (discoveries: [PeripheralDiscovery]) in

                })
                .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
    }

    func clear() {
        devices = []
        cancellables.removeAll()
    }

    deinit {
        cancellables.removeAll()
    }
}

extension PeripheralDiscovery {
    func mapToDevice() -> Device {
        Device(name: advertisementData.localName ?? "Unknown", rssi: Int(rssi ?? 0))
    }
}
