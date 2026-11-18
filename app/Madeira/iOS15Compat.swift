import SwiftUI

#if !os(macOS)
struct NavigationStack<Content: View>: View {
    var path: Binding<NavigationPath>?
    @ViewBuilder var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.path = nil; self.content = content }
    init(path: Binding<NavigationPath>, @ViewBuilder content: @escaping () -> Content) { self.path = path; self.content = content }
    var body: some View { NavigationView { content() }.navigationViewStyle(.stack) }
}

struct NavigationPath {
    var count: Int { 0 }
    var isEmpty: Bool { true }
    mutating func append<V: Hashable>(_ value: V) {}
    mutating func removeLast(_ k: Int = 1) {}
}

struct LabeledContent<Label: View, Content: View>: View {
    let label: Label
    let content: Content
    init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) { self.label = label(); self.content = content() }
    var body: some View { HStack { label; Spacer(); content.foregroundColor(.secondary) } }
}

extension LabeledContent where Label == Text {
    init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) { self.label = Text(titleKey); self.content = content() }
    init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) { self.label = Text(title); self.content = content() }
}

extension LabeledContent where Label == Text, Content == Text {
    init<S: StringProtocol>(_ title: S, value: String) { self.label = Text(title); self.content = Text(value) }
}

struct ShareLink<Label: View>: View {
    let item: Any
    let label: Label
    init(item: URL, subject: Text? = nil, message: Text? = nil, @ViewBuilder label: () -> Label) { self.item = item; self.label = label() }
    init(item: String, subject: Text? = nil, message: Text? = nil, @ViewBuilder label: () -> Label) { self.item = item; self.label = label() }
    var body: some View {
        Button {
            guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = ws.windows.first?.rootViewController else { return }
            let av = UIActivityViewController(activityItems: [item], applicationActivities: nil)
            var top = root
            while let p = top.presentedViewController { top = p }
            top.present(av, animated: true)
        } label: { label }
    }
}

extension ShareLink where Label == SwiftUI.Label<Text, Image> {
    init(_ title: String, item: URL, subject: Text? = nil, message: Text? = nil) {
        self.item = item
        self.label = SwiftUI.Label(title, systemImage: "square.and.arrow.up")
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    init<S: Shape>(_ wrapped: S) { _path = { rect in wrapped.path(in: rect) } }
    func path(in rect: CGRect) -> Path { _path(rect) }
}

struct ViewThatFits<Content: View>: View {
    let content: Content
    init(in axes: Axis.Set = [.horizontal, .vertical], @ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content }
}

enum ScrollIndicatorVisibilityCompat { case automatic, visible, hidden, never }
enum ToolbarPlacementCompat { case automatic, navigationBar, tabBar, bottomBar }
enum SearchBarPlacementCompat { case automatic, navigationBarDrawer, sidebar, toolbar }

extension View {
    func fontWeight(_ weight: Font.Weight?) -> some View { self }
    func scrollContentBackground(_ visibility: Visibility) -> some View { self }
    func scrollIndicators(_ visibility: ScrollIndicatorVisibilityCompat, axes: Axis.Set = [.vertical, .horizontal]) -> some View { self }
    func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacementCompat...) -> some View { self }
    func toolbarBackground<S: ShapeStyle>(_ style: S, for bars: ToolbarPlacementCompat...) -> some View { self }
    func preferredSearchBarPlacement(_ placement: SearchBarPlacementCompat) -> some View { self }
}
#endif
