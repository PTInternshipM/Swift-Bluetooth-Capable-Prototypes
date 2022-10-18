//
//  Device.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 10/10/2022.
//

import Foundation

struct Device: Identifiable {

    var id = UUID()

    let name: String
    
    let rssi: Int
}
