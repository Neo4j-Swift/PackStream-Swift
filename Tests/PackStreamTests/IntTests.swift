import XCTest
@testable import PackStream

class Int8Tests: XCTestCase {

    func testOneByteMin() throws {
        let value = Int8(-0x10)
        let bytes = try value.pack()
        XCTAssertEqual(1, bytes.count)

        let unpacked = try Int8.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testMin() throws {

        let value = Int8.min
        let bytes = try value.pack()
        XCTAssertEqual(2, bytes.count)

        let unpacked = try Int8.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testMax() throws {

        let value = Int8.max
        let bytes = try value.pack()
        XCTAssertEqual(1, bytes.count)

        let unpacked = try Int8.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func test42() throws {

        let value: Int8 = 42
        let bytes = try value.pack()
        XCTAssertEqual(1, bytes.count)
        XCTAssertEqual(0x2A, bytes[0])

        let unpacked = try Int8.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func test42_alt() throws {

        let value: Int8 = 42
        let bytes = [ Byte(0xC8), Byte(0x2A) ]

        let unpacked = try Int8.unpack(bytes[0..<bytes.count])

        XCTAssertEqual(value, unpacked)
    }

    func testPerformance() throws {

        measure {
            let values: [Int8] = (0..<10).map { _ -> Int8 in return Int8.random() }

            do {
                for value in values {

                    let bytes = try value.pack()
                    let unpacked = try Int8.unpack(bytes[0..<bytes.count])
                    XCTAssertEqual(value, unpacked)
                }
            } catch {
                XCTFail("Didn't expect any exceptions in performance measurement")
            }

        }
    }

    static var allTests: [(String, (Int8Tests) -> () throws -> Void)] {
        #if os(Linux)
            return [
                ("testOneByteMin", testOneByteMin),
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42)
            ]
        #else
            return [
                ("testOneByteMin", testOneByteMin),
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42),
                ("testPerformance", testPerformance)
            ]
        #endif
    }

}

class Int16Tests: XCTestCase {

    func testMin() throws {

        let value = Int16.min
        let bytes = try value.pack()
        XCTAssertEqual(3, bytes.count)

        let unpacked = try Int16.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testMax() throws {

        let value = Int16.max
        let bytes = try value.pack()
        XCTAssertEqual(3, bytes.count)

        let unpacked = try Int16.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func test42() throws {

        let value: Int16 = 42
        let bytes = try value.pack()
        XCTAssertEqual(3, bytes.count)
        XCTAssertEqual(0xC9, bytes[0])
        XCTAssertEqual(0x00, bytes[1])
        XCTAssertEqual(0x2A, bytes[2])

        let unpacked = try Int16.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func test1234() throws {

        let value: Int16 = 1234
        let bytes = try value.pack()
        XCTAssertEqual(3, bytes.count)
        XCTAssertEqual(0xC9, bytes[0])
        XCTAssertEqual(0x04, bytes[1])
        XCTAssertEqual(0xD2, bytes[2])

        let unpacked = try Int16.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testPerformance() throws {

        measure {
            let values: [Int16] = (0..<10).map { _ -> Int16 in return Int16.random() }

            do {
                for value in values {

                    let bytes = try value.pack()
                    let unpacked = try Int16.unpack(bytes[0..<bytes.count])
                    XCTAssertEqual(value, unpacked)
                }
            } catch {
                XCTFail("Didn't expect any exceptions in performance measurement")
            }

        }
    }

    static var allTests: [(String, (Int16Tests) -> () throws -> Void)] {
        #if os(Linux)
            return [
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42),
                ("test1234", test1234)
            ]
        #else
            return [
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42),
                ("test1234", test1234),
                ("testPerformance", testPerformance)
            ]
        #endif
    }

}

class Int32Tests: XCTestCase {

    func testMin() throws {

        let value = Int32.min
        let bytes = try value.pack()
        XCTAssertEqual(5, bytes.count)

        let unpacked = try Int32.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testMax() throws {

        let value = Int32.max
        let bytes = try value.pack()
        XCTAssertEqual(5, bytes.count)

        let unpacked = try Int32.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func test42() throws {

        let value: Int32 = 42
        let bytes = try value.pack()
        XCTAssertEqual(5, bytes.count)
        XCTAssertEqual(0xCA, bytes[0])
        XCTAssertEqual(0x00, bytes[1])
        XCTAssertEqual(0x00, bytes[2])
        XCTAssertEqual(0x00, bytes[3])
        XCTAssertEqual(0x2A, bytes[4])

        let unpacked = try Int32.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testPerformance() throws {

        measure {
            let values: [Int32] = (0..<10).map { _ -> Int32 in return Int32.random() }

            do {
                for value in values {

                    let bytes = try value.pack()
                    let unpacked = try Int32.unpack(bytes[0..<bytes.count])
                    XCTAssertEqual(value, unpacked)
                }
            } catch {
                XCTFail("Didn't expect any exceptions in performance measurement")
            }

        }
    }

    static var allTests: [(String, (Int32Tests) -> () throws -> Void)] {
        #if os(Linux)
            return [
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42)
            ]
        #else
            return [
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42),
                ("testPerformance", testPerformance)
            ]
        #endif
    }

}

class Int64Tests: XCTestCase {

    func testMin() throws {

        let value = Int64.min
        let bytes = try value.pack()
        XCTAssertEqual(9, bytes.count)

        let unpacked = try Int64.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testMax() throws {

        let value = Int64.max
        let bytes = try value.pack()
        XCTAssertEqual(9, bytes.count)

        let unpacked = try Int64.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func test42() throws {

        let value: Int64 = 42
        let bytes = try value.pack()
        XCTAssertEqual(9, bytes.count)
        XCTAssertEqual(0xCB, bytes[0])
        XCTAssertEqual(0x00, bytes[1])
        XCTAssertEqual(0x00, bytes[2])
        XCTAssertEqual(0x00, bytes[3])
        XCTAssertEqual(0x00, bytes[4])
        XCTAssertEqual(0x00, bytes[5])
        XCTAssertEqual(0x00, bytes[6])
        XCTAssertEqual(0x00, bytes[7])
        XCTAssertEqual(0x2A, bytes[8])

        let unpacked = try Int64.unpack(bytes[0..<bytes.count])
        XCTAssertEqual(value, unpacked)
    }

    func testPerformance() throws {

        measure {
            let values: [Int64] = (0..<10).map { _ -> Int64 in return Int64.random() }

            do {
                for value in values {

                    let bytes = try value.pack()
                    let unpacked = try Int64.unpack(bytes[0..<bytes.count])
                    XCTAssertEqual(value, unpacked)
                }
            } catch {
                XCTFail("Didn't expect any exceptions in performance measurement")
            }

        }
    }

    static var allTests: [(String, (Int64Tests) -> () throws -> Void)] {
        #if os(Linux)
            return [
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42)
            ]
        #else
            return [
                ("testMin", testMin),
                ("testMax", testMax),
                ("test42", test42),
                ("testPerformance", testPerformance)
            ]
        #endif
    }

}
