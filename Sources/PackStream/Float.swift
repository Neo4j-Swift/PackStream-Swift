import Foundation

// MARK: - Double PackProtocol (IEEE 754 double-precision float)

extension Double: PackProtocol {
    public func pack() throws -> [Byte] {
        // Get the bit pattern and write in big-endian (network) byte order
        let bits = self.bitPattern
        return [
            PackStreamMarker.float64,
            Byte((bits >> 56) & 0xFF),
            Byte((bits >> 48) & 0xFF),
            Byte((bits >> 40) & 0xFF),
            Byte((bits >> 32) & 0xFF),
            Byte((bits >> 24) & 0xFF),
            Byte((bits >> 16) & 0xFF),
            Byte((bits >> 8) & 0xFF),
            Byte(bits & 0xFF)
        ]
    }

    public static func unpack(_ bytes: ArraySlice<Byte>) throws -> Double {
        guard bytes.count == 9, bytes.first == PackStreamMarker.float64 else {
            if bytes.count != 9 {
                throw UnpackError.incorrectNumberOfBytes
            }
            throw UnpackError.unexpectedByteMarker
        }

        // Read bytes in big-endian order and reconstruct the bit pattern
        var bits: UInt64 = 0
        for i in 1..<9 {
            bits = (bits << 8) | UInt64(bytes[bytes.startIndex + i])
        }

        return Double(bitPattern: bits)
    }
}
