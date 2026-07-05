import Foundation

enum OutputPathFactory {
    static var outputDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures", isDirectory: true)
            .appendingPathComponent("ScrollShot", isDirectory: true)
    }

    static func nextPNGURL(date: Date = Date()) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return outputDirectory.appendingPathComponent("scrollshot-\(formatter.string(from: date)).png")
    }
}
