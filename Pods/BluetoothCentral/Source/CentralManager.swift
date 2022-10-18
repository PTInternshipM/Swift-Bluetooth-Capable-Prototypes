//
//  CentralManager.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2/24/20.
//

import Foundation
import CoreBluetooth
import ObservationLite

// MARK: - Object Lifecycle

public final class CentralManager: NSObject {
    
    fileprivate let queue: DispatchQueue
    fileprivate var manager: CBCentralManager
    fileprivate var scanner: Scanner
    fileprivate var connectionPool: ConnectionPool
    fileprivate var delegateProxy: CentralDelegateProxy
    
    fileprivate var _availabilityEvent = PublishSubject<Availability>()
    fileprivate var _disconnectEvent = PublishSubject<Peripheral>()
    
    /// 系统蓝牙的可用状态
    public var availability: Availability {
        return Availability(state: manager.unifiedState)
    }
    
    /// 系统蓝牙可用状态事件
    public var availabilityEvent: Observable<Availability> {
        return _availabilityEvent.asObservable()
    }
    
    /// 蓝牙设备断开事件
    public var peripheralDisconnectEvent: Observable<Peripheral> {
        return _disconnectEvent.asObservable()
    }
    
    public override init() {
        queue = DispatchQueue(label: "queue.framework.BluetoothCentral")
        delegateProxy = CentralDelegateProxy()
        manager = CBCentralManager(delegate: nil, queue: queue, options: nil)
        scanner = Scanner(manager: manager)
        connectionPool = ConnectionPool(manager: manager)
        super.init()
        
        connectionPool.delegate = self
        delegateProxy.stateDelegate = self
        delegateProxy.discoveryDelegate = scanner
        delegateProxy.connectionDelegate = connectionPool
        manager.delegate = delegateProxy
    }
    
}

// MARK: - 蓝牙设备获取

public extension CentralManager {
    
    /// App 已连接上的所有蓝牙设备
    var connectedPeripherals: [Peripheral] {
        return connectionPool.connectedPeripherals
    }
    
    /// 通过蓝牙设备的标识符 UUID 来获取蓝牙设备
    func retrievePeripheral(withIdentifier identifier: UUID) -> Peripheral? {
        return retrievePeripherals(withIdentifiers: [identifier]).first
    }
    
    /// 通过多个蓝牙设备的标识符 UUIDs 来获取多个蓝牙设备。如果获取不到，返回空数据
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        let peripherals = manager.retrievePeripherals(withIdentifiers: identifiers)
        return mapPeripherals(peripherals)
    }
    
    /// 通过 service uuids 来获取系统已连上的所有蓝牙设备，包括 其它 app 已连接上的蓝牙设备
    func retrieveConnectedPeripherals(withServiceUUIDs uuidStrings: [String]) -> [Peripheral] {
        let uuids = uuidStrings.map { CBUUID(string: $0) }
        let peripherals = manager.retrieveConnectedPeripherals(withServices: uuids)
        return mapPeripherals(peripherals)
    }
    
    private func mapPeripherals(_ peripherals: [CBPeripheral]) -> [Peripheral] {
        var mapped = [Peripheral]()
        for peripheral in peripherals {
            if let cp = connectedPeripherals.filter( { $0.peripheral.identifier == peripheral.identifier }).first {
                mapped.append(cp)
            } else {
                let newPeripheral = Peripheral(peripheral: peripheral)
                newPeripheral._manager = self
                mapped.append(newPeripheral)
            }
        }
        return mapped
    }
}

// MARK: - 蓝牙设备扫描

public extension CentralManager {
    
    /// 扫描蓝牙可能遇到的错误
    /// - bluetoothUnavailable 蓝牙不可用，原因见 `UnavailabilityReason`
    /// - scanning 正在扫描中
    enum ScanError: Swift.Error {
        case bluetoothUnavailable(UnavailabilityReason)
        case scanning
    }
    
    /// 扫描模式，一直扫描或固定时间扫描
    enum ScanMode {
        case infinitely
        case fixedDuration(TimeInterval)
    }
    
    /// 扫描蓝牙设备过滤器
    struct ScanFilter {
        
        public typealias CustomFilterHandler = (PeripheralDiscovery) -> Bool
        
        /// 只扫描包含指定 service uuids 的蓝牙设备，默认为空(全部扫描).
        public let serviceUUIDs: [CBUUID]
        
        /// 是否更新重复的蓝牙设备，默认为 `false` (不更新).
        ///
        /// 开启后，同一个蓝牙设备可能会广播多次；关闭后，Core Bluetooth 会将多个广播信息合成一个再发出来，
        /// [详细请看这里](https://stackoverflow.com/questions/11557500/corebluetooth-central-manager-callback-diddiscoverperipheral-twice)。
        public var isUpdateDuplicatesEnabled: Bool
        
        /// 如果以上过滤条件不能满足，你可以实现自己的过滤逻辑。
        public var customFilter: CustomFilterHandler?
        
        public init(serviceUUIDs: [String] = [], isUpdateDuplicatesEnabled: Bool = false, customFilter: CustomFilterHandler? = nil) {
            self.serviceUUIDs = serviceUUIDs.map { CBUUID(string: $0) }
            self.isUpdateDuplicatesEnabled = isUpdateDuplicatesEnabled
            self.customFilter = customFilter
        }
    }
    
