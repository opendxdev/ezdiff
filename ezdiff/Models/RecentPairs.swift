import Foundation

struct RecentPair: Codable, Identifiable, Sendable {
    var id: String { "\(leftPath)-\(rightPath)-\(timestamp.timeIntervalSince1970)" }
    let leftPath: String
    let rightPath: String
    let timestamp: Date

    var leftFilename: String {
        (leftPath as NSString).lastPathComponent
    }

    var rightFilename: String {
        (rightPath as NSString).lastPathComponent
    }
}

struct RecentPairs {
    private static let key = "dev.opendx.ezdiff.recentPairs"
    private static let maxPairs = 5

    static func add(left: URL, right: URL) {
        var current = pairs
        // Remove duplicate if same pair exists
        current.removeAll { $0.leftPath == left.path && $0.rightPath == right.path }
        let pair = RecentPair(leftPath: left.path, rightPath: right.path, timestamp: Date())
        current.insert(pair, at: 0)
        if current.count > maxPairs {
            current = Array(current.prefix(maxPairs))
        }
        save(current)
    }

    static var pairs: [RecentPair] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([RecentPair].self, from: data)
        else {
            return []
        }
        return decoded
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func save(_ pairs: [RecentPair]) {
        guard let data = try? JSONEncoder().encode(pairs) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
