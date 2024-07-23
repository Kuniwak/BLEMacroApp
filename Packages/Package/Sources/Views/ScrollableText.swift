import SwiftUI
import EditMenu


public struct ScrollableText: View {
    private let text: String
    private let foregroundColor: Color

    
    public init(_ text: String, foregroundColor: Color? = nil) {
        self.text = text
        self.foregroundColor = foregroundColor ?? Color(.weak)
    }

    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .lineLimit(1)
                    .background(Color(.secondarySystemGroupedBackground))
                    // XXX: For unknown reasons, modifiers do not apply on views inside editMenu.
                    .foregroundColor(foregroundColor)
                    .editMenu {
                        EditMenuItem("Copy") {
                            UIPasteboard.general.string = text
                        }
                    }
                    .frame(
                        minWidth: geometry.size.width,
                        minHeight: geometry.size.height,
                        maxHeight: geometry.size.height,
                        alignment: .trailing
                    )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .trailing
            )
        }
    }
}


#Preview {
    NavigationStack {
        Form {
            LabeledContent("Short") {
                ScrollableText("text.")
            }

            LabeledContent("Long") {
                ScrollableText("This is a long text that is going to be scrolled.")
            }

            LabeledContent("Colored") {
                ScrollableText("This is a long text that is going to be scrolled.", foregroundColor: Color(.error))
            }
        }
    }
}
