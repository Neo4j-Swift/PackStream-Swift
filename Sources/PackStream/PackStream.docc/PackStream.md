# ``PackStream``

A Swift implementation of Neo4j's PackStream binary serialization format.

## Overview

PackStream is a binary serialization format designed for efficient data exchange with Neo4j databases. This library provides a type-safe Swift implementation that conforms to the PackStream specification used by the Bolt protocol.

The format supports a variety of data types including:
- Primitive types: `Bool`, `Int8`-`Int64`, `Double`
- String values with UTF-8 encoding
- Collections: `List` and `Map`
- Binary data with `Null` representation
- Structured data with `Structure` for protocol-level messages

### Key Features

- **Type Safety**: All packable types conform to the ``PackProtocol`` protocol
- **ByteBuffer Integration**: Efficient serialization directly to SwiftNIO `ByteBuffer`
- **Bidirectional**: Full support for both packing and unpacking operations
- **Extensible**: Easy to add custom structure types

## Topics

### Essentials

- ``PackProtocol``
- ``PackStreamMarker``

### Data Types

- ``List``
- ``Map``
- ``Structure``
- ``Null``

### Errors

- ``PackError``
- ``UnpackError``
- ``PackStreamError``

### Type Information

- ``PackStreamType``
