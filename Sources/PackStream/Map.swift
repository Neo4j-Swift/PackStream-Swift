import Foundation

public struct Map {
    public let dictionary: [String: PackProtocol]

    public init(dictionary: [String: PackProtocol]) {
        self.dictionary = dictionary
    }
}

extension Map: PackProtocol {

    struct Constants {
        static let shortMapMinMarker: Byte = 0xA0
        static let shortMapMaxMarker: Byte = 0xAF

        static let eightBitByteMarker: Byte = 0xD8
        static let sixteenBitByteMarker: Byte = 0xD9
        static let thirtytwoBitByteMarker: Byte = 0xDA
    }

    public func pack() throws -> [Byte] {

        let bytes = try dictionary.map({ (key: PackProtocol, value: PackProtocol) -> [Byte] in
            let keyBytes = try key.pack()
            let valueBytes = try value.pack()
            return keyBytes + valueBytes
        }).reduce([Byte](), { $0 + $1 })

        switch UInt(dictionary.count) {
        case 0:
            return [ Constants.shortMapMinMarker ]

        case 1...15:
            return [ Constants.shortMapMinMarker + UInt8(dictionary.count) ] + bytes

        case 16...255:
            let size = try UInt8(dictionary.count).pack()
            return [ Constants.eightBitByteMarker ] + size + bytes

        case 256...65_535:
            let size = try UInt16(dictionary.count).pack()
            return [ Constants.sixteenBitByteMarker ] + size + bytes

        case 65_536...4_294_967_295:
            let size = try UInt32(dictionary.count).pack()
            return [ Constants.thirtytwoBitByteMarker ] + size + bytes

        default:
            throw PackError.notPackable
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Map {

        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let size: UInt64
        var position: Int = bytes.startIndex

        switch firstByte {
        case Constants.shortMapMinMarker...Constants.shortMapMaxMarker:
            size = UInt64(firstByte - Constants.shortMapMinMarker)
            position += 1
        case Constants.eightBitByteMarker:
            size = UInt64(try UInt8.unpack([bytes[bytes.startIndex + 1]]))
            position += 2
        case Constants.sixteenBitByteMarker:
            let start = bytes.startIndex + 1
            let end = bytes.startIndex + 2
            size = UInt64(try UInt16.unpack(bytes[start...end]))
            position += 3
        case Constants.thirtytwoBitByteMarker:
            let start = bytes.startIndex + 1
            let end = bytes.startIndex + 4
            size = UInt64(try UInt32.unpack(bytes[start...end]))
            position += 5
        default:
            throw UnpackError.incorrectValue
        }

        var dictionary = [String: PackProtocol]()
        for _ in 0..<size {
            let key: PackProtocol
            let keyMarkerByte = bytes[position]
            switch Packer.Representations.typeFrom(representation: keyMarkerByte) {
            case .null:
                key = Null()
                position += 1
            case .bool:
                key = try Bool.unpack([keyMarkerByte])
                position += 1
            case .int8small:
                key = try Int8.unpack([keyMarkerByte])
                position += 1
            case .int8:
                key = try Int8.unpack(bytes[position...(position + 1)])
                position += 2
            case .int16:
                key = try Int16.unpack(bytes[position...(position + 2)])
                position += 3
            case .int32:
                key = try Int32.unpack(bytes[position...(position + 4)])
                position += 5
            case .int64:
                key = try Int64.unpack(bytes[position...(position + 8)])
                position += 9
            case .float:
                key = try Double.unpack(bytes[position...(position + 8)])
                position += 9
            case .string:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try String.sizeFor(bytes: sizeBytes)
                let markerLength = try String.markerSizeFor(bytes: sizeBytes)
                let end = position + markerLength + size
                if end >= bytes.endIndex {
                    key = try String.unpack(bytes[position..<bytes.endIndex])
                    print("Out of bounds: \(key)")
                } else {
                    key = try String.unpack(bytes[position..<end])
                }
                position += markerLength + size
            case .list:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try List.sizeFor(bytes: sizeBytes)
//                key = try List.unpack(bytes[position..<(position + size)])
                key = try List.unpack(bytes[position..<(bytes.endIndex)])
                position += size
            case .map:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Map.sizeFor(bytes: sizeBytes)
                key = try Map.unpack(bytes[position..<(bytes.endIndex)])
//                key = try Map.unpack(bytes[position..<(position + size)])
                position += size
            case .structure:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Structure.sizeFor(bytes: sizeBytes)
                key = try Structure.unpack(bytes[position..<(bytes.endIndex)])
//                key = try Structure.unpack(bytes[position..<(position + size)])
                position += size
            }

            let value: PackProtocol
            let valueMarkerByte = bytes[position]
            switch Packer.Representations.typeFrom(representation: valueMarkerByte) {
            case .null:
                value = Null()
                position += 1
            case .bool:
                value = try Bool.unpack([valueMarkerByte])
                position += 1
            case .int8small:
                value = try Int8.unpack([valueMarkerByte])
                position += 1
            case .int8:
                value = try Int8.unpack(bytes[position...(position + 1)])
                position += 2
            case .int16:
                value = try Int16.unpack(bytes[position...(position + 2)])
                position += 3
            case .int32:
                value = try Int32.unpack(bytes[position...(position + 4)])
                position += 5
            case .int64:
                value = try Int64.unpack(bytes[position...(position + 8)])
                position += 9
            case .float:
                value = try Double.unpack(bytes[position...(position + 8)])
                position += 9
            case .string:
                let length = bytes.endIndex > position + 9 ? 9 : bytes.endIndex - position - 1
                let sizeBytes = bytes[position..<(position + length)]
                let size = try String.sizeFor(bytes: sizeBytes)
                let markerLength = try String.markerSizeFor(bytes: sizeBytes)
                let stringEndPos = position + markerLength + size
                value = try String.unpack(bytes[position ..< stringEndPos])
                position += markerLength + size
            case .list:
                let length = bytes.endIndex > position + 9 ? 9 : bytes.endIndex - position - 1
                if length > 0 {
                    let size = try List.sizeFor(bytes: bytes[position..<bytes.endIndex])
                    if size > 0 {
                        value = try List.unpack(bytes[position..<(bytes.endIndex)])
//                        value = try List.unpack(bytes[position..<(position + size)])
                        position += size
                    } else {
                        value = List(items: [])
                    }
                } else {
                    value = List(items: [])
                }
            case .map:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Map.sizeFor(bytes: sizeBytes)
                // value = try Map.unpack(bytes[position..<(position + size)])
                value = try Map.unpack(bytes[position..<bytes.endIndex])
                position += size
            case .structure:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Structure.sizeFor(bytes: sizeBytes)
                value = try Structure.unpack(bytes[position..<(position + size)])
                position += size
            }

            if let key = key as? String {
                dictionary[key] = value
            } else {
                // Only string as key for now, need to make those other keys serve as Map keys
                dictionary["\(key)"] = value
                // throw UnpackError.notImplementedYet
            }

        }

        return Map(dictionary: dictionary)
    }

    static func markerSizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case Constants.shortMapMinMarker...Constants.shortMapMaxMarker:
            return 1
        case Constants.eightBitByteMarker:
            return 2
        case Constants.sixteenBitByteMarker:
            return 3
        case Constants.thirtytwoBitByteMarker:
            return 5

        default:
            throw UnpackError.unexpectedByteMarker
        }
    }

