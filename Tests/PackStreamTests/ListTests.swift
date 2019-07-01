import XCTest
@testable import PackStream

class ListTests: XCTestCase {

    func testEmptyList() throws {

        let value = List(items: [])
        let expected: [Byte] = [0x90]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try List.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testThreeSmallInts() throws {

        let value = List(items: [Int8(1), Int8(2), Int8(3)])
        let expected: [Byte] = [0x93, 0x01, 0x02, 0x03]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try List.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testFourtySmallInts() throws {

        let items = Array(Int8(1)...Int8(40))
        let value = List(items: items)
        let expected: [Byte] = [0xD4, 0x28, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try List.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testTheeHetrogenousTypes() throws {

        let items: [PackProtocol] = [ Int8(1), Double(2.0), "three" ]
        let value = List(items: items)
        let expected: [Byte] = [0x93, 0x01, 0xC1, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x85, 0x74, 0x68, 0x72, 0x65, 0x65]

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try List.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testListOf256Ones() throws {

        let items = (0...255).map { _ in Int8(1) }
        let value = List(items: items)
        let expected: [Byte] = [0xD5, 0x01, 0x00] + ((0...255).map { _ in Byte(1) })

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try List.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testListOf65536Ones() throws {

        let items = (0...65535).map { _ in Int8(1) }
        let value = List(items: items)
        let expected: [Byte] = [0xD6, 0x00, 0x01, 0x00, 0x00] + ((0...65535).map { _ in Byte(1) })

        let actual: [Byte] = try value.pack()
        XCTAssertEqual(expected, actual)

        let unpackedValue = try List.unpack(actual[0..<actual.count])
        XCTAssertEqual(value, unpackedValue)
    }

    func testWithRandomJSON() throws { // from http://www.json-generator.com
        let testPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().path
        let filePath = "\(testPath)/random.json"
        let jsonData = try String.init(contentsOfFile: filePath, encoding: .utf8).data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
        let array = json as! [PackProtocol]
        let bytes = try array.pack()
        XCTAssertNotNil(bytes)
    }

    static var allTests: [(String, (ListTests) -> () throws -> Void)] {
        return [
            ("testEmptyList", testEmptyList),
            ("testThreeSmallInts", testThreeSmallInts),
            ("testFourtySmallInts", testFourtySmallInts),
            ("testTheeHetrogenousTypes", testTheeHetrogenousTypes),
            ("testListOf256Ones", testListOf256Ones),
            ("testListOf65536Ones", testListOf65536Ones),
            ("testWithRandomJSON", testWithRandomJSON)
        ]
    }
}

extension NSArray {
    func toPackProtocol() -> [PackProtocol] {
        let array = self.compactMap { (item) -> PackProtocol? in
            if let i = item as? String {
                return i
            } else if let i = item as? NSArray {
                return i.toPackProtocol()
            } else if let i = item as? NSDictionary {
                return i.toPackProtocol()
            } else if let i = item as? Double {
                return i
            } else if let i = item as? Bool {
                return i
            } else if let i = item as? Int {
                return i
            }

            print("Not converting \(item) of type \(type(of: item))")
            return nil
        }

        return array
    }
}

extension NSDictionary: PackProtocol {
    func toPackProtocol() -> [String: PackProtocol] {
        var dict = [String: PackProtocol]()

        for (key, value) in self {
            let key = key as! String
            if let v = value as? NSArray {
                dict[key] = v.toPackProtocol()
            } else if let v = value as? NSDictionary {
                dict[key] = v.toPackProtocol()
            } else if let v = value as? String {
                dict[key] = v
            } else if let v = value as? Double {
                dict[key] = v
            } else if let v = value as? Bool {
                dict[key] = v
            } else if let v = value as? Int {
                dict[key] = v
            } else {
                print("Not converting \(value) of type \(type(of: value))")
            }
        }

        return dict
    }

    public func pack() throws -> [Byte] {

        let dict = self.toPackProtocol()
        let map = Map(dictionary: dict)
        return try map.pack()
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Self {
        return [:] // We're not using this
    }
}

 extension NSArray: PackProtocol {

    public func pack() throws -> [Byte] {

        let array = self.compactMap { (obj) -> PackProtocol? in
            if let p = obj as? PackProtocol {
                return p
            } else {
                return nil
            }
        }

        if array.count != self.count {
            throw PackError.notPackable
        }

        let list = List(items: array)
        return try list.pack()
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Self {
        return [] // We're not using this
    }

}
