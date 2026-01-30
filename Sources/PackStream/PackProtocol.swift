import Foundation
import NIOCore

// MARK: - Core Types

public typealias Byte = UInt8

// MARK: - Errors

/// Errors that can occur during packing
public enum PackError: Error, Sendable {
    case notPackable
    case valueTooLarge
}

/// Errors that can occur during unpacking
public enum UnpackError: Error, Sendable {
    case incorrectNumberOfBytes
    case incorrectValue
    case unexpectedByteMarker
    case notImplementedYet
    case bufferUnderflow
}

/// General PackStream protocol errors
public enum PackStreamError: Error, Sendable {
    case notPossible
    case invalidStructureSignature
}

// MARK: - PackStream Protocol

/// Protocol for types that can be packed and unpacked using PackStream format.
///
/// PackStream is a binary presentation format for the exchange of richly-typed data.
/// It supports: Null, Boolean, Integer, Float, Bytes, String, List, Dictionary, and Structure.
public protocol PackProtocol: Sendable {
    /// Pack this value into PackStream bytes
    func pack() throws -> [Byte]

    /// Unpack PackStream bytes into this type
    static func unpack(_ bytes: ArraySlice<Byte>) throws -> Self
}

// MARK: - ByteBuffer Extensions for PackStream

public extension PackProtocol {
    /// Unpack from a full byte array
    static func unpack(_ bytes: [Byte]) throws -> Self {
        return try unpack(bytes[0..<bytes.count])
    }

    /// Pack into a ByteBuffer
    func pack(into buffer: inout ByteBuffer) throws {
        let bytes = try pack()
        buffer.writeBytes(bytes)
    }
}

// MARK: - Integer Conversion Helpers

public extension PackProtocol {
    /// Convert to Int64 if this value represents an integer
    func intValue() -> Int64? {
        switch self {
        case let i as Int8: return Int64(i)
        case let i as Int16: return Int64(i)
        case let i as Int32: return Int64(i)
        case let i as Int64: return i
        case let i as UInt8: return Int64(i)
        case let i as UInt16: return Int64(i)
        case let i as UInt32: return Int64(i)
        case let i as Int: return Int64(i)
        default: return nil
        }
    }

    /// Convert to UInt64 if this value represents a non-negative integer
    func uintValue() -> UInt64? {
        if let i = self as? UInt64 {
            return i
        }
        if let i = intValue(), i >= 0 {
            return UInt64(i)
        }
        return nil
    }

    /// Convert to UInt64, legacy method for backwards compatibility
    @available(*, deprecated, renamed: "uintValue()")
    func asUInt64() -> UInt64? {
        return uintValue()
    }
}

// MARK: - Int Initializer Extension

public extension Int {
    init?(_ value: PackProtocol) {
        if let n = value.uintValue() {
            self.init(n)
        } else {
            return nil
        }
    }
}

// MARK: - PackStream Marker Constants

/// Constants for PackStream format markers
public enum PackStreamMarker {
    // Null
    public static let null: Byte = 0xC0

    // Boolean
    public static let `false`: Byte = 0xC2
    public static let `true`: Byte = 0xC3

    // Integer markers
    public static let int8: Byte = 0xC8
    public static let int16: Byte = 0xC9
    public static let int32: Byte = 0xCA
    public static let int64: Byte = 0xCB

    // Float
    public static let float64: Byte = 0xC1

    // Bytes markers
    public static let bytes8: Byte = 0xCC
    public static let bytes16: Byte = 0xCD
    public static let bytes32: Byte = 0xCE

    // String markers
    public static let tinyStringMin: Byte = 0x80
    public static let tinyStringMax: Byte = 0x8F
    public static let string8: Byte = 0xD0
    public static let string16: Byte = 0xD1
    public static let string32: Byte = 0xD2

    // List markers
    public static let tinyListMin: Byte = 0x90
    public static let tinyListMax: Byte = 0x9F
    public static let list8: Byte = 0xD4
    public static let list16: Byte = 0xD5
    public static let list32: Byte = 0xD6

    // Map markers
    public static let tinyMapMin: Byte = 0xA0
    public static let tinyMapMax: Byte = 0xAF
    public static let map8: Byte = 0xD8
    public static let map16: Byte = 0xD9
    public static let map32: Byte = 0xDA

    // Structure markers
    public static let tinyStructMin: Byte = 0xB0
    public static let tinyStructMax: Byte = 0xBF
    public static let struct8: Byte = 0xDC
    public static let struct16: Byte = 0xDD

    /// Determine the type from a marker byte
    public static func typeOf(_ marker: Byte) -> PackStreamType {
        // Check for tiny int (values -16 to 127 encoded directly)
        if marker <= 0x7F || marker >= 0xF0 {
            return .integer
        }

        switch marker {
        case null:
            return .null
        case `false`, `true`:
            return .boolean
        case int8, int16, int32, int64:
            return .integer
        case float64:
            return .float
        case bytes8, bytes16, bytes32:
            return .bytes
        case tinyStringMin...tinyStringMax, string8, string16, string32:
            return .string
        case tinyListMin...tinyListMax, list8, list16, list32:
            return .list
        case tinyMapMin...tinyMapMax, map8, map16, map32:
            return .map
        case tinyStructMin...tinyStructMax, struct8, struct16:
            return .structure
        default:
            return .null // Unknown marker, treat as null
        }
    }
}

/// Types supported by PackStream
public enum PackStreamType: Sendable {
    case null
    case boolean
    case integer
    case float
    case bytes
    case string
    case list
    case map
    case structure
}
