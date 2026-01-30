import Foundation

// MARK: - String PackProtocol

extension String: PackProtocol {
    public func pack() throws -> [Byte] {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else {
            throw PackError.notPackable
        }

        let bytes = Array(data)
        let length = bytes.count

        switch length {
        case 0:
            return [PackStreamMarker.tinyStringMin]
        case 1...15:
            // Tiny string: marker encodes length
            return [PackStreamMarker.tinyStringMin + Byte(length)] + bytes
        case 16...255:
            // String8: marker + 1-byte length + data
            return [PackStreamMarker.string8, Byte(length)] + bytes
        case 256...65535:
            // String16: marker + 2-byte length + data
            let sizeBytes = try UInt16(length).pack()
            return [PackStreamMarker.string16] + sizeBytes + bytes
        case 65536...Int(UInt32.max):
            // String32: marker + 4-byte length + data
            let sizeBytes = try UInt32(length).pack()
            return [PackStreamMarker.string32] + sizeBytes + bytes
        default:
            throw PackError.valueTooLarge
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> String {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case PackStreamMarker.tinyStringMin...PackStreamMarker.tinyStringMax:
            return try unpackTinyString(bytes)
        case PackStreamMarker.string8:
            return try unpackString8(bytes)
        case PackStreamMarker.string16:
            return try unpackString16(bytes)
        case PackStreamMarker.string32:
            return try unpackString32(bytes)
        default:
            throw UnpackError.unexpectedByteMarker
        }
    }

    // MARK: - Size Calculation Helpers

    static func markerSizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case PackStreamMarker.tinyStringMin...PackStreamMarker.tinyStringMax:
            return 1
        case PackStreamMarker.string8:
            return 2
        case PackStreamMarker.string16:
            return 3
        case PackStreamMarker.string32:
            return 5
        default:
            throw UnpackError.unexpectedByteMarker
        }
    }

    static func sizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case PackStreamMarker.tinyStringMin...PackStreamMarker.tinyStringMax:
            return Int(firstByte) - Int(PackStreamMarker.tinyStringMin)
        case PackStreamMarker.string8:
            guard bytes.count >= 2 else { throw UnpackError.incorrectNumberOfBytes }
            return Int(bytes[bytes.startIndex + 1])
        case PackStreamMarker.string16:
            guard bytes.count >= 3 else { throw UnpackError.incorrectNumberOfBytes }
            return Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))
        case PackStreamMarker.string32:
            guard bytes.count >= 5 else { throw UnpackError.incorrectNumberOfBytes }
            return Int(try UInt32.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 5)]))
        default:
            throw UnpackError.unexpectedByteMarker
        }
    }

    // MARK: - Private Unpack Helpers

    private static func unpackTinyString(_ bytes: ArraySlice<Byte>) throws -> String {
        let size = Int(bytes[bytes.startIndex] - PackStreamMarker.tinyStringMin)

        guard bytes.count == size + 1 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if size == 0 {
            return ""
        }

        let start = bytes.startIndex + 1
        return try bytesToString(Array(bytes[start..<bytes.endIndex]))
    }

    private static func unpackString8(_ bytes: ArraySlice<Byte>) throws -> String {
        guard bytes.count >= 2 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let size = Int(bytes[bytes.startIndex + 1])

        guard bytes.count == size + 2 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if size == 0 {
            return ""
        }

        return try bytesToString(Array(bytes[(bytes.startIndex + 2)..<bytes.endIndex]))
    }

    private static func unpackString16(_ bytes: ArraySlice<Byte>) throws -> String {
        guard bytes.count >= 3 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let size = Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))

        guard bytes.count == size + 3 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if size == 0 {
            return ""
        }

        return try bytesToString(Array(bytes[(bytes.startIndex + 3)..<bytes.endIndex]))
    }

    private static func unpackString32(_ bytes: ArraySlice<Byte>) throws -> String {
        guard bytes.count >= 5 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let size = Int(try UInt32.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 5)]))

        guard bytes.count == size + 5 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if size == 0 {
            return ""
        }

        return try bytesToString(Array(bytes[(bytes.startIndex + 5)..<bytes.endIndex]))
    }

    private static func bytesToString(_ bytes: [Byte]) throws -> String {
        let data = Data(bytes)
        guard let string = String(data: data, encoding: .utf8) else {
            throw UnpackError.incorrectValue
        }
        return string
    }
}
