import Testing
import Foundation
@testable import Catalogs

private struct TestCase {
    public let description: String
    public let manufacturer: Data
    public let expected: ManufacturerData
}


@Test(arguments: [
    TestCase(
        description: "Matched",
        manufacturer: Data([0xfe, 0xd4, 0x12, 0x34]),
        expected: .knownName(.init(name: "Apple, Inc.", 0x12, 0x34), Data([0x12, 0x34]))
    ),
    TestCase(
        description: "Not matched",
        manufacturer: Data([0x00, 0x00, 0x12, 0x34]),
        expected: .data(Data([0x00, 0x00, 0x12, 0x34]))
    ),
])
private func manifacturerCatalogTests(testCase: TestCase) {
    let actual = ManufacturerCatalog.from(data: testCase.manufacturer)
    #expect(actual == testCase.expected)
}
