import AppKit
import Foundation

// コマンド類

struct CommandResult {
    let iconName: String
    let iconColor: NSColor
    let title: String
    let subtitle: String
    let badgeText: String
    let badgeColor: NSColor
    let action: () -> Void
}

protocol CommandProvider {
    var prefix: String { get }
    func results(for input: String) -> [CommandResult]?
}

// tarminal
class ShellCommandProvider: CommandProvider {
    let prefix = "/shell"

    func results(for input: String) -> [CommandResult]? {
        guard input.hasPrefix(prefix) else { return nil }

        let arg = String(input.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)

        if arg.isEmpty {
            return [CommandResult(
                iconName: "terminal",
                iconColor: .systemIndigo,
                title: "/shell",
                subtitle: "Terminalを開く",
                badgeText: "shell",
                badgeColor: .systemIndigo,
                action: {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
                        NSWorkspace.shared.openApplication(
                            at: url,
                            configuration: NSWorkspace.OpenConfiguration()
                        )
                    }
                }
            )]
        } else {
            let escaped = arg
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return [CommandResult(
                iconName: "terminal",
                iconColor: .systemIndigo,
                title: arg,
                subtitle: "Terminalでコマンドを実行",
                badgeText: "shell",
                badgeColor: .systemIndigo,
                action: {
                    let script = """
                    tell application "Terminal"
                        activate
                        do script "\(escaped)"
                    end tell
                    """
                    if let appleScript = NSAppleScript(source: script) {
                        var error: NSDictionary?
                        appleScript.executeAndReturnError(&error)
                    }
                }
            )]
        }
    }
}

// Finder
class OpenCommandProvider: CommandProvider {
    let prefix = "/open"

    func results(for input: String) -> [CommandResult]? {
        guard input.hasPrefix(prefix) else { return nil }

        let arg = String(input.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)

        if arg.isEmpty {
            return [CommandResult(
                iconName: "folder.badge.plus",
                iconColor: .systemBlue,
                title: "/open",
                subtitle: "Finderを開く",
                badgeText: "open",
                badgeColor: .systemBlue,
                action: {
                    let homeURL = URL(fileURLWithPath: NSHomeDirectory())
                    NSWorkspace.shared.open(homeURL)
                }
            )]
        } else {
            let expanded = (arg as NSString).expandingTildeInPath

            // URL判定: scheme を持つ場合はURL、そうでなければファイルパス
            if arg.contains("://"), let url = URL(string: arg)
            {
                return [CommandResult(
                    iconName: "folder.badge.plus",
                    iconColor: .systemBlue,
                    title: arg,
                    subtitle: "URLを開く",
                    badgeText: "open",
                    badgeColor: .systemBlue,
                    action: {
                        NSWorkspace.shared.open(url)
                    }
                )]
            }
            else
            {
                let fileURL = URL(fileURLWithPath: expanded)
                return [CommandResult(
                    iconName: "folder.badge.plus",
                    iconColor: .systemBlue,
                    title: arg,
                    subtitle: "パスを開く",
                    badgeText: "open",
                    badgeColor: .systemBlue,
                    action: {
                        NSWorkspace.shared.open(fileURL)
                    }
                )]
            }
        }
    }
}

//簡易電卓
class CalcCommandProvider: CommandProvider {
    let prefix = "/calc"

    func results(for input: String) -> [CommandResult]? {
        guard input.hasPrefix(prefix) else { return nil }

        let arg = String(input.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)

        if arg.isEmpty {
            return [CommandResult(
                iconName: "function",
                iconColor: .systemOrange,
                title: "/calc",
                subtitle: "数式を計算する",
                badgeText: "calc",
                badgeColor: .systemOrange,
                action: {}
            )]
        }

        let expr = NSExpression(format: arg)
        let evaluated = expr.expressionValue(with: nil, context: nil)
        let safeResultText: String
        if let value = evaluated {
            safeResultText = "= \(value)"
        } else {
            safeResultText = "= (計算不可)"
        }

        return [CommandResult(
            iconName: "function",
            iconColor: .systemOrange,
            title: safeResultText,
            subtitle: arg,
            badgeText: "calc",
            badgeColor: .systemOrange,
            action: {
                // = を除いた数値部分をコピー
                let toCopy = safeResultText.hasPrefix("= ") ? String(safeResultText.dropFirst(2)) : safeResultText
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(toCopy, forType: .string)
            }
        )]
    }
}

//

class CommandHandler {
    static let shared = CommandHandler()

    let providers: [CommandProvider] = [
        ShellCommandProvider(),
        OpenCommandProvider(),
        CalcCommandProvider()
    ]

    private init() {}

    func isCommand(_ input: String) -> Bool {
        return input.hasPrefix("/")
    }

    func results(for input: String) -> [CommandResult] {
        // "/" のみ → 各プロバイダの説明を1件ずつ返す
        if input == "/" {
            return providers.compactMap { provider in
                provider.results(for: provider.prefix)?.first
            }
        }

        // マッチするプロバイダを探す
        for provider in providers {
            if input.hasPrefix(provider.prefix) || provider.prefix.hasPrefix(input) {
                if let res = provider.results(for: input) {
                    return res
                }
            }
        }

        // どれにもマッチしない場合: 前方一致するプロバイダの説明を返す
        let matched = providers.compactMap { provider -> CommandResult? in
            guard provider.prefix.hasPrefix(input) else { return nil }
            return provider.results(for: provider.prefix)?.first
        }
        return matched
    }
}
