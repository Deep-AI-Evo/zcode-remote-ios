import SwiftUI
import WebKit

/// 演示模式：加载内置演示页，让用户/审核员在无桌面会话时体验完整交互。
struct DemoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 32)
                }
                .accessibilityLabel("返回")
                Spacer()
                Text("演示模式")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Color.clear.frame(width: 34, height: 32)
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(Color.black.opacity(0.9))

            DemoWebView()
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

private struct DemoWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: cfg)
        if let url = Bundle.main.url(forResource: "demo", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: Bundle.main.resourceURL ?? url)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
