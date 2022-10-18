# BluetoothCetral
Swift 实现的主设备端的蓝牙通信框架， 支持 扫描、连接管理以及与从设备间的通信。



## Requirements

- iOS 9.0+ | macOS 10.13+ | tvOS 10.0+ | watchOS 3.0+

- Xcode 11

  

## Integration

#### CocoaPods (iOS 9.0+)

You can use [CocoaPods](http://cocoapods.org/) to install `BluetoothCetral` by adding it to your `Podfile`:

```ruby
platform :ios, '9.0'
use_frameworks!
target 'MyApp' do
    pod 'BluetoothCetral', '1.0.0'
end
```



## CentralManager

负责蓝牙设备的扫描、连接管理，以及系统蓝牙授权信息的状态更新。蓝牙操作都是在内部线程中进行，但 `delegate` 都会在主线程中进行。

### 创建及事件监听

```swift
import UIKit
import CoreBluetooth
import BluetoothCentral

class ScanViewController: UITableViewController {
    fileprivate let disposeBag = DisposeBag()
    fileprivate var manager: CentralManager!
    fileprivate var discoveries = [PeripheralDiscovery]()

    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CentralManager()
     	  listenerEvents()
    }
  
  	private func listenerEvents() {
        manager.availabilityEvent.subscribe { [weak self] (availability) in
						// 处理蓝牙状态变化事件
            switch availability {
            case .available:
                // 蓝牙可用
            case .unavailable(reason: let reason):
                // 蓝牙不可用
            }
        }.dispose(by: disposeBag)
        
        manager.peripheralDisconnectEvent.subscribe { [weak self] (peripheral) in
            // 处理蓝牙设备断开
        }.dispose(by: disposeBag)
    }
}
```



### 扫描

扫描可以指定 `filter` 为可选的，filter 可以指定扫描特定的 service uuids, 扫描特定的设备名。

```swift
fileprivate func startScan() {
    let filter = CentralManager.ScanFilter(serviceUUIDs: []) { (discovery) -> Bool in
        guard  discovery.localName != nil else { return false }
        return true
    }
    manager.startScan(withMode: .fixedDuration(5.0), filter: filter, onProgress: { [unowned self] (change) in
        switch change {
        case let .updated(discovery, index):
            self.discoveries[index] = discovery
            self.tableView.reloadRows(at: [IndexPath(item: index, section: 0)], with: .none)
        case let .new(discovery):
          	let insertIndex = IndexPath(item: self.discoveries.count - 1, section: 0)
            self.discoveries.append(discovery)
            self.tableView.insertRows(at: [insertIndex], with: .right)
        }
    }, onCompletion: { [unowned self] (discoveries) in
			 // 扫描完成
    }) { [unowned self] (error) in
       // 扫描出错
    }
}
```

停止扫描

```swift
func stopScan() {
    manager.stopScan()
}
```



### 连接

*CentralManager* 支持多连接，已连接上的设备可以通过 *CentralManager* 的 `connectedPeripherals` 来获取。通过调用 `disconnectPeripheral` 来断开连接。 

```swift
manager.connect(withTimeout: 3.0, peripheral: peripheral, onSuccess: { (connectedPeripheral) in
	 // 连接成功
}, onFailure: { (peripheral, error) in
	 // 连接出错
})
```



## 与蓝牙从设备通信

当蓝牙设备连接成功后，我们就得到了 `Peripheral` 对象，通过它，我们就可以完成蓝牙服务的准备和数据通信了。

### 蓝牙服务准备

准备蓝牙服务可以指定你感兴趣的服务，或者默认将蓝牙设备拥有的所有服务都准备好。建议只开启需要的服务，这样可以节省蓝牙设备的资源。

```swift
peripheral.prepareServicesToReady(successHandler: { (serviceInfoMap) in
	// 蓝牙服务准备就绪，接下来就可以直接通信了.
  // serviceInfoMap 为找到的蓝牙服务，一般不用关心
}) { (error) in
 	// 蓝牙服务准备失败，建议断开蓝牙或再次尝试
}
```

### 给蓝牙设备发送数据

将数据发送到指定的 `characteristic`，*Peripheral* 支持任意长度的数据，数据长度太大的话，会自动分包传送。

```
let packetData: Data = ... 
do {
    try peripheral.writeData(packetData, toCharacteristic: characteristicUUID)
} catch {
    print(error)
}
```

### 接收蓝牙设备的数据

接收数据需要实现 `PeripheralReceiveDataDelegate`，然后通过 `characteristicUUID` 来区分是哪个 *Characteristic* 传过来的数据。

```swift
final class BluetoothInteractor: PeripheralReceiveDataDelegate {

 	func peripheralDidRecevieCharacteristicData(_ peripheral: Peripheral, data: Data, characteristicUUID: String) {
			// 收到 Periphera 发送过来的数据。接下来可以组包，解析数据等.
	}
}
```

