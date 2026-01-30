import Foundation

// MARK: - Map Type

/// Represents a PackStream map (key-value pairs)
public struct Map: Sendable {
    public let dictionary: [String: any PackProtocol]

    public init(dictionary: [String: any PackProtocol] = [:]) {
        self.dictionary = dictionary
    }
}

// MARK: - PackProtocol Conformance

extension Map: PackProtocol {
    public func pack() throws -> [Byte] {
        let entryBytes: [Byte] = try dictionary.flatMap { (key, value) -> [Byte] in
            try key.pack() + value.pack()
        }
        let count = dictionary.count

        switch count {
        case 0:
            return [PackStreamMarker.tinyMapMin]
        case 1...15:
            return [PackStreamMarker.tinyMapMin + Byte(count)] + entryBytes
        case 16...255:
            return [PackStreamMarker.map8, Byte(count)] + entryBytes
        case 256...65535:
            let sizeBytes = try UInt16(count).pack()
            return [PackStreamMarker.map16] + sizeBytes + entryBytes
        case 65536...Int(UInt32.max):
            let sizeBytes = try UInt32(count).pack()
            return [PackStreamMarker.map32] + sizeBytes + entryBytes
        default:
            throw PackError.valueTooLarge
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Map {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let entryCount: Int
        var position = bytes.startIndex

        switch firstByte {
        case PackStreamMarker.tinyMapMin...PackStreamMarker.tinyMapMax:
            entryCount = Int(firstByte - PackStreamMarker.tinyMapMin)
            position += 1
        case PackStreamMarker.map8:
            guard bytes.count >= 2 else { throw UnpackError.incorrectNumberOfBytes }
            entryCount = Int(bytes[bytes.startIndex + 1])
            position += 2
        case PackStreamMarker.map16:
            guard bytes.count >= 3 else { throw UnpackError.incorrectNumberOfBytes }
            entryCount = Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))
            position += 3
        case PackStreamMarker.map32:
            guard bytes.count >= 5 else { throw UnpackError.incorrectNumberOfBytes }
            entryCount = Int(try UInt32.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 5)]))
            position += 5
        default:
            throw UnpackError.unexpectedByteMarker
        }

        var dictionary: [String: any PackProtocol] = [:]
        dictionary.reserveCapacity(entryCount)

        for _ in 0..<entryCount {
            // Unpack key
            let keyRemaining = bytes[position...]
            let (keyValue, keyConsumed) = try Packer.unpackOne(keyRemaining)
            position += keyConsumed

            // Unpack value
            let valueRemaining = bytes[position...]
            let (value, valueConsumed) = try Packer.unpackOne(valueRemaining)
            position += valueConsumed

            // Convert key to string
            let key: String
            if let stringKey = keyValue as? String {
                key = stringKey
            } else {
                // For non-string keys, use string representation
                key = "\(keyValue)"
            }

            dictionary[key] = value
        }

        return Map(dictionary: dictionary)
    }

    // MARK: - Size Calculation Helpers

    static func markerSizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case PackStreamMarker.tinyMapMin...PackStreamMarker.tinyMapMax:
            return 1
        case PackStreamMarker.map8:
            return 2
        case PackStreamMarker.map16:
            return 3
        case PackStreamMarker.map32:
            return 5
        default:
            throw UnpackError.unexpectedByteMarker
        }
    }

    static func sizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let entryCount: Int
        var position = bytes.startIndex

        switch firstByte {
        case PackStreamMarker.tinyMapMin...PackStreamMarker.tinyMapMax:
            entryCount = Int(firstByte - PackStreamMarker.tinyMapMin)
            position += 1
        case PackStreamMarker.map8:
            guard bytes.count >= 2 else { throw UnpackError.incorrectNumberOfBytes }
            entryCount = Int(bytes[bytes.startIndex + 1])
            position += 2
        case PackStreamMarker.map16:
            guard bytes.count >= 3 else { throw UnpackError.incorrectNumberOfBytes }
            entryCount = Int(try UInt16.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 3)]))
            position += 3
        case PackStreamMarker.map32:
            guard bytes.count >= 5 else { throw UnpackError.incorrectNumberOfBytes }
            entryCount = Int(try UInt32.unpack(bytes[(bytes.startIndex + 1)..<(bytes.startIndex + 5)]))
            position += 5
        default:
            throw UnpackError.unexpectedByteMarker
        }

        for _ in 0..<entryCount {
            // Skip key
            let keyRemaining = bytes[position...]
            let (_, keyConsumed) = try Packer.unpackOne(keyRemaining)
            position += keyConsumed

            // Skip value
            let valueRemaining = bytes[position...]
            let (_, valueConsumed) = try Packer.unpackOne(valueRemaining)
            position += valueConsumed
        }

        return position - bytes.startIndex
    }
}

// MARK: - Equatable

extension Map: Equatable {
    public static func == (lhs: Map, rhs: Map) -> Bool {
        guard lhs.dictionary.count == rhs.dictionary.count else {
            return false
        }

        for (key, lhv) in lhs.dictionary {
            guard let rhv = rhs.dictionary[key] else {
                return false
            }

            if !packProtocolValuesEqual(lhv, rhv) {
                return false
            }
        }

        return true
    }
}

// MARK: - Dictionary PackProtocol Extension

extension Dictionary: PackProtocol where Key == String, Value: PackProtocol {
    public func pack() throws -> [Byte] {
        let map = Map(dictionary: self)
        return try map.pack()
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Dictionary {
        let map = try Map.unpack(bytes)
        return map.dictionary as! Dictionary<Key, Value>
    }
}

// MARK: - Dictionary Helpers

extension Dictionary {
    func mapDictionary<K, V>(transform: (Key, Value) -> (K, V)?) -> [K: V] {
        var result: [K: V] = [:]
        for (key, value) in self {
            if let (newKey, newValue) = transform(key, value) {
                result[newKey] = newValue
            }
        }
        return result
    }
}
