import XCTest

#if !os(macOS) && !os(iOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
		testCase(BoolTests.allTests),
		testCase(FloatTests.allTests),
		testCase(FullTests.allTests),
		testCase(Int8Tests.allTests),
		testCase(Int16Tests.allTests),
		testCase(Int32Tests.allTests),
		testCase(Int64Tests.allTests),
		testCase(ListTests.allTests),
		testCase(MapTests.allTests),
		testCase(NullTests.allTests),
		testCase(StringTests.allTests),
		testCase(StructureTests.allTests)
    ]
}
#endif
