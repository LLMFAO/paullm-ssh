import SwiftUI

struct InputBufferTextView: View {
    @Binding var text: String
    /// Bound directly to the underlying TextEditor. Applying `.focused` to the
    /// wrapper view did not reliably engage the editor, so the terminal keyboard
    /// stayed up and covered the composer's controls until the user tapped away.
    var focused: FocusState<Bool>.Binding
    var onCmdReturn: () -> Void

    var body: some View {
        TextEditor(text: $text)
            .focused(focused)
            .font(.system(size: 15, weight: .regular, design: .monospaced))
            .autocorrectionDisabled(true)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.asciiCapable)
            .scrollContentBackground(.hidden)
            #endif
    }
}
