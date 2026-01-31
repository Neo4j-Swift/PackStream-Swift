# Getting Started with PackStream

Learn how to serialize and deserialize data using the PackStream format.

## Overview

PackStream provides a simple API for converting Swift values to and from a compact binary format. This guide covers the basics of packing and unpacking data.

### Packing Data

To serialize data, use the `pack()` method available on all types conforming to ``PackProtocol``:

```swift
import PackStream

// Pack a simple integer
let intValue: Int64 = 42
let bytes = try intValue.pack()

// Pack a string
let stringValue = "Hello, Neo4j!"
let stringBytes = try stringValue.pack()

// Pack a list
let list = List(items: ["Alice", "Bob", Int64(30)])
let listBytes = try list.pack()

// Pack a map
let map = Map(dictionary: [
    "name": "Alice",
    "age": Int64(30)
])
let mapBytes = try map.pack()
```

### Unpacking Data

To deserialize data, use the static `unpack(_:)` method:

```swift
import PackStream

// Unpack an integer
let intValue = try Int64.unpack(bytes)

// Unpack a string
let stringValue = try String.unpack(stringBytes)

// Unpack a list
let list = try List.unpack(listBytes)
for item in list.items {
    print(item)
}

// Unpack a map
let map = try Map.unpack(mapBytes)
if let name = map.dictionary["name"] as? String {
    print("Name: \(name)")
}
```

### Working with ByteBuffer

For better performance in networking scenarios, pack directly into a SwiftNIO `ByteBuffer`:

```swift
import PackStream
import NIOCore

var buffer = ByteBufferAllocator().buffer(capacity: 256)

// Pack directly into the buffer
try Int64(42).pack(into: &buffer)
try "Hello".pack(into: &buffer)
```

### Using Structures

Structures are used by the Bolt protocol to represent typed messages:

```swift
import PackStream

// Create a structure (e.g., for a Bolt message)
let structure = Structure(
    signature: 0x10,  // Message signature
    items: [Int64(1), "query", Map(dictionary: [:])]
)

let bytes = try structure.pack()
```

## Topics

### Core Protocol

- ``PackProtocol``

### Data Types

- ``List``
- ``Map``
- ``Structure``
