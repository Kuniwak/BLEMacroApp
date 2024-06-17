import XCTest
import CoreBluetoothStub
import ModelStubs
@testable import Models


final class PeripheralSearchModelTests: XCTestCase {
    private struct TestCase {
        public let description: String
        public let peripheral: StubPeripheralModel
        public let searchQuery: String
        public let expected: Bool
    }
    
    
    func testSatisfy() {
        let testCases: [UInt: TestCase] = [
            #line: .init(
                description: "No match",
                peripheral: .init(
                    state: .makeStub(
                        name: .success(nil),
                        manufacturerData: nil
                    ),
                    identifiedBy: StubUUID.zero
                ),
                searchQuery: "a",
                expected: false
            ),
            #line: .init(
                description: "Empty search query match by UUID",
                peripheral: .init(
                    state: .makeStub(
                        name: .success(nil),
                        manufacturerData: nil
                    ),
                    identifiedBy: StubUUID.zero
                ),
                searchQuery: "",
                expected: true
            ),
            #line: .init(
                description: "Empty search query match by name",
                peripheral: .init(
                    state: .makeStub(
                        name: .success("EXAMPLE"),
                        manufacturerData: nil
                    ),
                    identifiedBy: StubUUID.zero
                ),
                searchQuery: "",
                expected: true
            ),
            #line: .init(
                description: "Empty search query match by manufacturer name",
                peripheral: .init(
                    state: .makeStub(
                        name: .success(nil),
                        manufacturerData: .knownName("EXAMPLE", Data())
                    ),
                    identifiedBy: StubUUID.zero
                ),
                searchQuery: "",
                expected: true
            ),
            #line: .init(
                description: "Match by UUID",
                peripheral: .init(
                    state: .makeStub(
                        name: .success(nil),
                        manufacturerData: nil
                    ),
                    identifiedBy: StubUUID.zero
                ),
                searchQuery: "0000",
                expected: true
            ),
            #line: .init(
                description: "Match by Name",
                peripheral: .init(
                    state: .makeStub(
                        name: .success("__NAME__"),
                        manufacturerData: nil
                    ),
                    identifiedBy: StubUUID.zero
                ),
                searchQuery: "NAME",
                expected: true
            ),
            #line: .init(
                description: "Match by Manufacture Name",
                peripheral: .init(
                    state: .makeStub(
                        name: .success(nil),
                        manufacturerData: .knownName("__MANUFACTURER__", Data())
                    ),
                    identifiedBy: StubUUID.zero
                ),
                searchQuery: "MANUFACTURER",
                expected: true
            ),
        ]
        
        for (line, testCase) in testCases {
            let result = satisfy(searchQuery: testCase.searchQuery)(testCase.peripheral)
            XCTAssertEqual(result, testCase.expected, line: line)
        }
    }
}
