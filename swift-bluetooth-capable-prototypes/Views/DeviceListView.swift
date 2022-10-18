//
//  DeviceListView.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 10/10/2022.
//

import SwiftUI
import Foundation

struct DeviceListView<T: FrameworkDeviceList>: View where T: FrameworkDeviceList {

    @ObservedObject var frameworkDeviceList: T

    var body: some View {
        VStack {
            List(frameworkDeviceList.devices) { device in
                HStack {
                    Text(device.name)
                    Spacer()
                    Text("\(device.rssi)")
                }
            }
            Spacer()
            StandardButton(action: {
                frameworkDeviceList.scan()
            }, text: "Scan")
            StandardButton(action: {
                frameworkDeviceList.stop()
            }, text: "Stop")
            StandardButton(action: {
                frameworkDeviceList.clear()
            }, text: "Clear")
        }
                .padding()
                .navigationTitle(T.name)
    }
}

//struct DeviceListView_Previews: PreviewProvider {
//    static var previews: some View {
////        DeviceListView(frameworkDeviceList: LittleBluetoothDeviceList())
//    }
//}

struct StandardButton: View {
    var action: () -> Void
    var text: String

    var body: some View {
        Button(action: action) {
            Text(text)
                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .center)
                    .foregroundColor(Color.white)
                    .background(Color.accentColor)
                    .cornerRadius(7)
        }
    }
}
