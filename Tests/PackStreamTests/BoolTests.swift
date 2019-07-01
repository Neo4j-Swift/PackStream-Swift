import XCTest
@testable import PackStream

class BoolTests: XCTestCase {

    func testTrue() throws {
        let val = true
        let bytes = try val.pack()
        let unpacked = try Bool.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(val, unpacked)
    }

    func testFalse() throws {
        let val = false
        let bytes = try val.pack()
        let unpacked = try Bool.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(val, unpacked)
    }

    func testFailOnBadBytes() {

        do {
            let bytes = [ Byte(0x00) ]
            _ = try Bool.unpack(bytes[0..<bytes.count])
        } catch {
            return // Test success
        }

        XCTFail("Should have reached exception")

    }

    static var allTests: [(String, (BoolTests) -> () throws -> Void)] {
        return [
            ("testTrue", testTrue),
            ("testFalse", testFalse),
            ("testFailOnBadBytes", testFailOnBadBytes)
        ]
    }

}
