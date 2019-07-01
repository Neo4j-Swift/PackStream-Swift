import XCTest

#if os(Linux)
    import Glibc
    let DBL_MIN = -1000.0 //TODO: How do I get min/max of Double on Linux?
    let DBL_MAX = 1000.0
#else
    import Darwin
#endif

@testable import PackStream

class FloatTests: XCTestCase {

    func testMin() throws {

        let value = Double.leastNormalMagnitude
        let bytes = try value.pack()
        XCTAssertEqual(9, bytes.count)

        let unpacked = try Double.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testMax() throws {

        let value = Double.greatestFiniteMagnitude
        let bytes = try value.pack()
        XCTAssertEqual(9, bytes.count)

        let unpacked = try Double.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func test42() throws {

        let value: Float64 = Float64(42.0)
        let bytes = try value.pack()
        XCTAssertEqual(9, bytes.count)
        XCTAssertEqual(0xC1, bytes[0])
        XCTAssertEqual(0x40, bytes[1]) // what should it be?
        XCTAssertEqual(0x45, bytes[2])
        XCTAssertEqual(0x00, bytes[3])
        XCTAssertEqual(0x00, bytes[4])
        XCTAssertEqual(0x00, bytes[5])
        XCTAssertEqual(0x00, bytes[6])
        XCTAssertEqual(0x00, bytes[7])
        XCTAssertEqual(0x00, bytes[8])

        let unpacked = try Float64.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)

    }

    func test_6_283185307179586() throws {
        let value: Float64 = 6.283185307179586
        let bytes = try value.pack()
        XCTAssertEqual(9, bytes.count)
        XCTAssertEqual(0xC1, bytes[0])
        XCTAssertEqual(0x40, bytes[1])
        XCTAssertEqual(0x19, bytes[2])
        XCTAssertEqual(0x21, bytes[3])
        XCTAssertEqual(0xFB, bytes[4])
        XCTAssertEqual(0x54, bytes[5])
        XCTAssertEqual(0x44, bytes[6])
        XCTAssertEqual(0x2D, bytes[7])
        XCTAssertEqual(0x18, bytes[8])

        let unpacked = try Float64.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)

    }

    func test_1_1() throws {
        let pos: [Byte] = [0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A]
        let neg: [Byte] = [0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A]

        XCTAssertEqual(Double(1.1), try Double.unpack(pos[0..<pos.count]))
        XCTAssertEqual(Double(-1.1), try Double.unpack(neg[0..<neg.count]))
    }

    static var allTests: [(String, (FloatTests) -> () throws -> Void)] {
        return [

            ("testMin", testMin),
            ("testMax", testMax),
            ("test42", test42),
            ("test_6_283185307179586", test_6_283185307179586),
            ("test_1_1", test_1_1)

        ]
    }

}
