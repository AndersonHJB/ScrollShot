import AppKit
import Foundation

final class RegionSelectionController {
    private var windows: [NSWindow] = []
    private var completion: ((CGRect?) -> Void)?

    func selectRegion(activateApp: Bool = true, completion: @escaping (CGRect?) -> Void) {
        cancel()
        self.completion = completion

        for screen in NSScreen.screens {
            let window = SelectionWindow(screen: screen)
            let view = SelectionOverlayView(frame: window.contentView?.bounds ?? .zero)
            view.autoresizingMask = [.width, .height]
            view.onComplete = { [weak self, weak window] localRect in
                guard let self else { return }
                guard let window, let localRect else {
                    self.finish(nil)
                    return
                }
                let frame = window.frame
                let rect = CGRect(
                    x: frame.minX + localRect.minX,
                    y: frame.minY + localRect.minY,
                    width: localRect.width,
                    height: localRect.height
                ).standardized
                self.finish(rect)
            }
            view.onCancel = { [weak self] in
                self?.finish(nil)
            }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
        if activateApp {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func cancel() {
        finish(nil)
    }

    private func finish(_ rect: CGRect?) {
        let handler = completion
        completion = nil
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        handler?(rect)
    }
}

private final class SelectionWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        setFrame(screen.frame, display: true)
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { true }
}

private final class SelectionOverlayView: NSView {
    var onComplete: ((CGRect?) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: CGPoint?
    private var currentRect: CGRect = .zero

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        window?.makeFirstResponder(self)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.28).setFill()
        bounds.fill()

        guard !currentRect.isEmpty else { return }

        NSGraphicsContext.current?.cgContext.saveGState()
        NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
        NSColor.clear.setFill()
        currentRect.fill()
        NSGraphicsContext.current?.cgContext.restoreGState()

        NSColor.systemBlue.setStroke()
        let path = NSBezierPath(rect: currentRect)
        path.lineWidth = 2
        path.stroke()

        let label = "\(Int(currentRect.width)) x \(Int(currentRect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.55)
        ]
        label.draw(
            at: CGPoint(x: currentRect.minX + 8, y: currentRect.maxY + 8),
            withAttributes: attributes
        )
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        currentRect = CGRect(
            x: min(startPoint.x, point.x),
            y: min(startPoint.y, point.y),
            width: abs(startPoint.x - point.x),
            height: abs(startPoint.y - point.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard currentRect.width >= 8, currentRect.height >= 8 else {
            onComplete?(nil)
            return
        }
        onComplete?(currentRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }
}
