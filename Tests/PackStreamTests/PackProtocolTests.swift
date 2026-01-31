import XCTest
import NIOCore
@testable import PackStream

/// Tests for PackProtocol extensions and core functionality
/// These test the ByteBuffer integration and integer conversion helpers
class PackProtocolTests: XCTestCase {

    // MARK: - Integer Conversion Tests (intValue)

    func testIntValueFromInt8() {
        let value: Int8 = -42
        XCTAssertEqual(value.intValue(), Int64(-42))
    }

    func testIntValueFromInt16() {
        let value: Int16 = 1000
        XCTAssertEqual(value.intValue(), Int64(1000))
    }

    func testIntValueFromInt32() {
        let value: Int32 = 100000
        XCTAssertEqual(value.intValue(), Int64(100000))
    }

    func testIntValueFromInt64() {
        let value: Int64 = Int64.max
        XCTAssertEqual(value.intValue(), Int64.max)
    }

    func testIntValueFromNegativeInt64() {
        let value: Int64 = -999
        XCTAssertEqual(value.intValue(), Int64(-999))
    }

    func testIntValueFromNonInteger() {
        let value: String = "not an integer"
        XCTAssertNil(value.intValue())
    }

    func testIntValueFromDouble() {
        let value: Double = 3.14
        XCTAssertNil(value.intValue())
    }

    func testIntValueFromBool() {
        let value: Bool = true
        XCTAssertNil(value.intValue())
    }

    // MARK: - Unsigned Integer Conversion Tests (uintValue)

    func testUintValueFromPositiveInt8() {
        let value: Int8 = 42
        XCTAssertEqual(value.uintValue(), UInt64(42))
    }

    func testUintValueFromNegativeInt8() {
        let value: Int8 = -42
        XCTAssertNil(value.uintValue())  // Negative values return nil
    }

    func testUintValueFromLargePositiveInt64() {
        let value: Int64 = Int64.max
        XCTAssertEqual(value.uintValue(), UInt64(Int64.max))
    }

    func testUintValueFromZero() {
        let value: Int64 = 0
        XCTAssertEqual(value.uintValue(), UInt64(0))
    }

    func testUintValueFromPositiveInt64() {
        let value: Int64 = 9999999
        XCTAssertEqual(value.uintValue(), UInt64(9999999))
    }

    func testUintValueFromNegativeInt64() {
        let value: Int64 = -1
        XCTAssertNil(value.uintValue())
    }

    func testUintValueFromString() {
        let value: String = "test"
        XCTAssertNil(value.uintValue())
    }

    // MARK: - Int Initializer Tests

    func testIntInitFromUInt8() {
        let value: UInt8 = 100
        XCTAssertEqual(Int(value), 100)
    }

    func testIntInitFromInt64() {
        let value: Int64 = 12345
        XCTAssertEqual(Int(value), 12345)
    }

    func testIntInitFromNegativeReturnsNil() {
        let value: Int64 = -5
        XCTAssertNil(Int(value))  // uintValue returns nil for negatives
    }

    // MARK: - ByteBuffer Integration Tests

    func testPackIntoByteBuf() throws {
        let value: Int8 = 42
        var buffer = ByteBufferAllocator().buffer(capacity: 100)

        try value.pack(into: &buffer)

        XCTAssertGreaterThan(buffer.readableBytes, 0)
    }

    func testPackStringIntoByteBuffer() throws {
        let value = "Hello, PackStream!"
        var buffer = ByteBufferAllocator().buffer(capacity: 100)

        try value.pack(into: &buffer)

        XCTAssertGreaterThan(buffer.readableBytes, 0)
    }

    func testPackListIntoByteBuffer() throws {
        let list = List(items: [Int64(1), Int64(2), Int64(3)])
        var buffer = ByteBufferAllocator().buffer(capacity: 100)

        try list.pack(into: &buffer)

        XCTAssertGreaterThan(buffer.readableBytes, 0)
    }

    func testPackMapIntoByteBuffer() throws {
        let map = Map(dictionary: ["key": "value", "number": Int64(42)])
        var buffer = ByteBufferAllocator().buffer(capacity: 100)

        try map.pack(into: &buffer)

        XCTAssertGreaterThan(buffer.readableBytes, 0)
    }

