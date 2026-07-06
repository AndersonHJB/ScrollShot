import AppKit
import Carbon.HIToolbox
import Foundation

enum GlobalHotKeyCommand: UInt32, CaseIterable {
    case startLongCapture = 1
    case selectRegion = 2
    case cancelCapture = 3

    static let userInfoKey = "ScrollShotGlobalHotKeyCommand"

    var defaultHotKey: GlobalHotKey {
        switch self {
        case .startLongCapture:
            return GlobalHotKey(keyCode: UInt32(kVK_ANSI_S), modifiers: GlobalHotKey.defaultModifiers)
        case .selectRegion:
            return GlobalHotKey(keyCode: UInt32(kVK_ANSI_R), modifiers: GlobalHotKey.defaultModifiers)
        case .cancelCapture:
            return GlobalHotKey(keyCode: UInt32(kVK_ANSI_X), modifiers: GlobalHotKey.defaultModifiers)
        }
    }

    var title: String {
        switch self {
        case .startLongCapture:
            return "开始长截图"
        case .selectRegion:
            return "重新框选"
        case .cancelCapture:
            return "停止/取消"
        }
    }

    fileprivate var storageKey: String {
        "GlobalHotKey.\(rawValue)"
    }
}

extension Notification.Name {
    static let scrollShotGlobalHotKey = Notification.Name("ScrollShotGlobalHotKey")
    static let scrollShotGlobalHotKeySettingsDidChange = Notification.Name("ScrollShotGlobalHotKeySettingsDidChange")
}

struct GlobalHotKey: Codable, Equatable, Hashable {
    static let defaultModifiers = UInt32(cmdKey | optionKey | controlKey)
    static let fallbackModifier = UInt32(controlKey)
    static let modifierOptions: [GlobalHotKeyModifier] = [
        GlobalHotKeyModifier(symbol: "⌃", name: "Control", flag: UInt32(controlKey)),
        GlobalHotKeyModifier(symbol: "⌥", name: "Option", flag: UInt32(optionKey)),
        GlobalHotKeyModifier(symbol: "⇧", name: "Shift", flag: UInt32(shiftKey)),
        GlobalHotKeyModifier(symbol: "⌘", name: "Command", flag: UInt32(cmdKey))
    ]
    static let keyOptions: [GlobalHotKeyKeyOption] = [
        GlobalHotKeyKeyOption(label: "A", keyCode: UInt32(kVK_ANSI_A)),
        GlobalHotKeyKeyOption(label: "B", keyCode: UInt32(kVK_ANSI_B)),
        GlobalHotKeyKeyOption(label: "C", keyCode: UInt32(kVK_ANSI_C)),
        GlobalHotKeyKeyOption(label: "D", keyCode: UInt32(kVK_ANSI_D)),
        GlobalHotKeyKeyOption(label: "E", keyCode: UInt32(kVK_ANSI_E)),
        GlobalHotKeyKeyOption(label: "F", keyCode: UInt32(kVK_ANSI_F)),
        GlobalHotKeyKeyOption(label: "G", keyCode: UInt32(kVK_ANSI_G)),
        GlobalHotKeyKeyOption(label: "H", keyCode: UInt32(kVK_ANSI_H)),
        GlobalHotKeyKeyOption(label: "I", keyCode: UInt32(kVK_ANSI_I)),
        GlobalHotKeyKeyOption(label: "J", keyCode: UInt32(kVK_ANSI_J)),
        GlobalHotKeyKeyOption(label: "K", keyCode: UInt32(kVK_ANSI_K)),
        GlobalHotKeyKeyOption(label: "L", keyCode: UInt32(kVK_ANSI_L)),
        GlobalHotKeyKeyOption(label: "M", keyCode: UInt32(kVK_ANSI_M)),
        GlobalHotKeyKeyOption(label: "N", keyCode: UInt32(kVK_ANSI_N)),
        GlobalHotKeyKeyOption(label: "O", keyCode: UInt32(kVK_ANSI_O)),
        GlobalHotKeyKeyOption(label: "P", keyCode: UInt32(kVK_ANSI_P)),
        GlobalHotKeyKeyOption(label: "Q", keyCode: UInt32(kVK_ANSI_Q)),
        GlobalHotKeyKeyOption(label: "R", keyCode: UInt32(kVK_ANSI_R)),
        GlobalHotKeyKeyOption(label: "S", keyCode: UInt32(kVK_ANSI_S)),
        GlobalHotKeyKeyOption(label: "T", keyCode: UInt32(kVK_ANSI_T)),
        GlobalHotKeyKeyOption(label: "U", keyCode: UInt32(kVK_ANSI_U)),
        GlobalHotKeyKeyOption(label: "V", keyCode: UInt32(kVK_ANSI_V)),
        GlobalHotKeyKeyOption(label: "W", keyCode: UInt32(kVK_ANSI_W)),
        GlobalHotKeyKeyOption(label: "X", keyCode: UInt32(kVK_ANSI_X)),
        GlobalHotKeyKeyOption(label: "Y", keyCode: UInt32(kVK_ANSI_Y)),
        GlobalHotKeyKeyOption(label: "Z", keyCode: UInt32(kVK_ANSI_Z)),
        GlobalHotKeyKeyOption(label: "0", keyCode: UInt32(kVK_ANSI_0)),
        GlobalHotKeyKeyOption(label: "1", keyCode: UInt32(kVK_ANSI_1)),
        GlobalHotKeyKeyOption(label: "2", keyCode: UInt32(kVK_ANSI_2)),
        GlobalHotKeyKeyOption(label: "3", keyCode: UInt32(kVK_ANSI_3)),
        GlobalHotKeyKeyOption(label: "4", keyCode: UInt32(kVK_ANSI_4)),
        GlobalHotKeyKeyOption(label: "5", keyCode: UInt32(kVK_ANSI_5)),
        GlobalHotKeyKeyOption(label: "6", keyCode: UInt32(kVK_ANSI_6)),
        GlobalHotKeyKeyOption(label: "7", keyCode: UInt32(kVK_ANSI_7)),
        GlobalHotKeyKeyOption(label: "8", keyCode: UInt32(kVK_ANSI_8)),
        GlobalHotKeyKeyOption(label: "9", keyCode: UInt32(kVK_ANSI_9))
    ]