    static func sizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let numberOfItems: Int
        var position: Int = bytes.startIndex
        switch firstByte {
        case Constants.shortMapMinMarker...Constants.shortMapMaxMarker:
            numberOfItems = Int(firstByte) - Int(Constants.shortMapMinMarker)
            position += 1
        case Constants.eightBitByteMarker:
            let start = bytes.startIndex + 1
            let end = bytes.startIndex + 2
            numberOfItems = Int(try UInt8.unpack(bytes[start..<end]))
            position += 2
        case Constants.sixteenBitByteMarker:
            let start = bytes.startIndex + 1
            let end = bytes.startIndex + 3
            numberOfItems = Int(try UInt16.unpack(bytes[start..<end]))
            position += 3
        case Constants.thirtytwoBitByteMarker:
            let start = bytes.startIndex + 1
            let end = bytes.startIndex + 5
            numberOfItems = Int(try UInt32.unpack(bytes[start..<end]))
            position += 5
        default:
            throw UnpackError.unexpectedByteMarker
        }

        for _ in 0..<numberOfItems {
            let keyMarkerByte = bytes[position]
            switch Packer.Representations.typeFrom(representation: keyMarkerByte) {
            case .null:
                position += 1
            case .bool:
                position += 1
            case .int8small:
                position += 1
            case .int8:
                position += 2
            case .int16:
                position += 3
            case .int32:
                position += 5
            case .int64:
                position += 9
            case .float:
                position += 9
            case .string:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try String.sizeFor(bytes: sizeBytes)
                let markerSize = try String.markerSizeFor(bytes: sizeBytes)
                position += size + markerSize
            case .list:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try List.sizeFor(bytes: sizeBytes)
                let markerSize = try List.markerSizeFor(bytes: sizeBytes)
                position += size + markerSize
            case .map:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Map.sizeFor(bytes: sizeBytes)
                let markerSize = try Map.markerSizeFor(bytes: sizeBytes)
                position += size + markerSize
            case .structure:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Structure.sizeFor(bytes: sizeBytes)
                let markerSize = try Structure.markerSizeFor(bytes: sizeBytes)
                position += size + markerSize
            }

            let valueMarkerByte = bytes[position]
            switch Packer.Representations.typeFrom(representation: valueMarkerByte) {
            case .null:
                position += 1
            case .bool:
                position += 1
            case .int8small:
                position += 1
            case .int8:
                position += 2
            case .int16:
                position += 3
            case .int32:
                position += 5
            case .int64:
                position += 9
            case .float:
                position += 9
            case .string:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try String.sizeFor(bytes: sizeBytes)
                let markerSize = try String.markerSizeFor(bytes: sizeBytes)
                position += size + markerSize
            case .list:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try List.sizeFor(bytes: sizeBytes)
//              let markerSize = try List.markerSizeFor(bytes: sizeBytes)
                position += size // markerSize included
            case .map:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Map.sizeFor(bytes: sizeBytes)
                let markerSize = try Map.markerSizeFor(bytes: sizeBytes)
                position += size + markerSize
            case .structure:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Structure.sizeFor(bytes: sizeBytes)
                position += size
            }

        }

