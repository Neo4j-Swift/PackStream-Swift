import Foundation

extension Bool: PackProtocol {

    struct Constants {
        static let byteForFalse: Byte = 0xC2
        static let byteForTrue: Byte = 0xC3
    }

    public func pack() throws -> [Byte] {
        if self == true {
            return [ Constants.byteForTrue ]
        } else {
            return [ Constants.byteForFalse ]
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Bool {

        guard bytes.count == 1,
              let byte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        if byte == Constants.byteForTrue {
            return true
        }

        if byte == Constants.byteForFalse {
            return false
        }

        throw UnpackError.incorrectValue
    }
}
