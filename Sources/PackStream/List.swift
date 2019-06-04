import Foundation

/*
 * I'd prefer to do
 *
extension Sequence where Self:PackProtocol { ... }
 *
 * but this brought to much complexity for the time being, so List for now, refactor later
 */

public struct List {
    public let items: [PackProtocol]

    public init(items: [PackProtocol] = []) {
        self.items = items
    }
}

extension List: PackProtocol {

    struct Constants {
        static let shortListMinMarker: Byte = 0x90
        static let shortListMaxMarker: Byte = 0x9F

        static let eightBitByteMarker: Byte = 0xD4
        static let sixteenBitByteMarker: Byte = 0xD5
        static let thirtytwoBitByteMarker: Byte = 0xD6
    }

    public func pack() throws -> [Byte] {

        switch UInt(items.count) {
        case 0:
            return [ Constants.shortListMinMarker ]
        case 1...15:
            let bytes: [Byte] = try items.map({ try $0.pack() }).reduce([Byte](), { $0 + $1 })
            return [ Constants.shortListMinMarker + UInt8(items.count) ] + bytes
        case 16...255:
            let bytes: [Byte] = try items.map({ try $0.pack() }).reduce([Byte](), { $0 + $1 })
            let size = try UInt8(items.count).pack()
            return [ Constants.eightBitByteMarker ] + size + bytes
        case 256...65_535:
            let bytes: [Byte] = try items.map({ try $0.pack() }).reduce([Byte](), { $0 + $1 })
            let size = try UInt16(items.count).pack()
            return [ Constants.sixteenBitByteMarker ] + size + bytes
        case 65_536...4_294_967_295:
            let bytes: [Byte] = try items.map({ try $0.pack() }).reduce([Byte](), { $0 + $1 })
            let size = try UInt32(items.count).pack()
            return [ Constants.thirtytwoBitByteMarker ] + size + bytes
        default:
            throw PackError.notPackable
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> List {

        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        let size: UInt64
        var position: Int = bytes.startIndex

        switch firstByte {
        case Constants.shortListMinMarker...Constants.shortListMaxMarker:
            size = UInt64(firstByte - Constants.shortListMinMarker)
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

        var items = [PackProtocol]()
        for _ in 0..<size {
            let item: PackProtocol
            let markerByte = bytes[position]
            switch Packer.Representations.typeFrom(representation: markerByte) {
            case .null:
                item = Null()
                position += 1
            case .bool:
                item = try Bool.unpack([markerByte])
                position += 1
            case .int8small:
                item = try Int8.unpack([markerByte])
                position += 1
            case .int8:
                if position + 1 >= bytes.endIndex {
                    throw UnpackError.incorrectNumberOfBytes
                }
                item = try Int8.unpack(bytes[position...(position + 1)])
                position += 2
            case .int16:
                if position + 2 >= bytes.endIndex {
                    throw UnpackError.incorrectNumberOfBytes
                }
                item = try Int16.unpack(bytes[position...(position + 2)])
                position += 3
            case .int32:
                if position + 4 >= bytes.endIndex {
                    throw UnpackError.incorrectNumberOfBytes
                }
                item = try Int32.unpack(bytes[position...(position + 4)])
                position += 5
            case .int64:
                if position + 8 >= bytes.endIndex {
                    throw UnpackError.incorrectNumberOfBytes
                }
                item = try Int32.unpack(bytes[position...(position + 8)])
                position += 9
            case .float:
                if position + 8 >= bytes.endIndex {
                    throw UnpackError.incorrectNumberOfBytes
                }
                item = try Double.unpack(bytes[position...(position + 8)])
                position += 9
            case .string:
                let sizeBytes = bytes[position..<(bytes.endIndex)]
                let size = try String.sizeFor(bytes: sizeBytes)
                let markerLength = try String.markerSizeFor(bytes: sizeBytes)
                item = try String.unpack(bytes[position..<(position + markerLength + size)])
                position += markerLength + size
            case .list:
                let size = try List.sizeFor(bytes: bytes[position..<(bytes.endIndex)])
                item = try List.unpack(bytes[position..<(bytes.endIndex)])
                position += size
            case .map:
                let size = try Map.sizeFor(bytes: bytes[position..<(bytes.endIndex)])
                item = try Map.unpack(bytes[position..<(bytes.endIndex)])
                position += size
            case .structure:
                let sizeBytes = bytes[position..<(bytes.endIndex)]
                let size = try Structure.sizeFor(bytes: sizeBytes)
                item = try Structure.unpack(bytes[position..<(bytes.endIndex)])
                position += size
            }

            items.append(item)
        }

        return List(items: items)
    }

    static func markerSizeFor(bytes: ArraySlice<Byte>) throws -> Int {
        guard let firstByte = bytes.first else {
            throw UnpackError.incorrectNumberOfBytes
        }

        switch firstByte {
        case Constants.shortListMinMarker...Constants.shortListMaxMarker:
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
        case Constants.shortListMinMarker...Constants.shortListMaxMarker:
            numberOfItems = Int(firstByte) - Int(Constants.shortListMinMarker)
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
            let markerByte = bytes[position]
            switch Packer.Representations.typeFrom(representation: markerByte) {
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
                let length = bytes.endIndex > position + 9 ? 9 : bytes.endIndex - position - 1
                let sizeBytes = bytes[position...(position + length)]
                let size = try String.sizeFor(bytes: sizeBytes)
                let markerSize = try String.markerSizeFor(bytes: sizeBytes)
                position += size + markerSize
            case .list:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try List.sizeFor(bytes: sizeBytes)
                position += size
            case .map:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Map.sizeFor(bytes: sizeBytes)
                position += size
            case .structure:
                let sizeBytes = bytes[position..<bytes.endIndex]
                let size = try Structure.sizeFor(bytes: sizeBytes)
                position += size
            }
        }

        return position - bytes.startIndex
    }

}

extension List: Equatable {

    public static func ==(lhs: List, rhs: List) -> Bool {
        if lhs.items.count != rhs.items.count {
            return false
        }

        for i in 0..<lhs.items.count {
            let lht = type(of: lhs.items[i])
            let rht = type(of: rhs.items[i])
            if lht != rht {
                return false
            }

            if  let l = lhs.items[i] as? Int8,
                let r = rhs.items[i] as? Int8,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? Int16,
                let r = rhs.items[i] as? Int16,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? Int32,
                let r = rhs.items[i] as? Int32,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? Int64,
                let r = rhs.items[i] as? Int64,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? Bool,
                let r = rhs.items[i] as? Bool,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? Double,
                let r = rhs.items[i] as? Double,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? String,
                let r = rhs.items[i] as? String,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? List,
                let r = rhs.items[i] as? List,
                l != r {
                return false
            }

            if  let l = lhs.items[i] as? Map,
                let r = rhs.items[i] as? Map,
                l != r {
                return false
            }
        }

        return true
    }

}

extension Array: PackProtocol {

    public func pack() throws -> [Byte] {
        if let array = self as? [PackProtocol] {
            let list = List(items: array)
            return try list.pack()
        } else {
            throw PackError.notPackable
        }
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Array {
        let list = try List.unpack(bytes)
        return list.items as! Array<Element>
    }

}
