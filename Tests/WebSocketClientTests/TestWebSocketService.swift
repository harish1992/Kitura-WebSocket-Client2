//
//  TestWebSocketService.swift
//  WebSocketClientTests
//
//  Created by Haris Kumar S on 31/10/19.
//

import Foundation
import KituraNet
import KituraWebSocket
import Dispatch
import LoggerAPI
//public class EchoService {
//
//}
// A test WebSocket service used for running Autobahn tests in the CI
public class EchoService: WebSocketService {
    var connectCount = 0
    var disconnectCount = 0
    let connectionTimeOut: Int?
    private var _connectionId = ""
    let connectionIDAccessQueue: DispatchQueue = DispatchQueue(label: "Connection ID Access Queue")

    var connectionId: String {
        get {
            return connectionIDAccessQueue.sync {
                return _connectionId
            }
        }
        set {
            connectionIDAccessQueue.sync {
                _connectionId = newValue
            }
        }
    }

    public init(connectionTimeOut: Int? = nil){
        self.connectionTimeOut = connectionTimeOut
    }

    public func connected(connection: WebSocketConnection) {
        connectionId = connection.id
        connection.ping()
    }

    public func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
    }

    public func received(message: Data, from: WebSocketConnection) {
        from.send(message: message)
    }

    public func received(message: String, from: WebSocketConnection) {
        from.send(message: message)
    }

    public var connectionTimeout: Int? {
        return connectionTimeOut
    }
}

/// The set of colors used when logging with colorized lines
public enum TerminalColor: String {
    /// Log text in white.
    case white = "\u{001B}[0;37m" // white
    /// Log text in red, used for error messages.
    case red = "\u{001B}[0;31m" // red
    /// Log text in yellow, used for warning messages.
    case yellow = "\u{001B}[0;33m" // yellow
    /// Log text in the terminal's default foreground color.
    case foreground = "\u{001B}[0;39m" // default foreground color
    /// Log text in the terminal's default background color.
    case background = "\u{001B}[0;49m" // default background color
}

public class PrintLogger: Logger {
    let colored: Bool

    init(colored: Bool) {
        self.colored = colored
    }

    public func log(_ type: LoggerMessageType, msg: String,
                    functionName: String, lineNum: Int, fileName: String ) {
        let message = "[\(type)] [\(getFile(fileName)):\(lineNum) \(functionName)] \(msg)"

        guard colored else {
            print(message)
            return
        }

        let color: TerminalColor
        switch type {
        case .warning:
            color = .yellow
        case .error:
            color = .red
        default:
            color = .foreground
        }

        print(color.rawValue + message + TerminalColor.foreground.rawValue)
    }

    public func isLogging(_ level: LoggerAPI.LoggerMessageType) -> Bool {
        return true
    }

    public static func use(colored: Bool) {
        Log.logger = PrintLogger(colored: colored)
        setbuf(stdout, nil)
    }

    private func getFile(_ path: String) -> String {
        guard let range = path.range(of: "/", options: .backwards) else {
            return path
        }

        return String(path[range.upperBound...])
    }
}
