import Foundation

// MARK: - Structure Type

/// Represents a PackStream structure (typed container with signature byte)
public struct Structure: Sendable {
    public let signature: UInt8
    public let items: [any PackProtocol]

    public init(signature: UInt8, items: [any PackProtocol] = []) {
        self.signature = signature
        self.items = items
    }
}

// MARK: - PackProtocol Conformance

extension Structure: PackProtocol {
    public func pack() throws -> [Byte] {
        let itemBytes: [Byte] = try items.flatMap { try $0.pack() }
        let count = items.count

        switch count {
        case 0...15:
            return [PackStreamMarker.tinyStructMin + Byte(count), signature] + itemBytes
        case 16...255:
            return [PackStreamMarker.struct8, Byte(count), signature] + itemBytes
        case 256...65535:
            let sizeBytes = try UInt16(count).pack()
            return [PackStreamMarker.struct16] + sizeBytes + [signature] + itemBytes
        default:
            throw PackError.valueTooLarge
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Structure {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let itemCount: Int
        var position = bytes.startIndex

        switch firstByte {
        case PackStreamMarker.tinyStructMin...PackStreamMarker.tinyStructMax:
            itemCount = Int(firstByte - PackStreamMarker.tinyStructMin)
            position += 1
        case PackStreamMarker.struct8:
            guard bytes.count >= 2 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(bytes[bytes.startIndex + 1])
            position += 2
        case PackStreamMarker.struct16:
            guard bytes.count >= 3 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))
            position += 3
        default:
            throw UnpackError.unexpectedByteMarker
        }

        // Read signature byte
        guard position < bytes.endIndex else {
            throw UnpackError.incorrectNumberOfBytes
        }
        let signature = bytes[position]
        position += 1

        // Unpack items
        var items: [any PackProtocol] = []
        items.reserveCapacity(itemCount)

        for _ in 0..<itemCount {
            let remaining = bytes[position...]
            let (item, consumed) = try Packer.unpackOne(remaining)
            items.append(item)
            position += consumed
        }

        return Structure(signature: signature, items: items)
    }

    // MARK: - Size Calculation Helpers

    static func markerSizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case PackStreamMarker.tinyStructMin...PackStreamMarker.tinyStructMax:
            return 1
        case PackStreamMarker.struct8:
            return 2
        case PackStreamMarker.struct16:
            return 3
        default:
            throw UnpackError.unexpectedByteMarker
        }
    }

    static func sizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let itemCount: Int
        var position = bytes.startIndex

        switch firstByte {
        case PackStreamMarker.tinyStructMin...PackStreamMarker.tinyStructMax:
            itemCount = Int(firstByte - PackStreamMarker.tinyStructMin)
            position += 1
        case PackStreamMarker.struct8:
            guard bytes.count >= 2 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(bytes[bytes.startIndex + 1])
            position += 2
        case PackStreamMarker.struct16:
            guard bytes.count >= 3 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))
            position += 3
        default:
            throw UnpackError.unexpectedByteMarker
        }

        // Skip signature byte
        position += 1

        // Skip items
        for _ in 0..<itemCount {
            let remaining = bytes[position...]
            let (_, consumed) = try Packer.unpackOne(remaining)
            position += consumed
        }

        return position - bytes.startIndex
    }
}

// MARK: - Equatable

extension Structure: Equatable {
    public static func == (lhs: Structure, rhs: Structure) -> Bool {
        guard lhs.signature == rhs.signature else {
            return false
        }

        guard lhs.items.count == rhs.items.count else {
            return false
        }

        for i in 0..<lhs.items.count {
            if !packProtocolValuesEqual(lhs.items[i], rhs.items[i]) {
                return false
            }
        }

        return true
    }
}
