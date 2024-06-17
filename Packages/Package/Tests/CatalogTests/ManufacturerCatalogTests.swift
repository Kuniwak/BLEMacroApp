import XCTest
@testable import Catalogs


final class ManufacturerCatalogTests: XCTestCase {
    private struct TestCase {
        public let description: String
        public let manufacturer: Data
        public let expected: ManufacturerData
    }
    
    
    func testFrom() {
        let testCases: [UInt: TestCase] = [
            #line: .init(
                description: "Matched",
                manufacturer: Data([0xfe, 0xd4, 0x12, 0x34]),
                expected: .knownName("Apple, Inc.", Data([0x12, 0x34]))
            ),
            #line: .init(
                description: "Not matched",
                manufacturer: Data([0x00, 0x00, 0x12, 0x34]),
                expected: .data(Data([0x00, 0x00, 0x12, 0x34]))
            ),
        ]
        
        for (line, testCase) in testCases {
            let actual = ManufacturerCatalog.from(data: testCase.manufacturer)
            XCTAssertEqual(actual, testCase.expected, line: line)
        }
    }
}
