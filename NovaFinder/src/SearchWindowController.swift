import AppKit
import Foundation

// MARK: - SearchWindow

private class SearchWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - RowItem

private enum RowItem {
    case sectionHeader(String)
    case history(HistoryItem)
    case command(CommandResult)

    var isHeader: Bool {
        if case .sectionHeader = self { return true }
        return false
    }
}

// MARK: - RoundedRowView

private class RoundedRowView: NSTableRowView {
    override var isEmphasized: Bool {
        get { return true }
        set {}
    }

    override func drawSelection(in dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 6, dy: 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        NSColor.selectedContentBackgroundColor.withAlphaComponent(0.15).setFill()
        path.fill()
    }
}

// MARK: - SectionHeaderView

private class SectionHeaderView: NSTableCellView {
    private let label = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .tertiaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) {
        label.stringValue = title.uppercased()
    }
}

// MARK: - HistoryCellView

private class HistoryCellView: NSTableCellView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let enterLabel = NSTextField(labelWithString: "↩")

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    override init(frame: NSRect) {
        super.init(frame: frame)

        iconView.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: nil)
        iconView.contentTintColor = .systemOrange
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        titleLabel.font = NSFont.systemFont(ofSize: 14)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        timeLabel.font = NSFont.systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabelColor
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)

        enterLabel.font = NSFont.systemFont(ofSize: 12)
        enterLabel.textColor = .tertiaryLabelColor
        enterLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(enterLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            timeLabel.trailingAnchor.constraint(equalTo: enterLabel.leadingAnchor, constant: -8),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),

            enterLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            enterLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(item: HistoryItem) {
        titleLabel.stringValue = item.query
        timeLabel.stringValue = HistoryCellView.relativeFormatter.localizedString(
            for: item.timestamp,
            relativeTo: Date()
        )
    }
}

// MARK: - CommandCellView

private class CommandCellView: NSTableCellView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let badgeView = NSTextField(labelWithString: "")
    private let enterLabel = NSTextField(labelWithString: "↩")

    private var badgeWidthConstraint: NSLayoutConstraint?

    override init(frame: NSRect) {
        super.init(frame: frame)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        titleLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        badgeView.wantsLayer = true
        badgeView.layer?.cornerRadius = 5
        badgeView.layer?.masksToBounds = true
        badgeView.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        badgeView.textColor = .white
        badgeView.alignment = .center
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeView)

        enterLabel.font = NSFont.systemFont(ofSize: 12)
        enterLabel.textColor = .tertiaryLabelColor
        enterLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(enterLabel)

        let badgeWidth = badgeView.widthAnchor.constraint(equalToConstant: 60)
        badgeWidthConstraint = badgeWidth

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            subtitleLabel.trailingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: -8),

            badgeView.trailingAnchor.constraint(equalTo: enterLabel.leadingAnchor, constant: -8),
            badgeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeView.heightAnchor.constraint(equalToConstant: 18),
            badgeWidth,

            enterLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            enterLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(result: CommandResult) {
        iconView.image = NSImage(systemSymbolName: result.iconName, accessibilityDescription: nil)
        iconView.contentTintColor = result.iconColor

        titleLabel.stringValue = result.title
        subtitleLabel.stringValue = result.subtitle

        badgeView.stringValue = result.badgeText
        badgeView.layer?.backgroundColor = result.badgeColor.cgColor

        let badgeFont = NSFont.systemFont(ofSize: 10, weight: .semibold)
        let textWidth = result.badgeText.size(withAttributes: [.font: badgeFont]).width
        badgeWidthConstraint?.constant = textWidth + 16
    }
}

// MARK: - SearchWindowController

class SearchWindowController: NSObject {

    // ウィンドウ幅は settings.json の window.width から取得
    private var windowWidth: CGFloat { CGFloat(StorageManager.shared.settings.window.width) }
    private let searchHeight: CGFloat = 68
    private let rowHeight: CGFloat = 52
    private let headerHeight: CGFloat = 28


    private var searchWindow: SearchWindow!
    private var effectView: NSVisualEffectView!
    private var iconView: NSImageView!
    private var searchField: NSTextField!
    private var separatorView: NSView!
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!

    
    private var rows: [RowItem] = []
    private var isCommandMode = false

    var isVisible: Bool { searchWindow?.isVisible ?? false }

    override init() {
        super.init()
        setupUI()
    }


