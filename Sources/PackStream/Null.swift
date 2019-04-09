import Foundation

public struct Null {
    public init() {}
}

extension Null : PackProtocol {

    struct Constants {
        static let byteMarker: Byte = 0xC0
    }

    public func pack() throws -> [Byte] {
        return [ Constants.byteMarker ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Null {
        if bytes.count != 1 {
            throw UnpackError.incorrectNumberOfBytes
        }

        if bytes[bytes.startIndex] != Constants.byteMarker {
            throw UnpackError.unexpectedByteMarker
        }

        return Null()
    }

}
