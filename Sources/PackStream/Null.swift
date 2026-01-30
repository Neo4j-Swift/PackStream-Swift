import Foundation

// MARK: - Null Type

/// Represents a PackStream null value
public struct Null: Sendable, Hashable {
    public init() {}
}

// MARK: - PackProtocol Conformance

extension Null: PackProtocol {
    public func pack() throws -> [Byte] {
        return [PackStreamMarker.null]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Null {
        guard bytes.count == 1 else {
            throw UnpackError.incorrectNumberOfBytes
        }

        guard bytes[bytes.startIndex] == PackStreamMarker.null else {
            throw UnpackError.unexpectedByteMarker
        }

        return Null()
    }
}
