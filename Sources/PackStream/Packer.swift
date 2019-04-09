import Foundation

public class Packer {

    public enum Representations {
        case null
        case bool
        case int8small
        case int8
        case int16
        case int32
        case int64
        case float
        case string
        case list
        case map
        case structure

        public static func typeFrom(representation: Byte) -> Representations {
            if Int(representation) <= Int(Int8.max) && Int(representation) >= Int(Int8.min) {
                switch Int8(representation) {
                case -0x10 ... 0x7F:
                    return .int8small
                default:
                    break
                }
            }

            switch representation {
            case 0xC0:
                return .null
            case Bool.Constants.byteForFalse,
                 Bool.Constants.byteForTrue:
                return .bool
            case Int8.Constants.byteMarker:
                return .int8
            case Int16.Constants.byteMarker:
                return .int16
            case Int32.Constants.byteMarker:
                return .int32
            case Int64.Constants.byteMarker:
                return .int64
            case Double.Constants.byteMarker:
                return .float
            case String.Constants.shortStringMinMarker...String.Constants.shortStringMaxMarker,
                 String.Constants.eightBitByteMarker,
                 String.Constants.sixteenBitByteMarker,
                 String.Constants.thirtytwoBitByteMarker:
                return .string
            case List.Constants.shortListMinMarker...List.Constants.shortListMaxMarker,
                 List.Constants.eightBitByteMarker,
                 List.Constants.sixteenBitByteMarker,
                 List.Constants.thirtytwoBitByteMarker:
                return .list
            case Map.Constants.shortMapMinMarker...Map.Constants.shortMapMaxMarker,
                 Map.Constants.eightBitByteMarker,
                 Map.Constants.sixteenBitByteMarker,
                 Map.Constants.thirtytwoBitByteMarker:
                return .map
            case Structure.Constants.shortStructureMinMarker...Structure.Constants.shortStructureMaxMarker,
                 Structure.Constants.eightBitByteMarker,
                 Structure.Constants.sixteenBitByteMarker:
                return .structure
            default:
                return .null
            }
        }
    }

    func pack(_ values: [PackProtocol]) throws -> [Byte] {
        let packed = try values.flatMap { (value) -> [Byte] in
            try value.pack()
        }
        return packed
    }

    static func unpack(_ bytes: ArraySlice<Byte>) throws -> [PackProtocol] {

        return []

    }

}
