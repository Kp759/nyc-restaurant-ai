import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var model = ChatViewModel()
    @State private var path = NavigationPath()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if model.isSending {
                                FoodPunInlineLoadingView(quote: LoadingQuotes.chat[0])
                                    .id("chat-loading")
                            }

                            ForEach(model.messages) { message in
                                turnView(message).id(message.id)
                            }

                            if model.messages.isEmpty {
                                intro
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: model.messages.count) {
                        scrollToLatest(proxy)
                    }
                    .onChange(of: model.newestAssistant?.isStreaming) { _, streaming in
                        guard streaming == false else { return }
                        scrollToLatest(proxy)
                    }
                    .onChange(of: model.newestAssistant?.visibleResultCount) { _, _ in
                        scrollToLatest(proxy, animated: false)
                    }
                    .onChange(of: model.isSending) { _, sending in
                        if sending { scrollToTop(proxy) }
                    }
                }
                inputBar
            }
            .navigationTitle("Ask me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.selectedTab = .home
                    } label: {
                        Label("Home", systemImage: "chevron.left")
                    }
                }
            }
            .navigationDestination(for: RestaurantRoute.self) { RestaurantDetailView(slug: $0.slug) }
        }
        .onAppear { consumePendingPrompt() }
        .onChange(of: router.pendingChatPrompt) { _, _ in consumePendingPrompt() }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy, animated: Bool = true) {
        guard let id = model.latestTurnID else { return }
        if animated {
            withAnimation { proxy.scrollTo(id, anchor: .top) }
        } else {
            proxy.scrollTo(id, anchor: .top)
        }
    }

    private func scrollToTop(_ proxy: ScrollViewProxy) {
        withAnimation { proxy.scrollTo("chat-loading", anchor: .top) }
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
    private func turnView(_ message: ChatMessage) -> some View {
        if message.role == "user" {
            userBubble(message)
        } else {
            assistantTurn(message)
        }
    }

    private func userBubble(_ message: ChatMessage) -> some View {
        HStack {
            Spacer()
            Text(message.text)
                .padding(10)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func assistantTurn(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundStyle(Theme.accent)
                    Text("BiteNYC")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                    if message.isStreaming {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Theme.accent)
                    }
                }
                assistantMessageBody(message)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(message.isError ? Theme.bad.opacity(0.12) : Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.accent.opacity(0.12), lineWidth: 1)
            )

            ForEach(Array(message.results.prefix(message.visibleResultCount))) { result in
                NavigationLink(value: RestaurantRoute(slug: result.restaurant.slug)) {
                    RestaurantCard(restaurant: result.restaurant, whyItFits: result.whyItFits)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func assistantMessageBody(_ message: ChatMessage) -> some View {
        Group {
            if message.isError {
                Text(message.text)
            } else if message.isStreaming {
                Text(message.text)
            } else {
                Text(markdown(message.text))
                    .transaction { $0.animation = nil }
            }
        }
        .font(.callout)
        .lineSpacing(5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
        .foregroundStyle(message.isError ? Theme.bad : .primary)
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
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { Task { await submitFromInputBar() } }
            Button { Task { await submitFromInputBar() } } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title)
            }
            .tint(Theme.accent)
            .disabled(model.input.trimmingCharacters(in: .whitespaces).isEmpty || model.isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func submitFromInputBar() async {
        await model.send()
        inputFocused = false
    }
}
