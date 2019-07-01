import XCTest
@testable import PackStream

class NullTests: XCTestCase {

    func testNull() throws {
        let val = Null()
        let bytes = try val.pack()
        let unpacked = try Null.unpack(bytes[0..<bytes.count])
        XCTAssert(type(of: val) == type(of: unpacked))
    }

    func testFailOnBadBytes() {

        do {
            let bytes = [ Byte(0x00) ]
            _ = try Null.unpack(bytes[0..<bytes.count])
        } catch {
            return // Test success
        }

        XCTFail("Should have reached exception")

    }

    static var allTests: [(String, (NullTests) -> () throws -> Void)] {
        return [
            ("testNull", testNull),
            ("testFailOnBadBytes", testFailOnBadBytes)
        ]
    }

}
