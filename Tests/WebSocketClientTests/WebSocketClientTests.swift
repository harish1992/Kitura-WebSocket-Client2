import XCTest
import KituraNet
import KituraWebSocket
@testable import WebSocketClient

class WebSocketClientTests: XCTestCase {
    
    private static let initOnce: () = {
        PrintLogger.use(colored: true)
    }()

    override func setUp() {
        super.setUp()
        //KituraTest.initOnce
    }

    private static var wsGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

    var secWebKey = "test"

    // Note: These two paths must only differ by the leading slash
    let servicePathNoSlash = "wstester"
    let servicePath = "/wstester"

    func performServerTest(line: Int = #line, asyncTasks: (XCTestExpectation) -> Void...) {
        let server = HTTP.createServer()
        server.allowPortReuse = true
        do {
            try server.listen(on: 8080)

            let requestQueue = DispatchQueue(label: "Request queue")

            for (index, asyncTask) in asyncTasks.enumerated() {
                let expectation = self.expectation(line: line, index: index)
                requestQueue.async {
                    asyncTask(expectation)
                }
            }

            waitForExpectations(timeout: 10) { error in
                // blocks test until request completes
                server.stop()
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("Test failed. Error=\(error)")
        }
    }

    func expectation(line: Int, index: Int) -> XCTestExpectation {
           return self.expectation(description: "\(type(of: self)):\(line)[\(index)]")
       }
}

