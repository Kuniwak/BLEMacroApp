import Foundation
import CoreBluetoothStub
import Models
import ModelStubs
import Testing


private struct TestCase: CustomTestStringConvertible {
    public let testDescription: String
    public let peripheral: PeripheralModelState
    public let searchQuery: SearchQuery
    public let expected: Bool
}

    
@Test(arguments: [
    TestCase(
        testDescription: "No match",
        peripheral: .makeStub(
            name: .success(nil),
            manufacturerData: nil
        ),
        searchQuery: "a",
        expected: false
    ),
    TestCase(
        testDescription: "Empty search query match by UUID",
        peripheral:  .makeStub(
            name: .success(nil),
            manufacturerData: nil
        ),
        searchQuery: "",
        expected: true
    ),
    TestCase(
        testDescription: "Empty search query match by name",
        peripheral:  .makeStub(
            name: .success("EXAMPLE"),
            manufacturerData: nil
        ),
        searchQuery: "",
        expected: true
    ),
    TestCase(
        testDescription: "Empty search query match by manufacturer name",
        peripheral: .makeStub(
            name: .success(nil),
            manufacturerData: .knownName(.init(name: "EXAMPLE", 0x01, 0x23), Data())
        ),
        searchQuery: "",
        expected: true
    ),
    TestCase(
        testDescription: "Match by UUID",
        peripheral: .makeStub(
            name: .success(nil),
            manufacturerData: nil
        ),
        searchQuery: "0000",
        expected: true
    ),
    TestCase(
        testDescription: "Match by Name",
        peripheral: .makeStub(
            name: .success("__NAME__"),
            manufacturerData: nil
        ),
        searchQuery: "NAME",
        expected: true
    ),
])
private func testSearchQueryMatch(testCase: TestCase) {
    let actual = testCase.searchQuery.match(state: testCase.peripheral)
    #expect(actual == testCase.expected)
}
