import SwiftUI
import WebKit
import PhotosUI
import UniformTypeIdentifiers

/// 连接页：WKWebView 全屏 + 顶部浮动工具条（返回/刷新/更多/收起）。
struct ConnectView: View {
    let connection: Connection

    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = ConnectionsStore.shared
    @StateObject private var host = WebViewHost()

    @AppStorage("zcode_remote_toolbar_collapsed") private var collapsed = false
    @State private var progress: Double = 0
    @State private var loadError: String?

    var body: some View {
        ZStack(alignment: .top) {
            WebViewRep(host: host, connection: connection,
                       onProgress: { progress = $0 },
                       onError: { loadError = $0 })
                .ignoresSafeArea(edges: .bottom)

            if progress < 1 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .padding(.horizontal, 2)
            }

            toolbarOverlay
        }
        .background(Color.black.ignoresSafeArea())
        .alert("加载失败", isPresented: .init(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("刷新") { host.webView.reload() }
            Button("好", role: .cancel) {}
        } message: {
            Text(loadError ?? "")
        }
    }

    // MARK: - 浮动工具条

    @ViewBuilder
    private var toolbarOverlay: some View {
        if collapsed {
            Button {
                withAnimation { collapsed = false }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.black.opacity(0.85)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 8)
            .accessibilityLabel("展开工具条")
        } else {
            HStack(spacing: 2) {
                barButton("chevron.left", "返回") { exitToMain() }
                barButton("arrow.clockwise", "刷新") { host.webView.reload() }
                Menu {
                    Button {
                        if let u = URL(string: connection.url) {
                            UIApplication.shared.open(u)
                        }
                    } label: {
                        Label("在 Safari 打开", systemImage: "safari")
                    }
                    Button {
                        // 与 Android 版一致：清除记忆并退回列表，再由列表页添加新链接
                        store.saveLastConnection(nil)
                        dismiss()
                    } label: {
                        Label("更换链接", systemImage: "link.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 32)
                }
                .accessibilityLabel("更多")
                barButton("chevron.down", "收起工具条") {
                    withAnimation { collapsed = true }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(Capsule().fill(Color.black.opacity(0.85)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func barButton(_ system: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34, height: 32)
        }
        .accessibilityLabel(label)
    }

    /// 主动退出连接：清除"最后连接"记忆并返回列表。
    private func exitToMain() {
        store.saveLastConnection(nil)
        dismiss()
    }
}

// MARK: - WebView 宿主（持有 WKWebView，便于外部 reload）

@MainActor
final class WebViewHost: ObservableObject {
    let webView: WKWebView

    init() {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        webView.scrollView.keyboardDismissMode = .interactive
    }
}

// MARK: - UIViewRepresentable

struct WebViewRep: UIViewRepresentable {
    let host: WebViewHost
    let connection: Connection
    var onProgress: (Double) -> Void
    var onError: (String) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = host.webView
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.onProgress = onProgress
        context.coordinator.onError = onError

        let target = connection.url
        // 页面尚未加载时才载入（SwiftUI 重建不重载）
        if webView.url == nil || webView.url?.absoluteString != target {
            webView.load(URLRequest(url: URL(string: target)!))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onProgress = onProgress
        context.coordinator.onError = onError
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var onProgress: (Double) -> Void = { _ in }
        var onError: (String) -> Void = { _ in }
        private var observation: NSKeyValueObservation?
        // 强持有，防止 delegate(weak) 提前释放导致回调丢失
        private var activePickerDelegate: PickerCoordinator?

        func attachProgressObserver(_ webView: WKWebView) {
            observation?.invalidate()
            observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.onProgress(wv.estimatedProgress)
                }
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            attachProgressObserver(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.onProgress(1) }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.onProgress(0)
                self.onError("网络异常或链接已失效，可刷新重试；也可退出后更换链接")
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.onError("页面执行出错：\(error.localizedDescription)") }
        }

        // MARK: 文件上传（网页 <input type=file>）：PHPicker / 文件选择器，无需存储权限

        func webView(
            _ webView: WKWebView,
            runFilePickerPanelWith parameters: WKFileUploadParameters,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping ([URL]?) -> Void
        ) {
            let wantsMedia = parameters.allowedMIMETypes.isEmpty
                || parameters.allowedMIMETypes.contains { $0.hasPrefix("image/") || $0.hasPrefix("video/") }

            if wantsMedia {
                var config = PHPickerConfiguration()
                config.filter = [.images, .videos]
                config.selectionLimit = parameters.allowsMultipleSelection ? 0 : 1
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = contextlessPickerDelegate(completionHandler: completionHandler)
                present(picker, from: webView)
            } else {
                var types: [UTType] = parameters.allowedMIMETypes.compactMap(UTType.init(mimeType:))
                if types.isEmpty { types = [.data] }
                let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
                picker.allowsMultipleSelection = parameters.allowsMultipleSelection
                picker.delegate = contextlessPickerDelegate(completionHandler: completionHandler)
                present(picker, from: webView)
            }
        }

        private func present(_ picker: UIViewController, from webView: WKWebView) {
            var top = webView.window?.rootViewController
            while let presented = top?.presentedViewController { top = presented }
            top?.present(picker, animated: true)
        }

        private func contextlessPickerDelegate(completionHandler: @escaping ([URL]?) -> Void)
            -> PickerCoordinator {
            let delegate = PickerCoordinator(completion: completionHandler)
            activePickerDelegate = delegate
            return delegate
        }
    }
}

// MARK: - 文件选择回调（PHPicker + DocumentPicker）

final class PickerCoordinator: NSObject, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
    let completion: ([URL]?) -> Void

    init(completion: @escaping ([URL]?) -> Void) {
        self.completion = completion
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else {
            completion(nil)
            return
        }
        let typeIdentifiers = provider.registeredTypeIdentifiers
        guard let typeId = typeIdentifiers.first else {
            completion(nil)
            return
        }
        provider.loadFileRepresentation(forTypeIdentifier: typeId) { [weak self] url, _ in
            guard let self, let url else {
                DispatchQueue.main.async { self?.completion(nil) }
                return
            }
            let name = url.lastPathComponent.isEmpty ? UUID().uuidString : url.lastPathComponent
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: tmp)
            do {
                try FileManager.default.copyItem(at: url, to: tmp)
                DispatchQueue.main.async { self.completion([tmp]) }
            } catch {
                DispatchQueue.main.async { self.completion(nil) }
            }
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let picked: [URL] = urls.compactMap { u in
            let scoped = u.startAccessingSecurityScopedResource()
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(u.lastPathComponent)
            try? FileManager.default.removeItem(at: tmp)
            guard (try? FileManager.default.copyItem(at: u, to: tmp)) != nil else {
                if scoped { u.stopAccessingSecurityScopedResource() }
                return nil
            }
            if scoped { u.stopAccessingSecurityScopedResource() }
            return tmp
        }
        completion(picked.isEmpty ? nil : picked)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion(nil)
    }
}