    /// 扫描到的蓝牙设备变化
    ///
    /// - updated(PeripheralDiscovery, Int): 已更新的 `PeripheralDiscovery` 及它的索引，可用于 table view reload row.
    /// - new(PeripheralDiscovery): 发现新的蓝牙设备.
    enum PeripheralDiscoveryChange {
        case updated(PeripheralDiscovery, Int)
        case new(PeripheralDiscovery)
        
        /// 发现蓝牙设备的时间差：当前时间戳减去开始扫描的时间戳.
        /// 也就是指明是在第几秒发现的。
        public var timeOffset: TimeInterval {
            switch self {
            case let .updated(discovery, _),
                 let .new(discovery):
                
                return discovery.timeOffset
            }
        }
        
        public var discovery: PeripheralDiscovery {
            switch self {
            case let .updated(aDiscovery, _):
                return aDiscovery
            case let .new(aDiscovery):
                return aDiscovery
            }
        }
    }
    
    /// 开始扫描蓝牙设备
    /// - Parameters:
    ///   - mode: 扫描模式，见 `ScanMode`
    ///   - filter: 扫描过滤条件，默认为扫描所有蓝牙设备。
    ///   - onProgress: 扫描进度，当发现新的蓝牙设备或已发现的蓝牙设备发生变化时，就会被调用。
    ///   - onCompletion: 扫描完成，返回本次扫描过程中所有发现的蓝牙设备。扫描时间到了，或主动调用 `stopScan`，都会触发这个回调。
    ///   - onError: 扫描出现错误时触发，返回 `ScanError`。
    func startScan(withMode mode: ScanMode, filter: ScanFilter? = nil, onProgress: ((_ change: PeripheralDiscoveryChange) -> Void)? = nil, onCompletion: @escaping ([PeripheralDiscovery]) -> Void, onError: ((ScanError) -> Void)? = nil) {
        do {
            let filter = filter ?? ScanFilter()
            try scanner.startScan(withMode: mode, filter: filter, onProgress: { [weak self] (change) in
                
                guard let `self` = self else { return }
                change.discovery.peripheral._manager = self
                onProgress?(change)
                
            }, onCompletion: onCompletion)
            
        } catch {
            onError?(error as! ScanError)
        }
    }
    
    /// 停止扫描，如果没有在扫描，调用它也没关系。
    func stopScan() {
        scanner.stop()
    }
}

// MARK: - 蓝牙设备连接

public extension CentralManager {
    
    typealias ConnectionSuccessBlock = (Peripheral) -> Void
    typealias ConnectionFailureBlock = (Peripheral, ConnectionError) -> Void
    
    /// 扫描蓝牙可能遇到的错误
    /// - bluetoothUnavailable 蓝牙不可用，原因见 `UnavailabilityReason`
    /// - connecting 正在连接中(正在连接蓝牙设备过程中，又再次连接此蓝牙设备会触发此错误)
    /// - alreadyConnected 已经连接上了(蓝牙设备已连上，又发起连接此蓝牙设备时会触发此错误)
    /// - timeout 连接蓝牙设备超时
    /// - cancelled 蓝牙设备蓝牙被取消(比如正在连接过程中，系统蓝牙被关了)
    /// - underlyingError 蓝牙连接底层错误
    enum ConnectionError: Swift.Error {
        case bluetoothUnavailable(UnavailabilityReason)
        case connecting
        case alreadyConnected
        case timeout
        case cancelled
        case failedWithUnderlyingError(Swift.Error)
    }
    
    /// 连接蓝牙设备
    /// - Parameters:
    ///   - timeout: 给定时间过去了，连接超时
    ///   - peripheral: 需要连接的蓝牙设备
    ///   - onSuccess: 连接成功后触发
    ///   - onFailure: 连接过程中遇到错误时触发，详细错误见 `ConnectionError`
    func connect(withTimeout timeout: TimeInterval = 5, peripheral: Peripheral, onSuccess: @escaping ConnectionSuccessBlock, onFailure: @escaping ConnectionFailureBlock) {
        peripheral._manager = self
        connectionPool.connectWithTimeout(timeout, peripheral: peripheral, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /// 断开蓝牙设备连接。如果返回 `false`，说明本来就没有与给定蓝牙设备连接。
    @discardableResult
    func disconnectPeripheral(_ peripheral: Peripheral) -> Bool {
        return connectionPool.disconnectPeripheral(peripheral)
    }
}

// MARK: - Handle CentralManager State

extension CentralManager: CentralStateDelegate {
    
    func triggerAvailabilityUpdate(_ availability: Availability) {
        runTaskOnMainThread { [weak self] in
            guard let `self` = self else { return }
            self._availabilityEvent.publish(availability)
        }
    }
    
    func triggerDisconnect(for peripheral: Peripheral) {
        try? peripheral.invalidateAllServices()
        runTaskOnMainThread { [weak self] in
            guard let `self` = self else { return }
            self._disconnectEvent.publish(peripheral)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        let unifiedState = central.unifiedState
        switch central.unifiedState {
        case .poweredOn:
            triggerAvailabilityUpdate(.available)
            
        default:
            let reason = UnavailabilityReason(state: unifiedState)
            stopOngoingTasks()
            triggerAvailabilityUpdate(.unavailable(reason: reason))
        }
    }
    
    private func stopOngoingTasks() {
        scanner.stop()
        connectionPool.reset()
    }
}

extension CentralManager: ConnectionPoolDelegate {
    
    func connectionPool(_ connectionPool: ConnectionPool, peripheralDidDisconnect peripheral: Peripheral) {
        triggerDisconnect(for: peripheral)
    }
}


