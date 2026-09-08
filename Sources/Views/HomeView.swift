import SwiftUI

/// 主界面：连接列表 + 空态 + 添加。
struct HomeView: View {
    @StateObject private var store = ConnectionsStore.shared
    @State private var showingAdd = false
    @State private var showingDemo = false
    @State private var autoOpened = false
    @State private var activeConnection: Connection?
    @State private var renamingConnection: Connection?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            Group {
                if store.connections.isEmpty {
                    emptyState
                } else {
                    connectionList
                }
            }
            .navigationTitle("Z-Code 远程手机工作台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("添加连接")
                    .accessibilityIdentifier("home.add")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddLinkView()
            }
            .fullScreenCover(item: $activeConnection) { conn in
                ConnectView(connection: conn)
            }
            .alert("重命名连接", isPresented: .init(
                get: { renamingConnection != nil },
                set: { if !$0 { renamingConnection = nil } }
            )) {
                TextField("名称", text: $renameText)
                Button("保存") {
                    if let conn = renamingConnection {
                        store.rename(id: conn.id, name: renameText)
                    }
                    renamingConnection = nil
                }
                Button("取消", role: .cancel) { renamingConnection = nil }
            }
            .task {
                // UI 测试：从干净状态开始
                if ProcessInfo.processInfo.arguments.contains("UITEST_RESET") {
                    store.removeAllForTesting()
                    autoOpened = true
                    return
                }
                // 恢复上次的连接页：重新打开 App 直接回到工作画面
                guard !autoOpened else { return }
                autoOpened = true
                if let last = store.lastConnection {
                    activeConnection = last
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "qr.code.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("扫码连接远程工作区")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("点右上角 ＋ 添加连接")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Button {
                showingDemo = true
            } label: {
                Text("体验演示")
                    .font(.footnote)
            }
            .buttonStyle(.bordered)
            .padding(.top, 6)
            .accessibilityIdentifier("home.demo")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(isPresented: $showingDemo) {
            DemoView()
        }
    }

    private var connectionList: some View {
        List {
            ForEach(store.connections) { conn in
                Button {
                    activeConnection = conn
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conn.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(conn.url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityIdentifier("home.card")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        store.remove(id: conn.id)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    Button {
                        renameText = conn.name
                        renamingConnection = conn
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    .tint(.indigo)
                    Button {
                        UIPasteboard.general.string = conn.url
                    } label: {
                        Label("复制链接", systemImage: "doc.on.doc")
                    }
                    .tint(.gray)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
