import Carbon

// グローバル関数: Cの関数ポインタとして渡す (Carbon コールバック)
func novaHotkeyCallback(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let ptr = userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(ptr).takeUnretainedValue()
    manager.invokeAction()
    return noErr
}

class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func invokeAction() {
        action()
    }

    func register() {
        let config = StorageManager.shared.settings.hotkey

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(), novaHotkeyCallback, 1, &spec, selfPtr, &handlerRef
        )

        let modifiers = carbonModifiers(from: config.modifiers)
        let hkid = EventHotKeyID(signature: fourCC("NOVA"), id: 1)
        RegisterEventHotKey(
            UInt32(config.keyCode),
            modifiers,
            hkid,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    // モディファイア名 → Carbon フラグ
    private func carbonModifiers(from names: [String]) -> UInt32 {
        var flags: UInt32 = 0
        for name in names {
            switch name.lowercased() {
            case "option", "alt":    flags |= UInt32(optionKey)
            case "command", "cmd":   flags |= UInt32(cmdKey)
            case "shift":            flags |= UInt32(shiftKey)
            case "control", "ctrl":  flags |= UInt32(controlKey)
            default: break
            }
        }
        return flags
    }

    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = handlerRef { RemoveEventHandler(ref) }
    }
}

private func fourCC(_ s: StaticString) -> FourCharCode {
    let bytes = s.utf8Start
    return (FourCharCode(bytes[0]) << 24)
         | (FourCharCode(bytes[1]) << 16)
         | (FourCharCode(bytes[2]) << 8)
         |  FourCharCode(bytes[3])
}
