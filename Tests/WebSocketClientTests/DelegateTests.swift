//
//  DelegateTests.swift
//  WebSocketClientTests
//
//  Created by Haris Kumar S on 26/11/19.
//

import Foundation
import KituraWebSocket
import XCTest
import NIO
import NIOWebSocket
import NIOHTTP1
@testable import WebSocketClient
import NIOFoundationCompat

class DelegateTests: WebSocketClientTests {

    let uint8Code: Data = Data([UInt8(WebSocketCloseReasonCode.normal.code() >> 8),
                                     UInt8(WebSocketCloseReasonCode.normal.code() & 0xff)])

    func testTextCallBackDelegate() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            let text = "\u{00}"
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: text.data(using: .utf8)!, expectation: expectation)
            client.connect()
            client.sendText(text)
        }
    }

    func testBinaryCallBackDelegate() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            let binaryPayload = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e])
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: binaryPayload, expectation: expectation)
            client.connect()
            client.sendBinary(binaryPayload)
        }
    }

    func testCloseCallBackDelegate() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: self.uint8Code, expectation: expectation)
            client.connect()
            client.close(data: Data())
        }
    }

    func testPongCallBackDelegate() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: Data(), expectation: expectation)
            client.connect()
            client.ping(data: Data())
        }
    }

    func testErrorCallBackDelegate() {
        performServerTest { expectation in
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: Data(), expectation: expectation)
            client.connect()
            client.ping()
        }
    }

    func testOnBinaryDelegatePriority() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: Data(), expectation: expectation)
            client.connect()
            client.sendBinary(Data())
            client.onBinary { _ in
                XCTFail("Delegates must have highest priority")
                expectation.fulfill()
            }
        }
    }

    func testOnTextDelegatePriority() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: "".data(using: .utf8)!, expectation: expectation)
            client.connect()
            client.sendText("")
            client.onText { _ in
                XCTFail("Delegates must have highest priority")
                expectation.fulfill()
            }
        }
    }

    func testOnPongDelegatePriority() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: "".data(using: .utf8)!, expectation: expectation)
            client.connect()
            client.ping()
            client.onPong { _,_  in
                XCTFail("Delegates must have highest priority")
                expectation.fulfill()
            }
        }
    }

    func testOnCloseDelegatePriority() {
        let echoDelegate = EchoService()
        WebSocket.register(service: echoDelegate, onPath: self.servicePath)
        performServerTest { expectation in
            guard let client = WebSocketClient("http://localhost:8080/wstester") else {
                XCTFail("Unable to create client")
                return
            }
            client.delegate = WSClientDelegate(client: client, expectedPayload: self.uint8Code, expectation: expectation)
            client.connect()
            client.close()
            client.onClose { _,_  in
                XCTFail("Delegates must have highest priority")
                expectation.fulfill()
            }
        }
    }
}

// Implements WebSocketClient Callback functions referenced by protocol `WebSocketClientDelegate`
class WSClientDelegate: WebSocketClientDelegate {
    weak var client: WebSocketClient?
    let expectedPayload: Data
    let expectation: XCTestExpectation

    init(client: WebSocketClient, expectedPayload: Data, expectation: XCTestExpectation){
        self.client = client
        self.expectedPayload = expectedPayload
        self.expectation = expectation
    }

    func onPing(data: Data) {
        client?.pong(data: data)
    }

    func onPong(data: Data) {
        XCTAssertEqual(data, expectedPayload, "Payloads not equal")
        expectation.fulfill()
    }

    func onBinary(data: Data) {
        XCTAssertEqual(data, expectedPayload, "Payloads not equal")
        expectation.fulfill()
    }

    func onText(text: String) {
        XCTAssertEqual(text, String(data: expectedPayload, encoding: .utf8), "Payloads not equal")
        expectation.fulfill()
    }

    func onClose(channel: Channel, data: Data) {
        XCTAssertEqual(data, expectedPayload, "Payloads not equal")
        expectation.fulfill()
    }

    func onError(error: Error?, status: HTTPResponseStatus?) {
        XCTAssertEqual(error as! WebSocketClientError, WebSocketClientError.webSocketUrlNotRegistered, "Invalid Error")
        XCTAssertEqual(status, HTTPResponseStatus.notFound, "Status not equal")
        expectation.fulfill()
    }
}
