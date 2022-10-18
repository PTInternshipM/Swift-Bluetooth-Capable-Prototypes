//
//  Framework.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 10/10/2022.
//

import Foundation

protocol FrameworkDeviceList : ObservableObject, Identifiable {
    
    static var name: String { get }
    
    var devices: [Device] { get }
    
    func scan()
    
    func stop()

    func clear()
}
//
//extension FrameworkDeviceList {
//    static var name: String {
//        get { "\(UUID())" }
//    }
//
//    var devices: [Device] {
//        get { [] }
//        set { }
//    }
//
//    var scanning: Bool {
//        get { false }
//        set { }
//    }
//
//    func scan() {
//        scanning = true
//    }
//
//    func stop() {
//        scanning = false
//    }
//
//    func clear() {
//        devices = []
//    }
//}
