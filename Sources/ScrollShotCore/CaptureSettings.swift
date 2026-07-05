import Foundation

public struct CaptureSettings: Equatable {
    public var maxFrames: Int
    public var scrollPixels: Int
    public var delayMilliseconds: Int
    public var reverseScroll: Bool
    public var minimumAppendPixels: Int
    public var stopAfterDuplicateFrames: Int

    public init(
        maxFrames: Int = 24,
        scrollPixels: Int = 720,
        delayMilliseconds: Int = 550,
        reverseScroll: Bool = false,
        minimumAppendPixels: Int = 80,
        stopAfterDuplicateFrames: Int = 2
    ) {
        self.maxFrames = max(2, maxFrames)
        self.scrollPixels = max(80, scrollPixels)
        self.delayMilliseconds = max(120, delayMilliseconds)
        self.reverseScroll = reverseScroll
        self.minimumAppendPixels = max(20, minimumAppendPixels)
        self.stopAfterDuplicateFrames = max(1, stopAfterDuplicateFrames)
    }
}