    private func setupUI() {
        let rect = NSRect(x: 0, y: 0, width: windowWidth, height: searchHeight)
        searchWindow = SearchWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        searchWindow.level = .floating
        searchWindow.isOpaque = false
        searchWindow.backgroundColor = .clear
        searchWindow.hasShadow = false
        searchWindow.isMovableByWindowBackground = false
        searchWindow.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        searchWindow.delegate = self

        // エフェクト関連
        effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: searchHeight))
        effectView.material = .underWindowBackground
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16
        effectView.layer?.masksToBounds = true
        searchWindow.contentView = effectView

        // アイコン
        iconView = NSImageView(frame: NSRect(x: 20, y: (searchHeight - 24) / 2, width: 24, height: 24))
        iconView.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        iconView.contentTintColor = .secondaryLabelColor
        effectView.addSubview(iconView)

        // テキストボックス
        let fieldY = (searchHeight - 26) / 2
        searchField = NSTextField(frame: NSRect(x: 56, y: fieldY, width: windowWidth - 56 - 16, height: 26))
        searchField.isBezeled = false
        searchField.drawsBackground = false
        searchField.font = NSFont.systemFont(ofSize: 22, weight: .light)
        searchField.placeholderString = "検索、または / でコマンド..."
        searchField.focusRingType = .none
        searchField.delegate = self
        effectView.addSubview(searchField)

        // separatorView
        separatorView = NSView(frame: NSRect(x: 0, y: searchHeight, width: windowWidth, height: 1))
        separatorView.wantsLayer = true
        separatorView.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        separatorView.isHidden = true
        effectView.addSubview(separatorView)

        // tableView
        tableView = NSTableView()
        tableView.backgroundColor = .clear
        tableView.style = .plain
        tableView.headerView = nil
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.rowHeight = rowHeight
        tableView.focusRingType = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.action = #selector(tableViewClicked)
        tableView.target = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.width = windowWidth
        tableView.addTableColumn(column)

        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: 0))
        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        effectView.addSubview(scrollView)
    }

    // MARK: - Height calculation

    private func totalHeight() -> CGFloat {
        if rows.isEmpty { return searchHeight }
        let contentH = rows.reduce(0.0) { $0 + ($1.isHeader ? headerHeight : rowHeight) }
        return searchHeight + 1 + contentH + 8
    }

    // MARK: - Frame computation

    private func computeTargetFrame() -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let visibleFrame = screen.visibleFrame
        let height = totalHeight()
        let x = visibleFrame.midX - windowWidth / 2
        let ratio = CGFloat(StorageManager.shared.settings.window.verticalOffsetRatio)
        let y = visibleFrame.maxY - height - screen.frame.height * ratio
        return NSRect(x: x, y: y, width: windowWidth, height: height)
    }

    // MARK: - Subview layout

    private func updateSubviewFrames(windowHeight: CGFloat) {
        effectView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        effectView.layer?.cornerRadius = 16

        // AppKit: Y=0 is bottom
        let iconY = windowHeight - searchHeight + (searchHeight - 24) / 2
        iconView.frame = NSRect(x: 20, y: iconY, width: 24, height: 24)

        let fieldY = windowHeight - searchHeight + (searchHeight - 26) / 2
        searchField.frame = NSRect(x: 56, y: fieldY, width: windowWidth - 56 - 16, height: 26)

        separatorView.frame = NSRect(x: 0, y: windowHeight - searchHeight - 1, width: windowWidth, height: 1)

        let scrollHeight = windowHeight - searchHeight - 1 - 8
        scrollView.frame = NSRect(x: 0, y: 8, width: windowWidth, height: max(0, scrollHeight))

        let tableHeight = tableView.numberOfRows == 0 ? 0 : rows.reduce(0.0) {
            $0 + ($1.isHeader ? headerHeight : rowHeight)
        }
        tableView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: max(0, tableHeight))
    }

    // MARK: - Layout update

    private func updateLayout(animate: Bool) {
        guard let window = searchWindow else { return }
        let targetFrame = computeTargetFrame()
        separatorView.isHidden = rows.isEmpty

        updateSubviewFrames(windowHeight: targetFrame.height)

        if animate {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.18
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            window.setFrame(targetFrame, display: true)
        }
    }

    // MARK: - Icon appearance

    private func updateIconViewAppearance() {
        if isCommandMode {
            iconView.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
            iconView.contentTintColor = .systemPurple
        } else {
            iconView.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            iconView.contentTintColor = .secondaryLabelColor
        }
    }

    // MARK: - Row building

    private func buildRows(for input: String) -> [RowItem] {
        if input.hasPrefix("/") {
            let results = CommandHandler.shared.results(for: input)
            if results.isEmpty { return [] }
            return [.sectionHeader("コマンド")] + results.prefix(6).map { .command($0) }
        } else {
            let items = StorageManager.shared.filteredHistory(prefix: input)
            if items.isEmpty { return [] }
            return [.sectionHeader("最近の検索")] + items.prefix(6).map { .history($0) }
        }
    }

    // MARK: - Show / Hide

    func show() {
        rows = []
        searchField.stringValue = ""
        isCommandMode = false
        updateIconViewAppearance()
        separatorView.isHidden = true

        let targetFrame = computeTargetFrame()
        updateSubviewFrames(windowHeight: targetFrame.height)

        let startFrame = NSRect(
            x: targetFrame.origin.x + 20,
            y: targetFrame.origin.y - 8 + 10,
            width: targetFrame.width,
            height: targetFrame.height
        )

        searchWindow.setFrame(startFrame, display: false)
        searchWindow.alphaValue = 0
        searchWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.searchWindow.animator().setFrame(targetFrame, display: true)
            self.searchWindow.animator().alphaValue = 1.0
        }

        searchWindow.makeFirstResponder(searchField)
    }

    func hide() {
        guard let window = searchWindow else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            window.alphaValue = 1.0
        })
    }

    // MARK: - Execution

    private func executeCurrentInput() {
        let text = searchField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        if text.hasPrefix("/") {
            if let first = CommandHandler.shared.results(for: text).first {
                first.action()
                StorageManager.shared.addHistory(text)
            }
        } else {
            StorageManager.shared.addHistory(text)
            if let url = StorageManager.shared.searchURL(for: text) {
                NSWorkspace.shared.open(url)
            }
        }
        hide()
    }

    private func executeRow(_ row: RowItem) {
        switch row {
        case .history(let item):
            StorageManager.shared.addHistory(item.query)
            if let url = StorageManager.shared.searchURL(for: item.query) {
                NSWorkspace.shared.open(url)
            }
            hide()
        case .command(let result):
            result.action()
            StorageManager.shared.addHistory(searchField.stringValue)
            hide()
        case .sectionHeader:
            break
        }
    }

    // MARK: - Selection helpers

    private func firstSelectableRow() -> Int? {
        for (i, row) in rows.enumerated() where !row.isHeader {
            return i
        }
        return nil
    }

    private func nextSelectableRow(after index: Int) -> Int? {
        guard index + 1 < rows.count else { return nil }
        for i in (index + 1)..<rows.count where !rows[i].isHeader {
            return i
        }
        return nil
    }

    private func prevSelectableRow(before index: Int) -> Int? {
        guard index > 0 else { return nil }
        for i in stride(from: index - 1, through: 0, by: -1) where !rows[i].isHeader {
            return i
        }
        return nil
    }

    @objc private func tableViewClicked() {
        let row = tableView.clickedRow
        guard row >= 0, row < rows.count, !rows[row].isHeader else { return }
        executeRow(rows[row])
    }
}

