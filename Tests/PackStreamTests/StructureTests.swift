import XCTest
@testable import PackStream

class StructureTests: XCTestCase {

    func testEmptyStructure() throws {

        let value = Structure(signature: 42, items: [])
        let expected: [Byte] = [0xB0, 0x2A]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try Structure.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testThreeSmallInts() throws {

        let value = Structure(signature: 42, items: [Int8(1), Int8(2), Int8(3)])
        let expected: [Byte] = [0xB3, 0x2A, 0x01, 0x02, 0x03]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try Structure.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testFourtySmallInts() throws {

        let items = Array(Int8(1)...Int8(40))
        let value = Structure(signature: 42, items: items)
        let expected: [Byte] = [0xDC, 0x28, 0x2A, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try Structure.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testTheeHetrogenousTypes() throws {

        let items: [PackProtocol] = [ Int8(1), Double(2.0), "three" ]
        let value = Structure(signature: 42, items: items)
        let expected: [Byte] = [0xB3, 0x2A, 0x01, 0xC1, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x85, 0x74, 0x68, 0x72, 0x65, 0x65]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try Structure.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testStructureOf256Ones() throws {

        let items = (0...255).map { _ in Int8(1) }
        let value = Structure(signature: 42, items: items)
        let expected: [Byte] = [0xDD, 0x01, 0x00, 0x2A] + ((0...255).map { _ in Byte(1) })

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try Structure.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    static var allTests: [(String, (StructureTests) -> () throws -> Void)] {
        return [
            ("testEmptyStructure", testEmptyStructure),
            ("testThreeSmallInts", testThreeSmallInts),
            ("testFourtySmallInts", testFourtySmallInts),
            ("testTheeHetrogenousTypes", testTheeHetrogenousTypes),
            ("testStructureOf256Ones", testStructureOf256Ones)
        ]
    }
}
