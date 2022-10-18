//
//  SendDataChannel.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2020/6/1.
//

import Foundation
import CoreBluetooth

/// 给蓝牙设备发送数据的通道，将数据发送到指定的 `CBCharacteristic`.
/// 您给以给每个 `CBCharacteristic` 都创建一个数据通道用来发送数据。
///
/// 支持发送任意数据，如果数据太大，data channel 会自动拆分成小数据包再发进行发送。
class SendDataChannel: NSObject {
    
    fileprivate let maxDataLengthPerWrite: Int
    fileprivate let peripheral: CBPeripheral
    fileprivate let characteristic: CBCharacteristic
    fileprivate let queue = DispatchQueue(label: "Queue.BluetoothCentral.SendDataChannel")
    
    fileprivate var sendDataTasks = [SendDataTask]()
    fileprivate var lock = MutexLock()
    
    var hasDataTasksNotSent: Bool {
        lock.lock()
        let empty = sendDataTasks.isEmpty
        lock.unlock()
        return !empty
    }
    
    init(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        maxDataLengthPerWrite = peripheral.maximumWriteValueLength(for: .withoutResponse)
    }
    
    func sendData(_ data: Data) {
        let dataTask = SendDataTask(data: data, maxDataLenghtCanSentOnce: maxDataLengthPerWrite)
        enqueue(dataTask)
        doNext()
    }
    
    /// 告诉 data channel 可以继续发送数据了。
    ///
    /// 当 `CBPeripheral` 的代理方法: `peripheralIsReady(toSendWriteWithoutResponse:)` 被调用时，
    /// 调用此方法来通知 data channel 继续发送数据。
    func peripheralIsReadyToSendData() {
        doNext()
    }
    
    /// 取消数据通道中的所有数据发送任务，比如蓝牙断开
    func cancelAllSendDataTasks() {
        lock.lock()
        sendDataTasks.removeAll()
        lock.unlock()
    }
}

fileprivate extension SendDataChannel {
    
    func enqueue(_ task: SendDataTask) {
        lock.lock()
        sendDataTasks.append(task)
        lock.unlock()
    }
    
    @discardableResult
    func dequeue() -> SendDataTask? {
        lock.lock()
        defer { lock.unlock() }
        return sendDataTasks.removeFirst()
    }
    
    func doNext() {
        queue.async { [weak self] in
            self?.processSendDataTasks()
        }
    }
    
    /// 处理数据发送队列中的等待任务。
    func processSendDataTasks() {
        guard hasDataTasksNotSent else {
            return
        }
        
        let nextTask = sendDataTasks.first!
        if nextTask.isAllDataSent {
            dequeue()
            doNext()
            return
        }
        
        // 如果数据还没有发送完
        if let nextSendData = nextTask.dataForNextSend {
            let properties = characteristic.properties
            if properties.contains(.writeWithoutResponse) {
                peripheral.writeValue(nextSendData, for: characteristic, type: .withoutResponse)
            } else if properties.contains(.write) {
                peripheral.writeValue(nextSendData, for: characteristic, type: .withResponse)
            } else {
                fatalError("这个 characteristic 不支持写数据")
            }
            
            nextTask.offset += nextSendData.count
            doNext()
        }
    }
}

fileprivate final class SendDataTask: Equatable {
    
    private let data: Data
    private let maxDataLenghtCanSentOnce: Int
    
    var offset: Int = 0
    
    init(data: Data, maxDataLenghtCanSentOnce: Int) {
        self.data = data
        self.maxDataLenghtCanSentOnce = maxDataLenghtCanSentOnce
    }

    var isAllDataSent: Bool {
        return remainingDataLength == 0
    }
    
    var dataForNextSend: Data? {
        if let range = rangeForNextSend {
             return data.subdata(in: range)
        } else {
            return nil
        }
    }
    
    private var remainingDataLength: Int {
        return data.count - offset
    }
    
    private var rangeForNextSend: Range<Int>? {
        let lengthForNextSend = remainingDataLength > maxDataLenghtCanSentOnce ? maxDataLenghtCanSentOnce : remainingDataLength
        let range = NSRange(location: offset, length: lengthForNextSend)
        return Range(range)
    }
    
    static func == (lhs: SendDataTask, rhs: SendDataTask) -> Bool {
        return lhs.data == rhs.data
    }
}


