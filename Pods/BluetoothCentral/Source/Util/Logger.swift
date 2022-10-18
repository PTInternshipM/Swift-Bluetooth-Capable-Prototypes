//
//  Logger.swift
//
//  Created by Evan Xie on 2019/3/29.
//

import Foundation

/// 简单的控制台 log 输出
public struct Logger {
    
    private static var _dateFormatter: DateFormatter {
        if dateFormatter == nil {
            dateFormatter = DateFormatter()
            dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }
        return dateFormatter!
    }
    
    /// 是否开启 log, 默认为关闭。
    public static var isEnabled = true
    
    /// Log 输出的日期显示格式，不提供则使用默认格式。
    public static var dateFormatter: DateFormatter? = nil
    
    public static func trace(file: String = #file, method: String = #function) {
        if isEnabled {
            print("\(_dateFormatter.string(from: Date())) [Trace] \(method)]")
        }
    }
    
    public static func debug<T>(_ message: T, file: String = #file, method: String = #function) {
        if isEnabled {
            print("\(_dateFormatter.string(from: Date())) [Debug] \(message)")
        }
    }
    
    public static func info<T>(_ message: T, file: String = #file, method: String = #function) {
        if isEnabled {
            print("\(_dateFormatter.string(from: Date())) [Info] \(message)")
        }
    }
    
    public static func warning<T>(_ message: T, file: String = #file, method: String = #function) {
        if isEnabled {
            print("\(_dateFormatter.string(from: Date())) [⚠️] \(message)")
        }
    }
    
    public static func error<T>(_ message: T, file: String = #file, method: String = #function) {
        if isEnabled {
            print("\(_dateFormatter.string(from: Date())) [❌]  \(message)")
        }
    }
    
    public static func tag<T>(_ tag: String, message: T, file: String = #file, method: String = #function) {
        if isEnabled {
            print("\(_dateFormatter.string(from: Date())) [\(tag)] \(message)")
        }
    }
}
