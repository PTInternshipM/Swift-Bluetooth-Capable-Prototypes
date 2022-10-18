//
//  DataFormatter.swift
//  BluetoothCentral
//
//  Created by Evan Xie on 2020/3/6.
//

import Foundation

public protocol HexadecimalExpressible {
    
    /// 不带 `0x` 前缀的十六进制字符串表示
    var hexString: String { get }
    
    /// 带 `0x` 前缀的十六进制字符串表示
    var hexStringWithTag: String { get }
}

extension HexadecimalExpressible {
    
    /// 255 -> 0xFF
    public var hexStringWithTag: String {
        return "0x\(hexString)"
    }
}

extension Data: HexadecimalExpressible {
    
    public var hexString: String {
        return self.map( { $0.hexString }).joined()
    }
}

extension UInt8: HexadecimalExpressible {
    
    /// 比我对齐宽度。 不对齐, 每 4 比特对齐，每 8 比特对齐
    public enum BitAlignmentWidth: Int {
        case none
        case four
        case eight
    }
    
    
    /// 255 -> FF
    public var hexString: String {
        return String(format: "%02x", self)
    }
    
    /// 字节的所有比特，默认为每 8 比特对齐。
    /// - Parameter alignmentWidth: 不对齐, 每 4 比特对齐，每 8 比特对齐
    /// - Returns: 所有比特。例如：
    ///     - 不对齐:       3 -> 11,       49 -> 110001
    ///     - 每 4 比特对齐: 3 -> 0011,     49 -> 00110001
    ///     - 每 8 比特对齐: 3 -> 00000011, 49 -> 00110001

    public func bitsString(alignmentWidth: BitAlignmentWidth = .eight) -> String {
        let binaryString = String(self, radix: 2)
        if alignmentWidth == .none {
            return binaryString
        }
        if self <= 0b1111, alignmentWidth == .four {
            return binaryString.stringByPadding(with: "0", mode: .head, width: 4)
        }
        return binaryString.stringByPadding(with: "0", mode: .head, width: 8)
    }
}

extension Array: HexadecimalExpressible where Element == UInt8 {
    public var hexString: String {
        let data = Data(self)
        return data.hexString
    }
}

extension String {
    
    /// 补齐模式，在开头还是末尾填充字符进行补齐。
    public enum PaddingMode: Int {
        case head
        case tail
    }
    
    /// 用指定的字符对字符串进行补齐
    /// - Parameters:
    ///   - character: 补齐用到的填充字符
    ///   - mode: 补齐模式
    ///   - width: 按多少宽度来补齐。如果字符串长度小于 `width`, 则进行填充。反之，不填充，直接返回原字符串。
    /// - Returns: 返回补齐后的字符串
    public func stringByPadding(with character: String, mode: PaddingMode, width: Int) -> String {
        let padCount = width - count
        guard padCount > 0 else {
            return self
        }
        
        var paddingString = ""
        for _ in 0..<padCount {
            paddingString.append(character)
        }
        
        switch mode {
        case .head:
            return paddingString + self
        case .tail:
            return self + paddingString
        }
    }
}
