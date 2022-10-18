//
//  ContentView.swift
//  littlebluetoothprototype
//
//  Created by Timo van der Haar on 06/10/2022.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            VStack {
                List {
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: LittleBluetoothDeviceList())) {
                        Text(LittleBluetoothDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: CombineCoreBluetoothDeviceList())) {
                        Text(CombineCoreBluetoothDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: SwiftyBluetoothDeviceList())) {
                        Text(SwiftyBluetoothDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: RxBluetoothKitDeviceList())) {
                        Text(RxBluetoothKitDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: BluetoothKitDeviceList())) {
                        Text(BluetoothKitDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: RVSBlueThothDeviceList())) {
                        Text(RVSBlueThothDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: SwiftySensorsDeviceList())) {
                        Text(SwiftySensorsDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: BluetoothCentralDeviceList())) {
                        Text(BluetoothCentralDeviceList.name)
                    }
                    NavigationLink(destination: DeviceListView(frameworkDeviceList: CmdBluetoothDeviceList())) {
                        Text(CmdBluetoothDeviceList.name)
                    }
                }
            }
            .padding()
            .navigationTitle("Frameworks")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
