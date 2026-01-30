import Foundation

// MARK: - Int8 PackProtocol

extension Int8: PackProtocol {
    public func pack() throws -> [Byte] {
        // TINY_INT: values from -16 to 127 are encoded directly as a single byte
        if self >= -16 && self <= 127 {
            return [Byte(bitPattern: self)]
        }
        // INT_8: marker + 8-bit signed integer
        return [PackStreamMarker.int8, Byte(bitPattern: self)]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int8 {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch bytes.count {
        case 1:
            // Tiny int encoded directly
            return Int8(bitPattern: firstByte)
        case 2:
            guard firstByte == PackStreamMarker.int8 else {
                throw UnpackError.unexpectedByteMarker
            }
            return Int8(bitPattern: bytes[bytes.startIndex + 1])
        default:
            throw UnpackError.incorrectNumberOfBytes
        }
    }
}

// MARK: - Int16 PackProtocol

extension Int16: PackProtocol {
    public func pack() throws -> [Byte] {
        // Write in big-endian (network) byte order
        let unsigned = UInt16(bitPattern: self)
        return [
            PackStreamMarker.int16,
            Byte((unsigned >> 8) & 0xFF),
            Byte(unsigned & 0xFF)
        ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int16 {
        guard bytes.count == 3, bytes.first == PackStreamMarker.int16 else {
            if bytes.count != 3 {
                throw UnpackError.incorrectNumberOfBytes
            }
            throw UnpackError.unexpectedByteMarker
        }

        // Read big-endian bytes
        let high = UInt16(bytes[bytes.startIndex + 1]) << 8
        let low = UInt16(bytes[bytes.startIndex + 2])
        return Int16(bitPattern: high | low)
    }
}

// MARK: - Int32 PackProtocol

extension Int32: PackProtocol {
    public func pack() throws -> [Byte] {
        // Write in big-endian (network) byte order
        let unsigned = UInt32(bitPattern: self)
        return [
            PackStreamMarker.int32,
            Byte((unsigned >> 24) & 0xFF),
            Byte((unsigned >> 16) & 0xFF),
            Byte((unsigned >> 8) & 0xFF),
            Byte(unsigned & 0xFF)
        ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int32 {
        guard bytes.count == 5, bytes.first == PackStreamMarker.int32 else {
            if bytes.count != 5 {
                throw UnpackError.incorrectNumberOfBytes
            }
            throw UnpackError.unexpectedByteMarker
        }

        // Read big-endian bytes
        let b0 = UInt32(bytes[bytes.startIndex + 1]) << 24
        let b1 = UInt32(bytes[bytes.startIndex + 2]) << 16
        let b2 = UInt32(bytes[bytes.startIndex + 3]) << 8
        let b3 = UInt32(bytes[bytes.startIndex + 4])
        return Int32(bitPattern: b0 | b1 | b2 | b3)
    }
}

// MARK: - Int64 PackProtocol

extension Int64: PackProtocol {
    public func pack() throws -> [Byte] {
        // Write in big-endian (network) byte order
        let unsigned = UInt64(bitPattern: self)
        return [
            PackStreamMarker.int64,
            Byte((unsigned >> 56) & 0xFF),
            Byte((unsigned >> 48) & 0xFF),
            Byte((unsigned >> 40) & 0xFF),
            Byte((unsigned >> 32) & 0xFF),
            Byte((unsigned >> 24) & 0xFF),
            Byte((unsigned >> 16) & 0xFF),
            Byte((unsigned >> 8) & 0xFF),
            Byte(unsigned & 0xFF)
        ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int64 {
        guard bytes.count == 9, bytes.first == PackStreamMarker.int64 else {
            if bytes.count != 9 {
                throw UnpackError.incorrectNumberOfBytes
            }
            throw UnpackError.unexpectedByteMarker
        }

        // Read big-endian bytes
        var value: UInt64 = 0
        for i in 1..<9 {
            value = (value << 8) | UInt64(bytes[bytes.startIndex + i])
        }
        return Int64(bitPattern: value)
    }
}

// MARK: - UInt8 Pack Helpers

extension UInt8 {
    func pack() throws -> [Byte] {
        return [self]
    }

    static func unpack(_ bytes: ArraySlice<Byte>) throws -> UInt8 {
        guard bytes.count == 1, let byte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }
        return byte
    }
}

// MARK: - UInt16 Pack Helpers

extension UInt16 {
    public func pack() throws -> [Byte] {
        // Write in big-endian (network) byte order
        return [
            Byte((self >> 8) & 0xFF),
            Byte(self & 0xFF)
        ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> UInt16 {
        guard bytes.count == 2 else {
            throw UnpackError.incorrectNumberOfBytes
        }
        // Read big-endian bytes
        let high = UInt16(bytes[bytes.startIndex]) << 8
        let low = UInt16(bytes[bytes.startIndex + 1])
        return high | low
    }
}

// MARK: - UInt32 Pack Helpers

extension UInt32 {
    func pack() throws -> [Byte] {
        // Write in big-endian (network) byte order
        return [
            Byte((self >> 24) & 0xFF),
            Byte((self >> 16) & 0xFF),
            Byte((self >> 8) & 0xFF),
            Byte(self & 0xFF)
        ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> UInt32 {
        guard bytes.count == 4 else {
            throw UnpackError.incorrectNumberOfBytes
        }
        // Read big-endian bytes
        let b0 = UInt32(bytes[bytes.startIndex]) << 24
        let b1 = UInt32(bytes[bytes.startIndex + 1]) << 16
        let b2 = UInt32(bytes[bytes.startIndex + 2]) << 8
        let b3 = UInt32(bytes[bytes.startIndex + 3])
        return b0 | b1 | b2 | b3
    }
}

// MARK: - Int PackProtocol

extension Int: PackProtocol {
    public func pack() throws -> [Byte] {
        // Use the smallest encoding that fits
        switch self {
        case -16...127:
            return try Int8(self).pack()
        case -128..<(-16):
            return try Int8(self).pack()
        case -32768..<32768 where self < -128 || self > 127:
            return try Int16(self).pack()
        case -2147483648...2147483647 where self < -32768 || self > 32767:
            return try Int32(self).pack()
        default:
            return try Int64(self).pack()
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        // Check marker to determine the type
        switch bytes.count {
        case 1:
            // Tiny int
            return Int(Int8(bitPattern: firstByte))
        case 2:
            guard firstByte == PackStreamMarker.int8 else {
                throw UnpackError.unexpectedByteMarker
            }
            return Int(try Int8.unpack(bytes))
        case 3:
            return Int(try Int16.unpack(bytes))
        case 5:
            return Int(try Int32.unpack(bytes))
        case 9:
            return Int(try Int64.unpack(bytes))
        default:
            throw UnpackError.incorrectNumberOfBytes
        }
    }
}
