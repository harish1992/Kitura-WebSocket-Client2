/*
* Copyright IBM Corporation 2019
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import KituraWebSocket
import XCTest
import NIO
import NIOWebSocket
import NIOHTTP1
@testable import WebSocketClient

class ConnectionCleanUptests: WebSocketClientTests {

    func testNilConnectionTimeOut() {
            let echoDelegate = EchoService()
            WebSocket.register(service: echoDelegate, onPath: self.servicePath)
            performServerTest { expectation in
                guard let client = WebSocketClient(host: "localhost", port: 8080, uri: self.servicePath, requestKey: self.secWebKey) else {
                        XCTFail("Unable to create WebSocketClient")
                        return
                }
                client.connect()
                sleep(2)
                XCTAssertTrue(client.isConnected)
                expectation.fulfill()
            }
        }

        func testSingleConnectionTimeOut() {
            let echoDelegate = EchoService(connectionTimeOut: 2)
            WebSocket.register(service: echoDelegate, onPath: self.servicePath)
            performServerTest { expectation in
                guard let client = WebSocketClient(host: "localhost", port: 8080, uri: self.servicePath, requestKey: self.secWebKey) else {
                        XCTFail("Unable to create WebSocketClient")
                        return
                }
                client.connect()
                sleep(4)
                XCTAssertFalse(client.isConnected)
                expectation.fulfill()
            }
        }

        func testPingKeepsConnectionAlive() {
            let echoDelegate = EchoService(connectionTimeOut: 2)
            WebSocket.register(service: echoDelegate, onPath: self.servicePath)
            performServerTest { expectation in
                guard let client = WebSocketClient(host: "localhost", port: 8080, uri: self.servicePath, requestKey: self.secWebKey) else {
                        XCTFail("Unable to create WebSocketClient")
                        return
                }
                let delegate = ClientDelegate(client: client)
                client.delegate = delegate
                client.connect()
                sleep(4)
                XCTAssertTrue(client.isConnected)
                expectation.fulfill()
            }
        }

        func testMultiConnectionTimeOut() {
            let echoDelegate = EchoService(connectionTimeOut: 2)
            WebSocket.register(service: echoDelegate, onPath: self.servicePath)
            performServerTest { expectation in
                guard let client1 = WebSocketClient(host: "localhost", port: 8080, uri: self.servicePath, requestKey: self.secWebKey) else {
                                   XCTFail("Unable to create WebSocketClient")
                                   return
                           }
                client1.connect()
                guard let client2 = WebSocketClient(host: "localhost", port: 8080, uri: self.servicePath, requestKey: self.secWebKey) else {
                        XCTFail("Unable to create WebSocketClient")
                        return
                }
                let delegate = ClientDelegate(client: client2)
                client2.delegate = delegate
                client2.connect()

                sleep(4)
                XCTAssertFalse(client1.isConnected)
                XCTAssertTrue(client2.isConnected)
                expectation.fulfill()
            }
        }
}

// Implements WebSocketClient Callback functions referenced by protocol `WebSocketClientDelegate`
class ClientDelegate: WebSocketClientDelegate {
    weak var client: WebSocketClient?

    init(client: WebSocketClient){
        self.client = client
    }

    func onPing(data: Data) {
        client?.pong(data: data)
    }
}
