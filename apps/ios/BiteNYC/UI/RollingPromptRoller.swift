import SwiftUI
import Combine

/// Cycles placeholder prompts with a vertical roll animation.
struct RollingPromptRoller: View {
    let examples: [String]
    @Binding var index: Int
    var isPaused: Bool

    private let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(examples[index])
            .font(.title2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
            .clipped()
            .id(index)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.5), value: index)
            .onReceive(timer) { _ in
                guard !isPaused, !examples.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    index = (index + 1) % examples.count
                }
            }
    }
}
