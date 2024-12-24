import Cocoa
import Carbon.HIToolbox

class KeyMonitor {
    var texts: [String] = []
    var currentIndex = 0
    var lastShiftPress = Date.distantPast
    var eventTap: CFMachPort?
    
    init() {
        loadTextsFromFile()
    }
    
    func loadTextsFromFile() {
        // 假设文件位于项目的根目录
        let fileURL = URL(fileURLWithPath: "texts.txt")
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            texts = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        } catch {
            print("无法读取文件: \(error.localizedDescription)")
            exit(1)
        }
    }
    
    func start() {
        // 打印使用说明
        print("程序已启动！")
        print("预设的文本内容：")
        for (i, text) in texts.enumerated() {
            print("第 \(i + 1) 行: \(text)")
        }
        print("\n在任何地方按 Shift 键切换文本并自动粘贴")
        print("按 ESC 键退出程序")
        
        // 复制第一条文本到剪贴板
        if !texts.isEmpty {
            copyToPasteboard(texts[0])
        }
        
        // 创建事件监听
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<KeyMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                
                if type == .flagsChanged {
                    let flags = event.flags
                    if flags.contains(.maskShift) {
                        let now = Date()
                        if now.timeIntervalSince(monitor.lastShiftPress) > 0.3 {
                            monitor.lastShiftPress = now
                            monitor.switchTextAndPaste()
                        }
                    }
                } else if type == .keyDown {
                    let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                    if keycode == kVK_Escape {
                        exit(0)
                    }
                }
                
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("无法创建事件监听器。请确保已授予辅助功能权限。")
            exit(1)
        }
        
        self.eventTap = eventTap
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        CFRunLoopRun()
    }
    
    func switchTextAndPaste() {
        if texts.isEmpty { return }
        currentIndex = (currentIndex + 1) % texts.count
        let text = texts[currentIndex]
        copyToPasteboard(text)
        print("已复制到剪贴板并粘贴: \(text)")
        paste()
    }
    
    func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func paste() {
        let commandDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
        let vDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let vUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        let commandUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
        
        commandDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        
        commandDown?.post(tap: .cgAnnotatedSessionEventTap)
        vDown?.post(tap: .cgAnnotatedSessionEventTap)
        vUp?.post(tap: .cgAnnotatedSessionEventTap)
        commandUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}

// 启动程序
let monitor = KeyMonitor()
monitor.start()