    var keyCode: UInt32
    var modifiers: UInt32

    var displayShortcut: String {
        let symbols = Self.modifierOptions
            .filter { hasModifier($0.flag) }
            .map(\.symbol)
            .joined()
        return symbols + keyLabel
    }

    var keyLabel: String {
        Self.keyOptions.first { $0.keyCode == keyCode }?.label ?? "?"
    }

    func hasModifier(_ modifier: UInt32) -> Bool {
        modifiers & modifier != 0
    }

    func settingModifier(_ modifier: UInt32, enabled: Bool) -> GlobalHotKey {
        var updatedModifiers = modifiers
        if enabled {
            updatedModifiers |= modifier
        } else {
            updatedModifiers &= ~modifier
        }
        if updatedModifiers == 0 {
            updatedModifiers = Self.fallbackModifier
        }
        return GlobalHotKey(keyCode: keyCode, modifiers: updatedModifiers)
    }

    func settingKeyCode(_ keyCode: UInt32) -> GlobalHotKey {
        GlobalHotKey(keyCode: keyCode, modifiers: modifiers == 0 ? Self.fallbackModifier : modifiers)
    }
}

struct GlobalHotKeyModifier: Identifiable, Hashable {
    let symbol: String
    let name: String
    let flag: UInt32

    var id: UInt32 { flag }
}

struct GlobalHotKeyKeyOption: Identifiable, Hashable {
    let label: String
    let keyCode: UInt32

    var id: UInt32 { keyCode }
}

enum GlobalHotKeyPreferences {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func hotKeys() -> [GlobalHotKeyCommand: GlobalHotKey] {
        Dictionary(uniqueKeysWithValues: GlobalHotKeyCommand.allCases.map { command in
            (command, hotKey(for: command))
        })
    }

    static func hotKey(for command: GlobalHotKeyCommand) -> GlobalHotKey {
        guard
            let data = UserDefaults.standard.data(forKey: command.storageKey),
            let hotKey = try? decoder.decode(GlobalHotKey.self, from: data),
            GlobalHotKey.keyOptions.contains(where: { $0.keyCode == hotKey.keyCode }),
            hotKey.modifiers != 0
        else {
            return command.defaultHotKey
        }
        return hotKey
    }

    static func setHotKey(_ hotKey: GlobalHotKey, for command: GlobalHotKeyCommand) {
        let normalized = hotKey.modifiers == 0
            ? GlobalHotKey(keyCode: hotKey.keyCode, modifiers: GlobalHotKey.fallbackModifier)
            : hotKey
        if let data = try? encoder.encode(normalized) {
            UserDefaults.standard.set(data, forKey: command.storageKey)
        }
        NotificationCenter.default.post(name: .scrollShotGlobalHotKeySettingsDidChange, object: nil)
    }

    static func resetHotKey(for command: GlobalHotKeyCommand) {
        UserDefaults.standard.removeObject(forKey: command.storageKey)
        NotificationCenter.default.post(name: .scrollShotGlobalHotKeySettingsDidChange, object: nil)
    }

    static func resetAll() {
        for command in GlobalHotKeyCommand.allCases {
            UserDefaults.standard.removeObject(forKey: command.storageKey)
        }
        NotificationCenter.default.post(name: .scrollShotGlobalHotKeySettingsDidChange, object: nil)
    }
}

final class GlobalHotKeyManager {
    private static let signature: OSType = 0x53485354 // SHST

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?
    private var settingsObserver: NSObjectProtocol?

    func register() {
        unregisterHotKeys()
        installEventHandler()
        startObservingSettings()

        for command in GlobalHotKeyCommand.allCases {
            let hotKey = GlobalHotKeyPreferences.hotKey(for: command)
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: command.rawValue)
            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                hotKey.keyCode,
                hotKey.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let hotKeyRef {
                hotKeyRefs.append(hotKeyRef)
            } else {
                NSLog("ScrollShot failed to register global hot key %@ (%d)", hotKey.displayShortcut, status)
            }
        }
    }

    func unregister() {
        unregisterHotKeys()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
            self.settingsObserver = nil
        }
    }

    deinit {
        unregister()
    }

    private func unregisterHotKeys() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }

    private func startObservingSettings() {
        guard settingsObserver == nil else { return }
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .scrollShotGlobalHotKeySettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.register()
        }
    }

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard parameterStatus == noErr, hotKeyID.signature == GlobalHotKeyManager.signature else {
                    return OSStatus(eventNotHandledErr)
                }

                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleHotKey(id: hotKeyID.id)
                return noErr
            },
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        if status != noErr {
            NSLog("ScrollShot failed to install global hot key handler (%d)", status)
        }
    }

    private func handleHotKey(id: UInt32) {
        guard let command = GlobalHotKeyCommand(rawValue: id) else { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .scrollShotGlobalHotKey,
                object: self,
                userInfo: [GlobalHotKeyCommand.userInfoKey: command]
            )
        }
    }
}
