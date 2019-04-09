import Foundation

public typealias Byte = UInt8

public protocol PackProtocol {

    func pack() throws -> [Byte]
    static func unpack(_ bytes: ArraySlice<Byte>) throws -> Self
}

public enum PackError: Error {
    case notPackable
}

public enum UnpackError: Error {
    case incorrectNumberOfBytes
    case incorrectValue
    case unexpectedByteMarker
    case notImplementedYet
}

public enum PackProtocolError: Error {
    case notPossible
}

public extension PackProtocol {

    static func unpack(_ bytes: [Byte]) throws -> Self {
        return try unpack(bytes[0..<bytes.count])
    }

    func asUInt64() -> UInt64? {

        if let i = self as? UInt64 {
            return i
        }

        if let i = self as? UInt32 {
            return UInt64(i)
        }

        if let i = self as? UInt16 {
            return UInt64(i)
        }

        if let i = self as? UInt8 {
            return UInt64(i)
        }

        if let i = self as? Int64 {
            if i < 0 {
                return nil
            } else {
                return UInt64(i)
            }
        }

        if let i = self as? Int32 {
            if i < 0 {
                return nil
            } else {
                return UInt64(i)
            }
        }

        if let i = self as? Int16 {
            if i < 0 {
                return nil
            } else {
                return UInt64(i)
            }
        }

        if let i = self as? Int8 {
            if i < 0 {
                return nil
            } else {
                return UInt64(i)
            }
        }

        return nil
    }
}

public extension Int {
    init?(_ value: PackProtocol) {
        if let n = value.asUInt64() {
            self.init(n)
        } else {
            return nil
        }
    }
}
