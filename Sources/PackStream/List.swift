import Foundation

// MARK: - List Type

/// Represents a PackStream list (ordered collection of values)
public struct List: Sendable {
    public let items: [any PackProtocol]

    public init(items: [any PackProtocol] = []) {
        self.items = items
    }
}

// MARK: - PackProtocol Conformance

extension List: PackProtocol {
    public func pack() throws -> [Byte] {
        let itemBytes: [Byte] = try items.flatMap { try $0.pack() }
        let count = items.count

        switch count {
        case 0:
            return [PackStreamMarker.tinyListMin]
        case 1...15:
            return [PackStreamMarker.tinyListMin + Byte(count)] + itemBytes
        case 16...255:
            return [PackStreamMarker.list8, Byte(count)] + itemBytes
        case 256...65535:
            let sizeBytes = try UInt16(count).pack()
            return [PackStreamMarker.list16] + sizeBytes + itemBytes
        case 65536...Int(UInt32.max):
            let sizeBytes = try UInt32(count).pack()
            return [PackStreamMarker.list32] + sizeBytes + itemBytes
        default:
            throw PackError.valueTooLarge
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> List {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let itemCount: Int
        var position = bytes.startIndex

        switch firstByte {
        case PackStreamMarker.tinyListMin...PackStreamMarker.tinyListMax:
            itemCount = Int(firstByte - PackStreamMarker.tinyListMin)
            position += 1
        case PackStreamMarker.list8:
            guard bytes.count >= 2 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(bytes[bytes.startIndex + 1])
            position += 2
        case PackStreamMarker.list16:
            guard bytes.count >= 3 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))
            position += 3
        case PackStreamMarker.list32:
            guard bytes.count >= 5 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(try UInt32.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 5)]))
            position += 5
        default:
            throw UnpackError.unexpectedByteMarker
        }

        var items: [any PackProtocol] = []
        items.reserveCapacity(itemCount)

        for _ in 0..<itemCount {
            let remaining = bytes[position...]
            let (item, consumed) = try Packer.unpackOne(remaining)
            items.append(item)
            position += consumed
        }

        return List(items: items)
    }

    // MARK: - Size Calculation Helpers

    static func markerSizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case PackStreamMarker.tinyListMin...PackStreamMarker.tinyListMax:
            return 1
        case PackStreamMarker.list8:
            return 2
        case PackStreamMarker.list16:
            return 3
        case PackStreamMarker.list32:
            return 5
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
        case PackStreamMarker.tinyListMin...PackStreamMarker.tinyListMax:
            itemCount = Int(firstByte - PackStreamMarker.tinyListMin)
            position += 1
        case PackStreamMarker.list8:
            guard bytes.count >= 2 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(bytes[bytes.startIndex + 1])
            position += 2
        case PackStreamMarker.list16:
            guard bytes.count >= 3 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))
            position += 3
        case PackStreamMarker.list32:
            guard bytes.count >= 5 else { throw UnpackError.incorrectNumberOfBytes }
            itemCount = Int(try UInt32.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 5)]))
            position += 5
        default:
            throw UnpackError.unexpectedByteMarker
        }

        for _ in 0..<itemCount {
            let remaining = bytes[position...]
            let (_, consumed) = try Packer.unpackOne(remaining)
            position += consumed
        }

        return position - bytes.startIndex
    }
}

// MARK: - Equatable

extension List: Equatable {
    public static func == (lhs: List, rhs: List) -> Bool {
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

// MARK: - Array PackProtocol Extension

extension Array: PackProtocol where Element: PackProtocol {
    public func pack() throws -> [Byte] {
        let list = List(items: self)
        return try list.pack()
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Array {
        let list = try List.unpack(bytes)
        return list.items as! Array<Element>
    }
}

// MARK: - Helper for Equality

/// Compare two PackProtocol values for equality
func packProtocolValuesEqual(_ lhs: any PackProtocol, _ rhs: any PackProtocol) -> Bool {
    // For integers, compare by value regardless of specific integer type
    if let lhsInt = lhs.intValue(), let rhsInt = rhs.intValue() {
        return lhsInt == rhsInt
    }

    // Type must match for non-integers
    if type(of: lhs) != type(of: rhs) {
        return false
    }

    // Compare based on concrete type
    switch (lhs, rhs) {
    case let (l, r) as (Bool, Bool): return l == r
    case let (l, r) as (Double, Double): return l == r
    case let (l, r) as (String, String): return l == r
    case let (l, r) as (List, List): return l == r
    case let (l, r) as (Map, Map): return l == r
    case let (l, r) as (Structure, Structure): return l == r
    case is (Null, Null): return true
    default: return false
    }
}
