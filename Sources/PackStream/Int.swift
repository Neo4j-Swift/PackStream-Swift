import Foundation

#if swift(>=4.0)
#elseif swift(>=3.0)
typealias BinaryInteger = Integer
#endif

extension PackProtocol {
    public func intValue() -> Int64? {
        if let i = self as? Int8 {
            return Int64(i)
        } else if let i = self as? Int16 {
            return Int64(i)
        } else if let i = self as? Int32 {
            return Int64(i)
        } else if let i = self as? Int64 {
            return i
        } else if let i = self as? UInt8 {
            return Int64(i)
        } else if let i = self as? UInt16 {
            return Int64(i)
        } else if let i = self as? UInt32 {
            return Int64(i)
        }

        return nil
    }

    public func uintValue() -> UInt64? {
        if let i = self as? UInt64 {
            return i
        } else if let i = self.intValue() {
            if i < 0 {
                return nil
            } else {
                return UInt64(i)
            }
        }

        return nil
    }
}

extension Int8: PackProtocol {
    struct Constants {
        static let byteMarker: Byte = 0xC8
    }

    public func pack() throws -> [Byte] {

        switch self {
        case -0x10 ... 0x7F:
            return packInt8(withByteMarker: false)
        default:
            return packInt8(withByteMarker: true)
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int8 {

        switch bytes.count {
        case 1:
            return try unpackInt8(bytes, withMarker: false)
        case 2:
            return try unpackInt8(bytes, withMarker: true)
        default:
            throw UnpackError.incorrectNumberOfBytes
        }
    }

    private func packInt8(withByteMarker: Bool) -> [Byte] {

        if withByteMarker == true {
            return [ Constants.byteMarker, Byte(bitPattern: self) ]
        } else {
            return [ Byte(bitPattern: self) ]
        }
    }

    private static func unpackInt8(_ bytes: ArraySlice<Byte>, withMarker: Bool) throws -> Int8 {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if withMarker == false {
            return Int8(bitPattern: firstByte)

        } else {
            if firstByte != Constants.byteMarker {
                throw UnpackError.unexpectedByteMarker
            }

            if bytes.count != 2 {
                throw UnpackError.incorrectNumberOfBytes
            }

            let byte: Byte = bytes[bytes.startIndex + 1]
            return Int8(bitPattern: byte)
        }
    }

}

extension Int16: PackProtocol {
    struct Constants {
        static let byteMarker: Byte = 0xC9
    }

    public func pack() throws -> [Byte] {

        let nv: Int16 = Int16(self).bigEndian
        let uNv = UInt16(bitPattern: nv)

        let second = UInt8(uNv >> 8)
        let first = UInt8(uNv & 0x00ff)

        return [ Constants.byteMarker, first, second ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int16 {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if firstByte != Constants.byteMarker {
            throw UnpackError.unexpectedByteMarker
        }

        if bytes.count != 3 {
            throw UnpackError.incorrectNumberOfBytes
        }

        let data = NSData(bytes: Array(bytes), length: 3)
        let i: Int16 = Int.readInteger(data: data, start: 1)
        return Int16(bigEndian: i)
    }

}

extension UInt8 {

    func pack() throws -> [Byte] {
        return [ self ]
    }

    static func unpack(_ bytes: ArraySlice<Byte>) throws -> UInt8 {
        if bytes.count != 1 {
            throw UnpackError.incorrectNumberOfBytes
        }

        return bytes[bytes.startIndex]
    }
}

extension UInt16 {

    public func pack() throws -> [Byte] {
        var i: UInt16 = UInt16(self).bigEndian
        let data = NSData(bytes: &i, length: MemoryLayout<UInt16>.size)
        let length = data.length

        var bytes = [Byte](repeating: 0, count: length)
        data.getBytes(&bytes, length: length)
        return bytes
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> UInt16 {

        if bytes.count != 2 {
            throw UnpackError.incorrectNumberOfBytes
        }

        let data = NSData(bytes: Array(bytes), length: 2)
        let i: UInt16 = Int.readInteger(data: data, start: 0)
        return UInt16(bigEndian: i)
    }

}

extension UInt32 {

    func pack() throws -> [Byte] {
        var i: UInt32 = UInt32(self).bigEndian
        let data = NSData(bytes: &i, length: MemoryLayout<UInt32>.size)
        let length = data.length

        var bytes = [Byte](repeating: 0, count: length)
        data.getBytes(&bytes, length: length)
        return bytes
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> UInt32 {

        if bytes.count != 4 {
            throw UnpackError.incorrectNumberOfBytes
        }

        let data = NSData(bytes: Array(bytes), length: 4)
        let i: UInt32 = Int.readInteger(data: data, start: 0)
        return UInt32(bigEndian: i)
    }

}

extension Int32: PackProtocol {
    struct Constants {
        static let byteMarker: Byte = 0xCA
    }

    public func pack() throws -> [Byte] {
        var i: Int32 = Int32(self).bigEndian
        let data = NSData(bytes: &i, length: MemoryLayout<Int32>.size)
        let length = data.length

        var bytes = [Byte](repeating: 0, count: length)
        data.getBytes(&bytes, length: length)
        return [Constants.byteMarker] + bytes
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int32 {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if firstByte != Constants.byteMarker {
            throw UnpackError.unexpectedByteMarker
        }

        if bytes.count != 5 {
            throw UnpackError.incorrectNumberOfBytes
        }

        let data = NSData(bytes: Array(bytes), length: 5)
        let i: Int32 = Int.readInteger(data: data, start: 1)
        return Int32(bigEndian: i)
    }
}

extension Int64: PackProtocol {
    struct Constants {
        static let byteMarker: Byte = 0xCB
    }

    public func pack() throws -> [Byte] {

        var i: Int64 = Int64(self).bigEndian
        let data = NSData(bytes: &i, length: MemoryLayout<Int64>.size)
        let length = data.length

        var bytes = [Byte](repeating: 0, count: length)
        data.getBytes(&bytes, length: length)
        return [Constants.byteMarker] + bytes
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int64 {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if firstByte != Constants.byteMarker {
            throw UnpackError.unexpectedByteMarker
        }

        if bytes.count != 9 {
            throw UnpackError.incorrectNumberOfBytes
        }

        let data = NSData(bytes: Array(bytes), length: 9)
        let i: Int64 = Int.readInteger(data: data, start: 1)
        return Int64(bigEndian: i)
    }

}

extension Int: PackProtocol {

    public func pack() throws -> [Byte] {

        #if __LP64__ || os(Linux)

            switch self {
            case -0x10 ... 0x7F:
                return try Int8(self).pack()
            case -0x7F ..< -0x7F:
                return try Int8(self).pack()
            case -0x8000 ..< 0x8000:
                return try Int16(self).pack()
            case -0x80000000 ... 0x7fffffff:
                return try Int32(self).pack()
            case -0x8000000000000000 ... (0x800000000000000 - 1):
                return try Int64(self).pack()
            default:
                throw PackError.notPackable
            }
        #else
            switch self {
            case -0x10 ... 0x7F:
                return try Int8(self).pack()
            case -0x7F ..< -0x7F:
                return try Int8(self).pack()
            case -0x8000 ..< 0x8000:
                return try Int16(self).pack()
            case -0x80000000 ... 0x7fffffff:
                return try Int32(self).pack()
            default:
                throw PackError.notPackable
            }
        #endif
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Int {

        switch bytes.count {
        case 1:
            return Int(try Int8.unpack(bytes))
        case 2:
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

    static func readInteger<T: BinaryInteger>(data: NSData, start: Int) -> T {
        var d: T = 0 as T
        data.getBytes(&d, range: NSRange(location: start, length: MemoryLayout<T>.size))
        return d
    }

}
