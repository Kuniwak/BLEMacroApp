import UniformTypeIdentifiers
import SwiftUI
import BLEMacro
import Fuzi


public struct BLEMacroDocument: FileDocument {
    public var macro: Macro
    public static let readableContentTypes: [UTType] = [.bleMacro]
    public static let writableContentTypes: [UTType] = [.bleMacro]
    
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let xmlDoc = try XMLDocument(data: data)
        let macro = try MacroXMLParser.parse(xml: xmlDoc).get()
        self.macro = macro
    }
    
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var output: any TextOutputStream = ""
        MacroXMLWriter.write(macro.xml(), to: &output, withIndent: 0)
        let data = Data((output as! String).utf8)
        return .init(regularFileWithContents: data)
    }
}
