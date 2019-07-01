import XCTest
@testable import PackStream

class MapTests: XCTestCase {

    func testEmptyMap() throws {
        let value = Map(dictionary: [:])
        let expected: [Byte] = [ 0xA0 ]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try Map.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testOnePairOfStrings() throws {

        let value = Map(dictionary: [ "one": "eins"] )
        let expected: [Byte] = [ 0xA1, 0x83, 0x6F, 0x6E, 0x65, 0x84, 0x65, 0x69, 0x6E, 0x73 ]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try Map.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testAlphabet() throws {

        let value = Map(dictionary: [ "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8, "I": 9, "J": 10, "K": 11, "L": 12, "M": 13, "N": 14, "O": 15, "P": 16, "Q": 17, "R": 18, "S": 19, "T": 20, "U": 21, "V": 22, "W": 23, "X": 24, "Y": 25, "Z": 26] )
        let expected: [[Byte]] = [[ 0xD8, 0x1A], [0x81, 0x45, 0x05], [0x81, 0x57, 0x17], [0x81, 0x42, 0x02], [0x81, 0x4A, 0x0A], [0x81, 0x41, 0x01], [0x81, 0x53, 0x13], [0x81, 0x4B, 0x0B], [0x81, 0x49, 0x09], [0x81, 0x4E, 0x0E], [0x81, 0x55, 0x15], [0x81, 0x4D, 0x0D], [0x81, 0x4C, 0x0C], [0x81, 0x5A, 0x1A], [0x81, 0x54, 0x14], [0x81, 0x56, 0x16], [0x81, 0x43, 0x03], [0x81, 0x59, 0x19], [0x81, 0x44, 0x04], [0x81, 0x47, 0x07], [0x81, 0x46, 0x06], [0x81, 0x50, 0x10], [0x81, 0x58, 0x18], [0x81, 0x51, 0x11], [0x81, 0x4F, 0x0F], [0x81, 0x48, 0x08], [0x81, 0x52, 0x12] ]

        let actual: [Byte] = try value.pack()
        for part in expected { // cannot guarantee order of parts
            if part.count == 2 { // first
                XCTAssertEqual(actual[0], part[0])
                XCTAssertEqual(actual[1], part[1])
            } else {
                XCTAssertTrue(actual.contains(part))
            }
        }

        let unpackedValue = try Map.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func test256Pairs() throws {

        try performTestWith(itemCount: 256)
    }

    func testForFun() throws {
        let map = Map(dictionary: [
            "alpha": 42,
            "beta": 39.3,
            "gamma": "☺",
            "delta": List(items: [1, 2, 3, 4])
            ])
        let result = try map.pack()

        XCTAssertNotEqual(0, result.count)
        XCTAssertNotNil(result)

        let restored = try Map.unpack(result)
        guard let fourtyTwo = restored.dictionary["alpha"] as? Int8 else { XCTFail(); return }
        XCTAssertEqual(42, fourtyTwo)

    }

    private func performTestWith(itemCount: Int) throws {

        var dict = [String: Int]()
        for _ in 0..<itemCount {
            let uuid = UUID()
            dict[uuid.uuidString] = uuid.hashValue % Int(Int16.max)
        }

        let value = Map(dictionary: dict)

        let actual: [Byte] = try value.pack()

        let unpackedValue = try Map.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    /* // This test takes too long that I want it as a unit test. Should investigate why
    func test65536Pairs() throws {

        try performTestWith(itemCount: 65536)
    }
    */

    static var allTests: [(String, (MapTests) -> () throws -> Void)] {
        return [

            ("testEmptyMap", testEmptyMap),
            ("testOnePairOfStrings", testOnePairOfStrings),
            ("testAlphabet", testAlphabet),
            ("test256Pairs", test256Pairs)
            //("test65536Pairs", test65536Pairs),

        ]
    }

}

// Ok, this is where the Swift type system becomes a bit too much for me...
protocol _UInt8Type { }
extension UInt8: _UInt8Type {}
extension Array where Element: _UInt8Type {

    func contains(_ part: [UInt8]) -> Bool {
        for i in 0 ..< self.count {
            if i + part.count > self.count {
                return false
            } else {
                let result = (0 ..< part.count).reduce(true, { (inResult, b) -> Bool in
                    if inResult == false {
                        return false
                    }

                    let s = self[i + b] as! UInt8
                    return inResult && s == part[b]
                })

                if result == true {
                    return true
                }
            }
        }
        return false
    }
}