        return position - bytes.startIndex
    }
}

extension Map: Equatable {

    public static func ==(lhs: Map, rhs: Map) -> Bool {
        if lhs.dictionary.count != rhs.dictionary.count {
            return false
        }

        for key in lhs.dictionary.keys {
            let lhv = lhs.dictionary[key]
            let rhv = rhs.dictionary[key]
            if lhv == nil || rhv == nil {
                return false
            }

            let lht = type(of: lhv)
            let rht = type(of: rhv)

            if lht != rht {
                return false
            }

            if  let l = lhv as? Int8,
                let r = rhv as? Int8,
                l != r {
                return false
            }

            if  let l = lhv as? Int16,
                let r = rhv as? Int16,
                l != r {
                return false
            }

            if  let l = lhv as? Int32,
                let r = rhv as? Int32,
                l != r {
                return false
            }

            if  let l = lhv as? Int64,
                let r = rhv as? Int64,
                l != r {
                return false
            }

            if  let l = lhv as? Bool,
                let r = rhv as? Bool,
                l != r {
                return false
            }

            if  let l = lhv as? Double,
                let r = rhv as? Double,
                l != r {
                return false
            }

            if  let l = lhv as? String,
                let r = rhv as? String,
                l != r {
                return false
            }

            if  let l = lhv as? List,
                let r = rhv as? List,
                l != r {
                return false
            }

            if  let l = lhv as? Map,
                let r = rhv as? Map,
                l != r {
                return false
            }
        }

        return true
    }

}

extension Dictionary {
    func mapDictionary(transform: (Key, Value) -> (Key, Value)?) -> Dictionary<Key, Value> {
        var dict = [Key: Value]()
        for key in keys {
            guard let value = self[key], let keyValue = transform(key, value) else {
                continue
            }

            dict[keyValue.0] = keyValue.1
        }
        return dict
    }
}

extension Dictionary: PackProtocol  {

    public func pack() throws -> [Byte] {
        if let dict = self as? [String:PackProtocol] {
           let map = Map(dictionary: dict)
            return try map.pack()
        } else {
            throw PackError.notPackable
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Dictionary {
        let map = try Map.unpack(bytes)
        return map.dictionary as! Dictionary<Key, Value>
    }

}
