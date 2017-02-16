import Foundation

// source: https://gist.github.com/jstn/f9d5437316879c9c448a

let wordSize = __WORDSIZE // needed to suprress warnings

public func arc4random <T: ExpressibleByIntegerLiteral> (_ type: T.Type) -> T {
    var r: T = 0
    arc4random_buf(&r, Int(MemoryLayout<T>.size))
    return r
}

public extension UInt {
    public static func random(_ lower: UInt = min, upper: UInt = max) -> UInt {
        switch (wordSize) {
        case 32: return UInt(UInt32.random(UInt32(lower), upper: UInt32(upper)))
        case 64: return UInt(UInt64.random(UInt64(lower), upper: UInt64(upper)))
        default: return lower
        }
    }
}

public extension Int {
    public static func random(_ lower: Int = min, upper: Int = max) -> Int {
        switch (wordSize) {
        case 32: return Int(Int32.random(Int32(lower), upper: Int32(upper)))
        case 64: return Int(Int64.random(Int64(lower), upper: Int64(upper)))
        default: return lower
        }
    }
}

public extension Int8 {
    public static func random(_ lower: Int8 = min, upper: Int8 = max) -> Int8 {
        let r = arc4random_uniform(UInt32(Int64(upper) - Int64(lower)))
        return Int8(Int64(r) + Int64(lower))
    }
}

public extension Int16 {
    public static func random(_ lower: Int16 = min, upper: Int16 = max) -> Int16 {
        let r = arc4random_uniform(UInt32(Int64(upper) - Int64(lower)))
        return Int16(Int64(r) + Int64(lower))
    }
}

public extension UInt32 {
    public static func random(_ lower: UInt32 = min, upper: UInt32 = max) -> UInt32 {
        return arc4random_uniform(upper - lower) + lower
    }
}

public extension Int32 {
    public static func random(_ lower: Int32 = min, upper: Int32 = max) -> Int32 {
        let r = arc4random_uniform(UInt32(Int64(upper) - Int64(lower)))
        return Int32(Int64(r) + Int64(lower))
    }
}

public extension UInt64 {
    public static func random(_ lower: UInt64 = min, upper: UInt64 = max) -> UInt64 {
        var m: UInt64
        let u = upper - lower
        var r = arc4random(UInt64.self)

        if u > UInt64(Int64.max) {
            m = 1 + ~u
        } else {
            m = ((max - (u * 2)) + 1) % u
        }

        while r < m {
            r = arc4random(UInt64.self)
        }

        return (r % u) + lower
    }
}

public extension Int64 {
    public static func random(_ lower: Int64 = min, upper: Int64 = max) -> Int64 {
        let (s, overflow) = Int64.subtractWithOverflow(upper, lower)
        let u = overflow ? UInt64.max - UInt64(~s) : UInt64(s)
        let r = UInt64.random(upper: u)

        if r > UInt64(Int64.max) {
            return Int64(r - (UInt64(~lower) + 1))
        } else {
            return Int64(r) + lower
        }
    }
}

public extension Float {
    public static func random(_ lower: Float = 0.0, upper: Float = 1.0) -> Float {
        let r = Float(arc4random(UInt32.self)) / Float(UInt32.max)
        return (r * (upper - lower)) + lower
    }
}

public extension Double {
    public static func random(_ lower: Double = 0.0, upper: Double = 1.0) -> Double {
        let r = Double(arc4random(UInt64.self)) / Double(UInt64.max)
        return (r * (upper - lower)) + lower
    }
}
