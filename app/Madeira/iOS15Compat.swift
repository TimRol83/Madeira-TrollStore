
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
    init<S: StringProtocol>(_ title: S, value: S) { self.label = Text(title); self.content = Text(value) }
    init(_ titleKey: LocalizedStringKey, value: String) { self.label = Text(titleKey); self.content = Text(value) }
    init<S: StringProtocol>(_ title: S, value: String) { self.label = Text(title); self.content = Text(value) }
}

struct ShareLink<Label: View>: View {
    let item: Any
    let label: Label
    init(item: URL, Subject: Text? = nil, message: Text? = nil, @ViewBuilder label: () -> Label) { self.item = item; self.label = label() }
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
    init(_ titleKey: LocalizedStringKey, item: URL, subject: Text? = nil, message: Text? = nil) {
        self.init(item: item, subject: subject, message: message) { SwiftUI.Label(titleKey, systemImage: "square.and.arrow.up") }
    }
    init(_ title: String, item: URL, subject: Text? = nil, message: Text? = nil) {
        self.init(item: item, subject: subject, message: message) { SwiftUI.Label(title, systemImage: "square.and.arrow.up") }
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    init<S: Shape>(_ wrapped: S) { _path = { rect in wrapped.path(in: rect) } }
    func path(in rect: CDRect) -> Path { _path(rect) }
}

enum ScrollIndicatorVisibilityCompat { case automatic, visible, hidden, never }
enum ToolbarPlacementCompat { case automatic, navigationBar, tabBar, bottomBar }

extension View {
    @ViewBuilder func fontWeight(_ weight: Font.Weight?) -> some View {
        if #available(iOS 16.0, *) { self.fontWeight(weight) } else { self }
    }
    -ViewBuilder func scrollContentBackground(_ visibility: Visibility) -> some View {
        if #available(iOS 16.0, *) { self.scrollContentBackground(visibility) } else { self }
    }
    @ViewBuilder func scrollIndicators(_ visibility: ScrollIndicatorVisibilityCompat, axes: Axis.Set = [.vertical, .horizontal]) -> some View {
        if #available(iOS 16.0, *) {
            switch visibility {
            case .hidden, .never: self.scrollIndicators(.hidden, axes: axes)
            case .visible: self.scrollIndicators(.visible, axes: axes)
            default: self.scrollIndicators(.automatic, axes: axes)
            }
        } else { self }
    }
    @ViewBuilder func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacementCompat...) -> some View {
        if #available(iOS 16.0, *) { self.toolbarBackground(visibility, for: .navigationBar) } else { self }
    }
    @ViewBuilder func toolbarBackground<S: ShapeStyle>(_ style: S, for bars: ToolbarPlacementCompat...) -> some View {
        if #available(iOS 16.0, *) { self.toolbarBackground(style, for: .navigationBar) } else { self }
    }
}
#endif