    func testPackStructureIntoByteBuffer() throws {
        let structure = Structure(signature: 0x4E, items: [Int64(123), "test"])
        var buffer = ByteBufferAllocator().buffer(capacity: 100)

        try structure.pack(into: &buffer)

        XCTAssertGreaterThan(buffer.readableBytes, 0)
    }

    func testPackNullIntoByteBuffer() throws {
        let null = Null()
        var buffer = ByteBufferAllocator().buffer(capacity: 10)

        try null.pack(into: &buffer)

        XCTAssertEqual(buffer.readableBytes, 1)
    }

    func testPackBoolIntoByteBuffer() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 10)

        try true.pack(into: &buffer)

        XCTAssertEqual(buffer.readableBytes, 1)
    }

    func testPackDoubleIntoByteBuffer() throws {
        let value: Double = 3.14159
        var buffer = ByteBufferAllocator().buffer(capacity: 20)

        try value.pack(into: &buffer)

        XCTAssertGreaterThan(buffer.readableBytes, 0)
    }

    // MARK: - Unpack from Full Array Tests

    func testUnpackInt8FromFullArray() throws {
        let original: Int8 = 42
        let bytes = try original.pack()

        let unpacked = try Int8.unpack(bytes)
        XCTAssertEqual(unpacked, original)
    }

    func testUnpackStringFromFullArray() throws {
        let original = "test string"
        let bytes = try original.pack()

        let unpacked = try String.unpack(bytes)
        XCTAssertEqual(unpacked, original)
    }

    func testUnpackListFromFullArray() throws {
        let original = List(items: ["a", "b", "c"])
        let bytes = try original.pack()

        let unpacked = try List.unpack(bytes)
        XCTAssertEqual(unpacked.items.count, 3)
    }

    func testUnpackMapFromFullArray() throws {
        let original = Map(dictionary: ["key": "value"])
        let bytes = try original.pack()

        let unpacked = try Map.unpack(bytes)
        XCTAssertEqual(unpacked.dictionary["key"] as? String, "value")
    }

    // MARK: - PackStreamMarker Tests

    func testPackStreamMarkerTypeOfNull() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xC0), .null)
    }

    func testPackStreamMarkerTypeOfTrue() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xC3), .boolean)
    }

    func testPackStreamMarkerTypeOfFalse() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xC2), .boolean)
    }

    func testPackStreamMarkerTypeOfInt8() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xC8), .integer)
    }

    func testPackStreamMarkerTypeOfInt16() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xC9), .integer)
    }

    func testPackStreamMarkerTypeOfInt32() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xCA), .integer)
    }

    func testPackStreamMarkerTypeOfInt64() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xCB), .integer)
    }

    func testPackStreamMarkerTypeOfFloat64() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xC1), .float)
    }

    func testPackStreamMarkerTypeOfTinyInt() {
        // Values 0-127 are tiny ints
        XCTAssertEqual(PackStreamMarker.typeOf(0x00), .integer)
        XCTAssertEqual(PackStreamMarker.typeOf(0x7F), .integer)
        // Values -16 to -1 (0xF0-0xFF) are also tiny ints
        XCTAssertEqual(PackStreamMarker.typeOf(0xF0), .integer)
        XCTAssertEqual(PackStreamMarker.typeOf(0xFF), .integer)
    }

    func testPackStreamMarkerTypeOfTinyString() {
        XCTAssertEqual(PackStreamMarker.typeOf(0x80), .string)
        XCTAssertEqual(PackStreamMarker.typeOf(0x8F), .string)
    }

    func testPackStreamMarkerTypeOfString8() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xD0), .string)
    }

    func testPackStreamMarkerTypeOfString16() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xD1), .string)
    }

    func testPackStreamMarkerTypeOfString32() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xD2), .string)
    }

    func testPackStreamMarkerTypeOfTinyList() {
        XCTAssertEqual(PackStreamMarker.typeOf(0x90), .list)
        XCTAssertEqual(PackStreamMarker.typeOf(0x9F), .list)
    }

    func testPackStreamMarkerTypeOfList8() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xD4), .list)
    }

    func testPackStreamMarkerTypeOfTinyMap() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xA0), .map)
        XCTAssertEqual(PackStreamMarker.typeOf(0xAF), .map)
    }

    func testPackStreamMarkerTypeOfMap8() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xD8), .map)
    }

    func testPackStreamMarkerTypeOfTinyStruct() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xB0), .structure)
        XCTAssertEqual(PackStreamMarker.typeOf(0xBF), .structure)
    }

    func testPackStreamMarkerTypeOfStruct8() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xDC), .structure)
    }

    func testPackStreamMarkerTypeOfStruct16() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xDD), .structure)
    }

    func testPackStreamMarkerTypeOfBytes8() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xCC), .bytes)
    }

    func testPackStreamMarkerTypeOfBytes16() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xCD), .bytes)
    }

    func testPackStreamMarkerTypeOfBytes32() {
        XCTAssertEqual(PackStreamMarker.typeOf(0xCE), .bytes)
    }

    // MARK: - PackStreamMarker Constants

    func testPackStreamMarkerConstants() {
        XCTAssertEqual(PackStreamMarker.null, 0xC0)
        XCTAssertEqual(PackStreamMarker.false, 0xC2)
        XCTAssertEqual(PackStreamMarker.true, 0xC3)
        XCTAssertEqual(PackStreamMarker.int8, 0xC8)
        XCTAssertEqual(PackStreamMarker.int16, 0xC9)
        XCTAssertEqual(PackStreamMarker.int32, 0xCA)
        XCTAssertEqual(PackStreamMarker.int64, 0xCB)
        XCTAssertEqual(PackStreamMarker.float64, 0xC1)
    }

    // MARK: - Error Types

    func testPackErrorTypes() {
        let error1 = PackError.notPackable
        let error2 = PackError.valueTooLarge

        XCTAssertNotNil(error1)
        XCTAssertNotNil(error2)
    }

    func testUnpackErrorTypes() {
        let errors: [UnpackError] = [
            .incorrectNumberOfBytes,
            .incorrectValue,
            .unexpectedByteMarker,
            .notImplementedYet,
            .bufferUnderflow
        ]

        for error in errors {
            XCTAssertNotNil(error)
        }
    }

    func testPackStreamErrorTypes() {
        let error1 = PackStreamError.notPossible
        let error2 = PackStreamError.invalidStructureSignature

        XCTAssertNotNil(error1)
        XCTAssertNotNil(error2)
    }

    // MARK: - PackStreamType Enum

    func testPackStreamTypeEnum() {
        let types: [PackStreamType] = [
            .null, .boolean, .integer, .float, .bytes, .string, .list, .map, .structure
        ]

        XCTAssertEqual(types.count, 9)
    }

    // MARK: - allTests for Linux

    static var allTests: [(String, (PackProtocolTests) -> () throws -> Void)] {
        return [
            ("testIntValueFromInt8", testIntValueFromInt8),
            ("testIntValueFromInt16", testIntValueFromInt16),
            ("testIntValueFromInt32", testIntValueFromInt32),
            ("testIntValueFromInt64", testIntValueFromInt64),
            ("testIntValueFromNegativeInt64", testIntValueFromNegativeInt64),
            ("testIntValueFromNonInteger", testIntValueFromNonInteger),
            ("testIntValueFromDouble", testIntValueFromDouble),
            ("testIntValueFromBool", testIntValueFromBool),
            ("testUintValueFromPositiveInt8", testUintValueFromPositiveInt8),
            ("testUintValueFromNegativeInt8", testUintValueFromNegativeInt8),
            ("testUintValueFromLargePositiveInt64", testUintValueFromLargePositiveInt64),
            ("testUintValueFromZero", testUintValueFromZero),
            ("testUintValueFromPositiveInt64", testUintValueFromPositiveInt64),
            ("testUintValueFromNegativeInt64", testUintValueFromNegativeInt64),
            ("testUintValueFromString", testUintValueFromString),
            ("testIntInitFromUInt8", testIntInitFromUInt8),
            ("testIntInitFromInt64", testIntInitFromInt64),
            ("testIntInitFromNegativeReturnsNil", testIntInitFromNegativeReturnsNil),
            ("testPackIntoByteBuf", testPackIntoByteBuf),
            ("testPackStringIntoByteBuffer", testPackStringIntoByteBuffer),
            ("testPackListIntoByteBuffer", testPackListIntoByteBuffer),
            ("testPackMapIntoByteBuffer", testPackMapIntoByteBuffer),
            ("testPackStructureIntoByteBuffer", testPackStructureIntoByteBuffer),
            ("testPackNullIntoByteBuffer", testPackNullIntoByteBuffer),
            ("testPackBoolIntoByteBuffer", testPackBoolIntoByteBuffer),
            ("testPackDoubleIntoByteBuffer", testPackDoubleIntoByteBuffer),
            ("testUnpackInt8FromFullArray", testUnpackInt8FromFullArray),
            ("testUnpackStringFromFullArray", testUnpackStringFromFullArray),
            ("testUnpackListFromFullArray", testUnpackListFromFullArray),
            ("testUnpackMapFromFullArray", testUnpackMapFromFullArray),
            ("testPackStreamMarkerTypeOfNull", testPackStreamMarkerTypeOfNull),
            ("testPackStreamMarkerTypeOfTrue", testPackStreamMarkerTypeOfTrue),
            ("testPackStreamMarkerTypeOfFalse", testPackStreamMarkerTypeOfFalse),
            ("testPackStreamMarkerTypeOfInt8", testPackStreamMarkerTypeOfInt8),
            ("testPackStreamMarkerTypeOfInt16", testPackStreamMarkerTypeOfInt16),
            ("testPackStreamMarkerTypeOfInt32", testPackStreamMarkerTypeOfInt32),
            ("testPackStreamMarkerTypeOfInt64", testPackStreamMarkerTypeOfInt64),
            ("testPackStreamMarkerTypeOfFloat64", testPackStreamMarkerTypeOfFloat64),
            ("testPackStreamMarkerTypeOfTinyInt", testPackStreamMarkerTypeOfTinyInt),
            ("testPackStreamMarkerTypeOfTinyString", testPackStreamMarkerTypeOfTinyString),
            ("testPackStreamMarkerTypeOfString8", testPackStreamMarkerTypeOfString8),
            ("testPackStreamMarkerTypeOfString16", testPackStreamMarkerTypeOfString16),
            ("testPackStreamMarkerTypeOfString32", testPackStreamMarkerTypeOfString32),
            ("testPackStreamMarkerTypeOfTinyList", testPackStreamMarkerTypeOfTinyList),
            ("testPackStreamMarkerTypeOfList8", testPackStreamMarkerTypeOfList8),
            ("testPackStreamMarkerTypeOfTinyMap", testPackStreamMarkerTypeOfTinyMap),
            ("testPackStreamMarkerTypeOfMap8", testPackStreamMarkerTypeOfMap8),
            ("testPackStreamMarkerTypeOfTinyStruct", testPackStreamMarkerTypeOfTinyStruct),
            ("testPackStreamMarkerTypeOfStruct8", testPackStreamMarkerTypeOfStruct8),
            ("testPackStreamMarkerTypeOfStruct16", testPackStreamMarkerTypeOfStruct16),
            ("testPackStreamMarkerTypeOfBytes8", testPackStreamMarkerTypeOfBytes8),
            ("testPackStreamMarkerTypeOfBytes16", testPackStreamMarkerTypeOfBytes16),
            ("testPackStreamMarkerTypeOfBytes32", testPackStreamMarkerTypeOfBytes32),
            ("testPackStreamMarkerConstants", testPackStreamMarkerConstants),
            ("testPackErrorTypes", testPackErrorTypes),
            ("testUnpackErrorTypes", testUnpackErrorTypes),
            ("testPackStreamErrorTypes", testPackStreamErrorTypes),
            ("testPackStreamTypeEnum", testPackStreamTypeEnum),
        ]
    }
}
