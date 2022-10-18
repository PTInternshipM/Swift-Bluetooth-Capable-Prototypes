//
//  BluetoothKitDeviceList.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 13/10/2022.
//

import Foundation
import BluetoothKit

class BluetoothKitDeviceList: FrameworkDeviceList, BKCentralDelegate, BKAvailabilityObserver {
    func availabilityObserver(_ availabilityObservable: BluetoothKit.BKAvailabilityObservable, availabilityDidChange availability: BluetoothKit.BKAvailability) {
        if availability == .available {
            scan()
        } else {
            central.interruptScan()
        }
    }
    
    func availabilityObserver(_ availabilityObservable: BluetoothKit.BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BluetoothKit.BKUnavailabilityCause) {
        print("hier2")
    }
    
    func central(_ central: BluetoothKit.BKCentral, remotePeripheralDidDisconnect remotePeripheral: BluetoothKit.BKRemotePeripheral) {
        print("hier1")
    }
    
    
    static var name: String = "BluetoothKit"
    
    @Published var devices: [Device] = []
    
    var devicesMap: [UUID: Device] = [:]
    let central = BKCentral()
    
    init() {
    }
    
    func scan() {
//        central.scanWithDuration(15, progressHandler: {newDiscoveries in
//            print("Scanned new peripherals")
//            newDiscoveries.forEach { BKDiscovery in
//                self.devicesMap[BKDiscovery.remotePeripheral.identifier] = BKDiscovery.mapToDevice()
//                self.devices = Array(self.devicesMap.values)
//            }
//        }, completionHandler: {result,error in
//            print("Scanning finished!")
//            print(error)
//        })
        
        do {
            central.delegate = self
            central.addAvailabilityObserver(self)
            let dataServiceUUID = UUID(uuidString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
            let dataServiceCharacteristicUUID = UUID(uuidString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
            let configuration = BKConfiguration(dataServiceUUID: dataServiceUUID, dataServiceCharacteristicUUID: dataServiceCharacteristicUUID)
            try central.startWithConfiguration(configuration)
        } catch let error {
            print("Error while starting: \(error)")
        }
        
    
        central.scanContinuouslyWithChangeHandler({ changes, discoveries in
            // Handle changes to "availabile" discoveries, [BKDiscoveriesChange].
            // Handle current "available" discoveries, [BKDiscovery].
            // This is where you'd ie. update a table view.
            print("Something happened")
            discoveries.forEach { BKDiscovery in
                self.devicesMap[BKDiscovery.remotePeripheral.identifier] = BKDiscovery.mapToDevice()
                self.devices = Array(self.devicesMap.values)
            }
        }, stateHandler: { newState in
            // Handle newState, BKCentral.ContinuousScanState.
            // This is where you'd ie. start/stop an activity indicator.
            switch newState {
                
            case .stopped:
                print("Scanning stopped")
            case .scanning:
                print("Scanning!")
            case .waiting:
                print("Waiting!")
            }
        }, duration: 15, inBetweenDelay: 1, errorHandler: { error in
            // Handle error.
            print(error)
        })
    }
    
    func stop() {
        try? central.stop()
    }
    
    func clear() {
        try? central.stop()
        devices = []
    }
    
    deinit {
        try? central.stop()
    }
}

extension BKDiscovery {
    func mapToDevice() -> Device {
        Device(name: localName ?? "Unknown", rssi: Int(RSSI))
    }
}
