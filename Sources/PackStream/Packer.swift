import Foundation

// MARK: - Packer

/// Utility class for packing and unpacking PackStream values
public final class Packer: Sendable {

    /// Representation types for PackStream values
    public enum Representations: Sendable {
        case null
        case bool
        case int8small
        case int8
        case int16
        case int32
        case int64
        case float
        case string
        case list
        case map
        case structure

        /// Determine the type from a marker byte
        public static func typeFrom(representation marker: Byte) -> Representations {
            // Check for tiny int range first (includes negative tiny ints 0xF0-0xFF)
            if marker <= 0x7F {
                return .int8small
            }
            if marker >= 0xF0 {
                return .int8small
            }

            switch marker {
            case PackStreamMarker.null:
                return .null
            case PackStreamMarker.false, PackStreamMarker.true:
                return .bool
            case PackStreamMarker.int8:
                return .int8
            case PackStreamMarker.int16:
                return .int16
            case PackStreamMarker.int32:
                return .int32
            case PackStreamMarker.int64:
                return .int64
            case PackStreamMarker.float64:
                return .float
            case PackStreamMarker.tinyStringMin...PackStreamMarker.tinyStringMax,
                 PackStreamMarker.string8,
                 PackStreamMarker.string16,
                 PackStreamMarker.string32:
                return .string
            case PackStreamMarker.tinyListMin...PackStreamMarker.tinyListMax,
                 PackStreamMarker.list8,
                 PackStreamMarker.list16,
                 PackStreamMarker.list32:
                return .list
            case PackStreamMarker.tinyMapMin...PackStreamMarker.tinyMapMax,
                 PackStreamMarker.map8,
                 PackStreamMarker.map16,
                 PackStreamMarker.map32:
                return .map
            case PackStreamMarker.tinyStructMin...PackStreamMarker.tinyStructMax,
                 PackStreamMarker.struct8,
                 PackStreamMarker.struct16:
                return .structure
            default:
                return .null
            }
        }
    }

    public init() {}

    /// Pack multiple values into bytes
    public func pack(_ values: [PackProtocol]) throws -> [Byte] {
        try values.flatMap { try $0.pack() }
    }

    /// Unpack bytes into PackStream values
    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> [PackProtocol] {
        var results: [PackProtocol] = []
        var position = bytes.startIndex

        while position < bytes.endIndex {
            let remaining = bytes[position...]

            let (value, consumed) = try unpackOne(remaining)
            results.append(value)
            position += consumed
        }

        return results
    }

    /// Unpack a single value and return the value plus number of bytes consumed
    public static func unpackOne(_ bytes: ArraySlice<Byte>) throws -> (PackProtocol, Int) {
        guard let marker = bytes.first else {
            throw UnpackError.bufferUnderflow
        }

        let type = Representations.typeFrom(representation: marker)

        switch type {
        case .null:
            return (Null(), 1)

        case .bool:
            let value = try Bool.unpack(bytes[bytes.startIndex..<(bytes.startIndex + 1)])
            return (value, 1)

        case .int8small:
            let value = try Int8.unpack(bytes[bytes.startIndex..<(bytes.startIndex + 1)])
            return (value, 1)

        case .int8:
            guard bytes.count >= 2 else { throw UnpackError.bufferUnderflow }
            let value = try Int8.unpack(bytes[bytes.startIndex..<(bytes.startIndex + 2)])
            return (value, 2)

        case .int16:
            guard bytes.count >= 3 else { throw UnpackError.bufferUnderflow }
            let value = try Int16.unpack(bytes[bytes.startIndex..<(bytes.startIndex + 3)])
            return (value, 3)

        case .int32:
            guard bytes.count >= 5 else { throw UnpackError.bufferUnderflow }
            let value = try Int32.unpack(bytes[bytes.startIndex..<(bytes.startIndex + 5)])
            return (value, 5)

        case .int64:
            guard bytes.count >= 9 else { throw UnpackError.bufferUnderflow }
            let value = try Int64.unpack(bytes[bytes.startIndex..<(bytes.startIndex + 9)])
            return (value, 9)

        case .float:
            guard bytes.count >= 9 else { throw UnpackError.bufferUnderflow }
            let value = try Double.unpack(bytes[bytes.startIndex..<(bytes.startIndex + 9)])
            return (value, 9)

        case .string:
            let markerSize = try String.markerSizeFor(bytes: bytes)
            let dataSize = try String.sizeFor(bytes: bytes)
            let totalSize = markerSize + dataSize
            guard bytes.count >= totalSize else { throw UnpackError.bufferUnderflow }
            let value = try String.unpack(bytes[bytes.startIndex..<(bytes.startIndex + totalSize)])
            return (value, totalSize)

        case .list:
            let size = try List.sizeFor(bytes: bytes)
            guard bytes.count >= size else { throw UnpackError.bufferUnderflow }
            let value = try List.unpack(bytes[bytes.startIndex..<(bytes.startIndex + size)])
            return (value, size)

        case .map:
            let size = try Map.sizeFor(bytes: bytes)
            guard bytes.count >= size else { throw UnpackError.bufferUnderflow }
            let value = try Map.unpack(bytes[bytes.startIndex..<(bytes.startIndex + size)])
            return (value, size)

        case .structure:
            let size = try Structure.sizeFor(bytes: bytes)
            guard bytes.count >= size else { throw UnpackError.bufferUnderflow }
            let value = try Structure.unpack(bytes[bytes.startIndex..<(bytes.startIndex + size)])
            return (value, size)
        }
    }
}
