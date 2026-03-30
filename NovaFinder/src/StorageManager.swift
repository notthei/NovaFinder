import Foundation

struct HistoryItem: Codable, Equatable {
    var query: String
    var timestamp: Date
}

struct Settings: Codable {
    var searchEngine: String   // %@ がクエリに置き換わる
    var maxHistory: Int

    static let `default` = Settings(
        searchEngine: "https://www.google.com/search?q=%@",
        maxHistory: 50
    )
}

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
        encoder.outputFormatting = .prettyPrinted
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
