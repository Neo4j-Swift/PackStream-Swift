import XCTest
@testable import PackStream

class StringTests: XCTestCase {

    func testAlphabet() throws {
        let value = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let expected: [Byte] = [0xD0, 0x1A, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try String.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testDefaultSize() throws {
        let value = "Größenmaßstäbe"
        let expected: [Byte] = [0xD0, 0x12, 0x47, 0x72, 0xC3, 0xB6, 0xC3, 0x9F, 0x65, 0x6E, 0x6D, 0x61, 0xC3, 0x9F, 0x73, 0x74, 0xC3, 0xA4, 0x62, 0x65]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try String.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testEmptyString() throws {
        let value = ""
        let expected: [Byte] = [ 0x80 ]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try String.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testLetterA() throws {
        let value = "A"
        let expected: [Byte] = [ 0x81, 0x41 ]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try String.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testLetterEAccent() throws {
        let value = "é"
        let expected: [Byte] = [ 0x82, 0xC3, 0xA9 ]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try String.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func test256As() throws {

        let value = String.init(repeating: "A", count: 256)

        let expected = [Byte(0xD1), Byte(0x01), Byte(0x00)] + (0...255).map { (_) -> Byte in
            return Byte(0x41)
        }

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try String.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func test65536As() throws {

        let value = String.init(repeating: "A", count: 65536)

        let expected_part1 = [Byte(0xD2), Byte(0x00), Byte(0x01), Byte(0x00), Byte(0x00)]
        let expected_part2 = (0...65535).map { (_) -> Byte in
            return Byte(0x41)
        }
        let expected = expected_part1 + expected_part2

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try String.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    static var allTests: [(String, (StringTests) -> () throws -> Void)] {
        return [

            ("testAlphabet", testAlphabet),
            ("testDefaultSize", testDefaultSize),
            ("testEmptyString", testEmptyString),
            ("testLetterA", testLetterA),
            ("testLetterEAccent", testLetterEAccent),
            ("test256As", test256As),
            ("test65536As", test65536As)

        ]
    }

}
