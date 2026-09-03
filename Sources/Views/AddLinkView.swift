import SwiftUI
import UIKit

/// 添加连接：粘贴链接 / 扫码。
struct AddLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = ConnectionsStore.shared

    @State private var link = ""
    @State private var errorMessage: String?
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("在电脑端 ZCode 打开「手机连接」（左下角手机图标），把二维码里的链接扫进来或粘贴进来，之后一键连。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("连接链接") {
                    TextField("粘贴链接：https://…", text: $link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("add.urlField")
                }
                Section {
                    Button {
                        save()
                    } label: {
                        Label("保存连接", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("add.save")

                    Button {
                        showingScanner = true
                    } label: {
                        Label("扫码添加", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowBackground(Color.clear)
                }
                Section {
                    Text("提示：电脑端 ZCode 每次重新生成后，旧链接会失效，失效时回来重新扫码/粘贴即可。")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("添加连接")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("无法保存", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingScanner) {
                QRScannerView { code in
                    showingScanner = false
                    if let code {
                        link = code
                        save()
                    }
                }
                .ignoresSafeArea()
            }
        }
    }

    private func save() {
        guard let url = normalize(link) else {
            errorMessage = "链接格式不正确，应以 http(s):// 开头"
            return
        }
        let name = store.defaultName(for: url, index: store.connections.count + 1)
        store.add(name: name, url: url)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func normalize(_ raw: String) -> String? {
        var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        if t.hasPrefix("zcode://") {
            t = "https://" + t.dropFirst("zcode://".count)
        }
        if !t.hasPrefix("http://") && !t.hasPrefix("https://") {
            t = "https://" + t
        }
        guard let u = URL(string: t), let host = u.host, !host.isEmpty else { return nil }
        return t
    }
}