// MARK: - NSTextFieldDelegate

extension SearchWindowController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let text = searchField.stringValue
        isCommandMode = text.hasPrefix("/")
        updateIconViewAppearance()

        rows = buildRows(for: text)
        tableView.reloadData()
        updateLayout(animate: true)

        if let first = firstSelectableRow() {
            tableView.selectRowIndexes(IndexSet(integer: first), byExtendingSelection: false)
        } else {
            tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
        }
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.cancelOperation(_:)):
            hide()
            return true

        case #selector(NSResponder.moveDown(_:)):
            let current = tableView.selectedRow
            let next: Int?
            if current < 0 {
                next = firstSelectableRow()
            } else {
                next = nextSelectableRow(after: current)
            }
            if let n = next {
                tableView.selectRowIndexes(IndexSet(integer: n), byExtendingSelection: false)
                tableView.scrollRowToVisible(n)
            }
            return true

        case #selector(NSResponder.moveUp(_:)):
            let current = tableView.selectedRow
            if current >= 0, let prev = prevSelectableRow(before: current) {
                tableView.selectRowIndexes(IndexSet(integer: prev), byExtendingSelection: false)
                tableView.scrollRowToVisible(prev)
            }
            return true

        case #selector(NSResponder.insertNewline(_:)):
            let selected = tableView.selectedRow
            if selected >= 0, selected < rows.count {
                executeRow(rows[selected])
            } else {
                executeCurrentInput()
            }
            return true

        default:
            return false
        }
    }
}

// MARK: - NSTableViewDataSource

extension SearchWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }
}

// MARK: - NSTableViewDelegate

extension SearchWindowController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard row < rows.count else { return rowHeight }
        return rows[row].isHeader ? headerHeight : rowHeight
    }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        guard row < rows.count else { return false }
        return rows[row].isHeader
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard row < rows.count else { return false }
        return !rows[row].isHeader
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard row < rows.count, !rows[row].isHeader else { return nil }
        return RoundedRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else { return nil }

        switch rows[row] {
        case .sectionHeader(let title):
            let id = NSUserInterfaceItemIdentifier("header")
            let view: SectionHeaderView
            if let reused = tableView.makeView(withIdentifier: id, owner: self) as? SectionHeaderView {
                view = reused
            } else {
                view = SectionHeaderView(
                    frame: NSRect(x: 0, y: 0, width: windowWidth, height: headerHeight)
                )
                view.identifier = id
            }
            view.configure(title: title)
            return view

        case .history(let item):
            let id = NSUserInterfaceItemIdentifier("history")
            let view: HistoryCellView
            if let reused = tableView.makeView(withIdentifier: id, owner: self) as? HistoryCellView {
                view = reused
            } else {
                view = HistoryCellView(
                    frame: NSRect(x: 0, y: 0, width: windowWidth, height: rowHeight)
                )
                view.identifier = id
            }
            view.configure(item: item)
            return view

        case .command(let result):
            let id = NSUserInterfaceItemIdentifier("command")
            let view: CommandCellView
            if let reused = tableView.makeView(withIdentifier: id, owner: self) as? CommandCellView {
                view = reused
            } else {
                view = CommandCellView(
                    frame: NSRect(x: 0, y: 0, width: windowWidth, height: rowHeight)
                )
                view.identifier = id
            }
            view.configure(result: result)
            return view
        }
    }
}

// MARK: - NSWindowDelegate

extension SearchWindowController: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
