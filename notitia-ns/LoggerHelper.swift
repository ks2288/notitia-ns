//
//  LoggerHelper.swift
//  notitia-ns
//
//  Created by Kenny Sofranko on 3/21/24.
//

import Foundation

/// Typealias to choose which implementation of Logger to use
typealias Logger = XCGLoggerLogger

/// Available log levels
enum LoggerLevel: Int {
    case verbose
    case debug
    case info
    case warning
    case critical
    case error
}

/// LoggerHelper is a protocol that defines the basic behavior required from the Logger class.
protocol LoggerHelper {
    /// tags associated with a log that should not be logged.
    static var disabledTags: [String] { get set }
    
    /// minimum level the logger will log.
    static var minimumLevel: LoggerLevel { get set }
    
    /// Setup logger and set minimum logging level.
    ///
    /// Typically call Logger.setup(minimumLevel: .debug) in AppDelegate
    ///
    /// - Parameter minimumLevel: LoggerLevel to be minimum level.
    static func setup(minimumLevel: LoggerLevel)
    
    /// Implement the logging functionality
    ///
    /// - Parameters:
    ///   - level: level of the log message
    ///   - message: message to log
    static func doLog(level: LoggerLevel,
                      message: String,
                      function: String,
                      filePath: String,
                      fileLine: Int,
                      tags: [String])
    
    /// Info log channel
    ///
    /// - Parameters:
    ///   - message:
    ///   - function:
    ///   - filePath:
    ///   - fileLine:
    static func i(_ message: String,
                  function: String,
                  filePath: String,
                  fileLine: Int,
                  tags: [String])
    
    /// Warn log channel
    ///
    /// - Parameters:
    ///   - message:
    ///   - function:
    ///   - filePath:
    ///   - fileLine:
    static func w(_ message: String,
                  function: String,
                  filePath: String,
                  fileLine: Int,
                  tags: [String])
    
    /// Verbose log channel
    ///
    /// - Parameters:
    ///   - message:
    ///   - function:
    ///   - filePath:
    ///   - fileLine:
    static func v(_ message: String,
                  function: String,
                  filePath: String,
                  fileLine: Int,
                  tags: [String])
    
    /// Debug log channel
    ///
    /// - Parameters:
    ///   - message:
    ///   - function:
    ///   - filePath:
    ///   - fileLine:
    static func d(_ message: String,
                  function: String,
                  filePath: String,
                  fileLine: Int,
                  tags: [String])
    
    /// Error log channel
    ///
    /// - Parameters:
    ///   - message:
    ///   - function:
    ///   - filePath:
    ///   - fileLine:
    static func e(_ message: String,
                  function: String,
                  filePath: String,
                  fileLine: Int,
                  tags: [String])
}

/// Extension to provide functions with default parameters populated.
extension LoggerHelper {
    
    static func doLog(level: LoggerLevel,
                      message: String,
                      function: String = #function,
                      filePath: String = #file,
                      fileLine: Int = #line,
                      tags: [String] = []) {
        doLog(level: level,
              message: message,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              tags: tags)
    }
    
    static func i(_ message: String,
                  function: String = #function,
                  filePath: String = #file,
                  fileLine: Int = #line,
                  tags: [String] = []) {
        doLog(level: .info,
              message: message,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              tags: tags)
    }
    
    static func w(_ message: String,
                  function: String = #function,
                  filePath: String = #file,
                  fileLine: Int = #line,
                  tags: [String] = []) {
        doLog(level: .warning,
              message: message,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              tags: tags)
    }
    
    
    static func v(_ message: String,
                  function: String = #function,
                  filePath: String = #file,
                  fileLine: Int = #line,
                  tags: [String] = []) {
        doLog(level: .verbose,
              message: message,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              tags: tags)
    }
    
    static func d(_ message: String,
                  function: String = #function,
                  filePath: String = #file,
                  fileLine: Int = #line,
                  tags: [String] = []) {
        doLog(level: .debug,
              message: message,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              tags: tags)
    }
    
    static func e(_ message: String,
                  function: String = #function,
                  filePath: String = #file,
                  fileLine: Int = #line,
                  tags: [String] = []) {
        doLog(level: .error,
              message: message,
              function: function,
              filePath: filePath,
              fileLine: fileLine,
              tags: tags)
    }
}
