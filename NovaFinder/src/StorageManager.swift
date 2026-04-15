import Foundation

struct HistoryItem: Codable, Equatable {
    var query: String
    var timestamp: Date
}

// MARK: - Hotkey Config

struct HotkeyConfig: Codable {
    var keyCode: Int        // Carbon仮想キーコード (例: 44 = スラッシュ)
    var modifiers: [String] // "option", "command", "shift", "control"

    static let `default` = HotkeyConfig(keyCode: 44, modifiers: ["option"])
}

// MARK: - Window Config

struct WindowConfig: Codable {
    var width: Double               // ウィンドウ幅 (px)
    var verticalOffsetRatio: Double // 上端からの比率 (0.0〜1.0)

    static let `default` = WindowConfig(width: 660, verticalOffsetRatio: 0.22)
}

// MARK: - Custom Command Config

struct CustomCommandConfig: Codable {
    var prefix: String   // コマンドプレフィックス (例: "/git")
    var title: String    // 表示タイトル
    var subtitle: String // サブタイトル
    var iconName: String // SF Symbolsのアイコン名
    var badgeText: String
    var command: String  // 実行するシェルコマンド
}

// MARK: - Settings

struct Settings: Codable {
    var searchEngine: String
    var maxHistory: Int
    var hotkey: HotkeyConfig
    var window: WindowConfig
    var customCommands: [CustomCommandConfig]

    static let `default` = Settings(
        searchEngine: "https://www.google.com/search?q=%@",
        maxHistory: 50,
        hotkey: .default,
        window: .default,
        customCommands: []
    )

    // 旧フォーマットとの互換性: 存在しないキーはデフォルト値にフォールバック
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        searchEngine  = (try? c.decode(String.self,                    forKey: .searchEngine))  ?? Settings.default.searchEngine
        maxHistory    = (try? c.decode(Int.self,                       forKey: .maxHistory))    ?? Settings.default.maxHistory
        hotkey        = (try? c.decode(HotkeyConfig.self,              forKey: .hotkey))        ?? .default
        window        = (try? c.decode(WindowConfig.self,              forKey: .window))        ?? .default
        customCommands = (try? c.decode([CustomCommandConfig].self,    forKey: .customCommands)) ?? []
    }

    init(searchEngine: String, maxHistory: Int, hotkey: HotkeyConfig,
         window: WindowConfig, customCommands: [CustomCommandConfig]) {
        self.searchEngine   = searchEngine
        self.maxHistory     = maxHistory
        self.hotkey         = hotkey
        self.window         = window
        self.customCommands = customCommands
    }
}

// MARK: - StorageManager

class StorageManager {
    static let shared = StorageManager()

    private let baseDir: URL
    private let historyURL: URL
    private let settingsURL: URL

    private(set) var history: [HistoryItem] = []
    private(set) var settings: Settings = .default

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        baseDir = home.appendingPathComponent(".novafinder")
        historyURL = baseDir.appendingPathComponent("history.json")
        settingsURL = baseDir.appendingPathComponent("settings.json")

        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Load

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = try? Data(contentsOf: historyURL),
           let items = try? decoder.decode([HistoryItem].self, from: data) {
            history = items
        }
        if let data = try? Data(contentsOf: settingsURL),
           let s = try? decoder.decode(Settings.self, from: data) {
            settings = s
        }
    }

    // MARK: - Save

    private func saveHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(history) {
            try? data.write(to: historyURL)
        }
    }

    func saveSettings() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(settings) {
            try? data.write(to: settingsURL)
        }
    }

    // MARK: - History operations

    func addHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        history.removeAll { $0.query == trimmed }
        history.insert(HistoryItem(query: trimmed, timestamp: Date()), at: 0)
        if history.count > settings.maxHistory {
            history = Array(history.prefix(settings.maxHistory))
        }
        saveHistory()
    }

    func filteredHistory(prefix: String) -> [HistoryItem] {
        if prefix.isEmpty { return Array(history.prefix(5)) }
        return history.filter {
            $0.query.localizedCaseInsensitiveContains(prefix)
        }.prefix(5).map { $0 }
    }

    func searchURL(for query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlStr = String(format: settings.searchEngine, encoded)
        return URL(string: urlStr)
    }
}
