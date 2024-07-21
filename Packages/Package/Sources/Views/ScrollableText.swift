import SwiftUI
import EditMenu


public struct ScrollableText: View {
    private let text: String

    
    public init(_ text: String) {
        self.text = text
    }

    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .foregroundStyle(Color(.weak))
                    .lineLimit(1)
                    .frame(
                        minWidth: geometry.size.width,
                        minHeight: geometry.size.height,
                        maxHeight: geometry.size.height,
                        alignment: .trailing
                    )
                    .editMenu {
                        EditMenuItem("Copy") {
                            UIPasteboard.general.string = text
                        }
                    }
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
                ScrollableText("This is a long text that is going to be scrolled.")
                    .foregroundStyle(Color(.error))
            }
        }
    }
}
