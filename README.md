# PackStream implementation in Swift

PackStream is a binary message format very similar to [MessagePack](http://msgpack.org). It can be used stand-alone, but it has been built as a message format for use in the Bolt protocol to communicate between the Neo4j server and its clients.

This implementation is written in Swift, primarily as a dependency for the Swift Bolt implementation. That implementation will in turn provide [Theo](https://github.com/Neo4j-Swift/Neo4j-Swift), the [Neo4j](https://neo4j.com) Swift driver, with Bolt support.

## Requirements

* macOS 14+ / iOS 17+ / tvOS 17+ / watchOS 10+ / Linux
* Swift 6.0+

## Usage
Through PackStream you can encode Bool, Int, Float (Double in Swift lingo), String, List, Map and Structure. They all implement the `PackProtocol`, so if you want to have a collection of packable items, you can specify them as implementing PackProtocol.

### Example
First, remember to
```swift
import PackStream
```

Then you can use it, like for instance so:

```swift
let map = Map(dictionary: [
    "alpha": 42,
    "beta": 39.3,
    "gamma": "☺",
    "delta": List(items: [1,2,3,4])
    ])
let result = try map.pack()
let restored = try Map.unpack(result)
```

A list of the numbers 1 to 40
```swift
let items = Array(Int8(1)...Int8(40))
let value = List(items: items)
```
gets encoded to the following bytes
```
D4:28:01:02:03:04:05:06:07:08:09:0A:0B:0C:0D:0E:0F:10:11:12:13:14:15:16:17:18:19:1A:1B:1C:1D:1E:1F:20:22:23:24:25:26:27:28
```

## Getting started

### Swift Package Manager
Add the following to your dependencies array in Package.swift:
```swift
.package(url: "https://github.com/Neo4j-Swift/PackStream-Swift.git", from: "6.0.0"),
```
and you can now do a
```bash
swift build
```

## Protocol documentation
For reference, please see [driver.py](https://github.com/neo4j-contrib/boltkit/blob/master/boltkit/driver.py) in [Boltkit](https://github.com/neo4j-contrib/boltkit)
