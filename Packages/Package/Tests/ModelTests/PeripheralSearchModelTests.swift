import Foundation
import CoreBluetoothStub
import Models
import ModelStubs
import Testing


private struct TestCase {
    public let description: String
    public let peripheral: PeripheralModelState
    public let searchQuery: SearchQuery
    public let expected: Bool
}
    
    
@Test(arguments: [
    TestCase(
        description: "No match",
        peripheral: .makeStub(
            name: .success(nil),
            manufacturerData: nil
        ),
        searchQuery: "a",
        expected: false
    ),
    TestCase(
        description: "Empty search query match by UUID",
        peripheral:  .makeStub(
            name: .success(nil),
            manufacturerData: nil
        ),
        searchQuery: "",
        expected: true
    ),
    TestCase(
        description: "Empty search query match by name",
        peripheral:  .makeStub(
            name: .success("EXAMPLE"),
            manufacturerData: nil
        ),
        searchQuery: "",
        expected: true
    ),
    TestCase(
        description: "Empty search query match by manufacturer name",
        peripheral: .makeStub(
            name: .success(nil),
            manufacturerData: .knownName("EXAMPLE", Data())
        ),
        searchQuery: "",
        expected: true
    ),
    TestCase(
        description: "Match by UUID",
        peripheral: .makeStub(
            name: .success(nil),
            manufacturerData: nil
        ),
        searchQuery: "0000",
        expected: true
    ),
    TestCase(
        description: "Match by Name",
        peripheral: .makeStub(
            name: .success("__NAME__"),
            manufacturerData: nil
        ),
        searchQuery: "NAME",
        expected: true
    ),
    TestCase(
        description: "Match by Manufacture Name",
        peripheral: .makeStub(
            name: .success(nil),
            manufacturerData: .knownName("__MANUFACTURER__", Data())
        ),
        searchQuery: "MANUFACTURER",
        expected: true
    ),
])
private func testSearchQueryMatch(testCase: TestCase) {
    let actual = testCase.searchQuery.match(state: testCase.peripheral)
    #expect(actual == testCase.expected)
}
