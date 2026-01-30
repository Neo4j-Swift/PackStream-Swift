import Foundation

// MARK: - Bool PackProtocol

extension Bool: PackProtocol {
    public func pack() throws -> [Byte] {
        return [self ? PackStreamMarker.true : PackStreamMarker.false]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Bool {
        guard bytes.count == 1, let byte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch byte {
        case PackStreamMarker.true:
            return true
        case PackStreamMarker.false:
            return false
        default:
            throw UnpackError.incorrectValue
        }
    }
}
