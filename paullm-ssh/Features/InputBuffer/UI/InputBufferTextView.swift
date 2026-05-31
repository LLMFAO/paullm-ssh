import SwiftUI

struct InputBufferTextView: View {
    @Binding var text: String
    var onCmdReturn: () -> Void

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 15, weight: .regular, design: .monospaced))
            .autocorrectionDisabled(true)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.asciiCapable)
            .scrollContentBackground(.hidden)
            #endif
    }
}
