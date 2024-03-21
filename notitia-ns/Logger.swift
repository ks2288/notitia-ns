//
//  Logger.swift
//  notitia-ns
//
//

import Foundation
import os.log
import XCGLogger

extension OSLog {
    //swiftlint:disable:next force_unwrapping
    private static let subsystem = Bundle.main.bundleIdentifier!
    static let consoleLog = OSLog(subsystem: subsystem, category: "dev.specter")
}

class XCGLoggerLogger: LoggerHelper {
    
    private static let logger: XCGLogger = {
        let logger = XCGLogger.default
        logger.logAppDetails()
        return logger
    }()
    
    private static var documentDirectory: URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    /// Determines if the app is running while attached to a debugger
    static let isDebuggerAttached: Bool = {
        #if DEBUG
        var name: [Int32] = [
            CTL_KERN,
            KERN_PROC,
            KERN_PROC_PID,
            getpid()
        ]
        var info = kinfo_proc()
        var infoSize = MemoryLayout.size(ofValue: info)
        var isAttached = false
        if sysctl(&name, 4, &info, &infoSize, nil, 0) == -1 {
            print("Failed to execute sysctl")
        } else if (info.kp_proc.p_flag & P_TRACED) != 0 {
            isAttached = true
            if isAttached {
                print("App is running while attached to a debugger.")
            }
        }
        return isAttached
        #else
        return false
        #endif
    }()
    
    private static let tags = XCGLogger.Constants.userInfoKeyTags
    
    #if DEBUG
    // !isDebuggerAttached prevents double messages being printed to Xcode log window
    private static let isConsoleEnabled = !isDebuggerAttached
    #else
    private static let isConsoleEnabled = false
    #endif
    
    static var disabledTags: [String] = []
    
    /// minimum level the logger will log.
    static var minimumLevel = LoggerLevel.verbose {
        didSet {
            #if DEBUG
            let minLevel = XCGLogger.Level.debug
            #else
            let minLevel = minimumLevel.toXCGLoggerLevel()
            #endif
            let date = Date()
            let dateString = date.datetimeString("MM:dd'T'HHmm")
            let filePath = documentDirectory.appendingPathComponent("NotitiaLog_\(dateString).txt")
            
            logger.setup(level: minLevel,
                         showLogIdentifier: false,
                         showFunctionName: false,
                         showThreadName: true,
                         showLevel: true,
                         showFileNames: false,
                         showLineNumbers: false,
                         showDate: true,
                         writeToFile: filePath)
        }
    }
    
    static func setup(minimumLevel: LoggerLevel = .verbose) {
        Self.minimumLevel = minimumLevel
    }
    
    /// Implement the logging functionality
    ///
    /// - Parameters:
    ///   - level: level of the log message
    ///   - message: message to log
    ///   - file:
    ///   - line:
    ///   - function:
    ///   - logTags: A Set of tags, or nil
    static func doLog(level: LoggerLevel,
                      message: String,
                      function: String,
                      filePath: String,
                      fileLine: Int,
                      tags: [String] = []) {
        if tags.filter({ Self.disabledTags.contains($0) }).isEmpty,
           level.rawValue >= minimumLevel.rawValue {
            // 3) we're now ready to use it
            let prefix = "(\(filePath.components(separatedBy: "/").last ?? ""):\(fileLine)) - \(function):"
            let logMessage = "\(prefix) \(message)"
            
            if isConsoleEnabled {
                let now = Date()
                let consoleMesssage = "\(now) - [\(level)] - \(logMessage)"
                os_log("%{public}@", log: .consoleLog, consoleMesssage)
            }
            
            switch level {
            case .verbose:
                logger.verbose("◽️ \(logMessage)",
                               userInfo: [Self.tags: tags])
            case .debug:
                logger.debug("◾️ \(logMessage)",
                             userInfo: [Self.tags: tags])
            case .info:
                logger.info("🔷 \(logMessage)",
                            userInfo: [Self.tags: tags])
            case .warning:
                logger.warning("🔶 \(logMessage)",
                               userInfo: [Self.tags: tags])
            case .critical:
                logger.severe("🚫 \(logMessage)",
                              userInfo: [Self.tags: tags])
            case .error:
                logger.error("❌ \(logMessage)",
                             userInfo: [Self.tags: tags])
            }
        }
    }
}

fileprivate extension LoggerLevel {
    func toXCGLoggerLevel() -> XCGLogger.Level {
        switch self {
        case .verbose:
            return .verbose
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .critical:
            return .severe
        case .error:
            return .error
        }
    }
}
