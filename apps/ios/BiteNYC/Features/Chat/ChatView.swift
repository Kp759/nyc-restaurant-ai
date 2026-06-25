import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var model = ChatViewModel()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if model.messages.isEmpty { intro }
                            ForEach(model.messages) { message in
                                messageView(message).id(message.id)
                            }
                            if model.isSending {
                                HStack { ProgressView(); Text("Thinking…").foregroundStyle(.secondary) }
                                    .font(.caption)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: model.messages.count) {
                        if let last = model.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }
                inputBar
            }
            .navigationTitle("Ask BiteNYC")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RestaurantRoute.self) { RestaurantDetailView(slug: $0.slug) }
        }
        .onAppear { consumePendingPrompt() }
        .onChange(of: router.pendingChatPrompt) { _, _ in consumePendingPrompt() }
    }

    /// Sends a prompt handed over from another tab (e.g. the Home hero). Runs in
    /// an independent Task so clearing `pendingChatPrompt` doesn't cancel it.
    private func consumePendingPrompt() {
        guard let prompt = router.pendingChatPrompt else { return }
        router.pendingChatPrompt = nil
        Task { await model.send(prompt) }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tell me what you're in the mood for and I'll find NYC spots from our curated catalog.")
                .font(.subheadline).foregroundStyle(.secondary)
            ForEach(model.starters, id: \.self) { starter in
                Button { Task { await model.send(starter) } } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                        Text(starter).font(.subheadline)
                        Spacer()
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        if message.role == "user" {
            HStack {
                Spacer()
                Text(message.text)
                    .padding(10)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife.circle.fill")
                            .foregroundStyle(Theme.accent)
                        Text("BiteNYC")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    Text(message.isError ? AttributedString(message.text) : markdown(message.text))
                        .font(.callout)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .foregroundStyle(message.isError ? Theme.bad : .primary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(message.isError ? Theme.bad.opacity(0.12) : Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.accent.opacity(0.12), lineWidth: 1)
                )

                ForEach(message.results) { result in
                    NavigationLink(value: RestaurantRoute(slug: result.restaurant.slug)) {
                        RestaurantCard(restaurant: result.restaurant, whyItFits: result.whyItFits)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Parses the model's Markdown reply while preserving its line breaks so the
    /// formatted picks stay easy to skim.
    private func markdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: text, options: options))
            ?? AttributedString(text)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask for a vibe, dish, or neighborhood…", text: $model.input, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .submitLabel(.send)
                .onSubmit { Task { await model.send() } }
            Button { Task { await model.send() } } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title)
            }
            .tint(Theme.accent)
            .disabled(model.input.trimmingCharacters(in: .whitespaces).isEmpty || model.isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
