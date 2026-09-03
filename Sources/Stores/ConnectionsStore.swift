import Foundation

struct Connection: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    let url: String
    let createdAt: Date
}

/// 连接与"最后活动连接"均存 UserDefaults（JSON），纯本地。
final class ConnectionsStore: ObservableObject {
    static let shared = ConnectionsStore()

    @Published private(set) var connections: [Connection] = []

    private let key = "zcode_remote_connections"
    private let lastKey = "zcode_remote_last_connection"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    private func load() {
        guard let data = defaults.data(forKey: key) else { return }
        connections = (try? JSONDecoder().decode([Connection].self, from: data)) ?? []
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(connections) {
            defaults.set(data, forKey: key)
        }
    }

    func add(name: String, url: String) -> Connection {
        let conn = Connection(
            id: UUID().uuidString,
            name: name,
            url: url,
            createdAt: Date()
        )
        connections.insert(conn, at: 0)
        persist()
        return conn
    }

    func get(id: String) -> Connection? {
        connections.first { $0.id == id }
    }

    func remove(id: String) {
        connections.removeAll { $0.id == id }
        if lastConnectionId == id {
            saveLastConnection(nil)
        }
        persist()
    }

    /// 仅供 UI 测试：清空全部数据。
    func removeAllForTesting() {
        connections.removeAll()
        saveLastConnection(nil)
        persist()
    }

    // MARK: - 最后活动连接（重启后自动回到连接页；主动退出时清除）

    var lastConnectionId: String? {
        defaults.string(forKey: lastKey)
    }

    func saveLastConnection(_ id: String?) {
        defaults.set(id, forKey: lastKey)
    }

    var lastConnection: Connection? {
        lastConnectionId.flatMap { get(id: $0) }
    }

    func defaultName(for url: String, index: Int) -> String {
        if let host = URL(string: url)?.host, !host.isEmpty {
            return host
        }
        return "连接 \(index)"
    }
}
