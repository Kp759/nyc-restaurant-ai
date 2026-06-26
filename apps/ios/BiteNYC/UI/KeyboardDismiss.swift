import SwiftUI

extension View {
    /// Adds a keyboard toolbar with a Done button that clears focus.
    func keyboardDismissToolbar(focused: FocusState<Bool>.Binding) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused.wrappedValue = false }
                    .fontWeight(.semibold)
            }
        }
    }
}
