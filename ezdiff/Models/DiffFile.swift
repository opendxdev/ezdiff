import Foundation
import Combine

@MainActor
class DiffFile: ObservableObject {
    @Published var url: URL?
    @Published var filename: String = ""
    @Published var content: String = ""
    @Published var detectedLanguage: DetectedLanguage = .plainText
    @Published var lastModified: Date?
    @Published var hasUnsavedChanges: Bool = false

    private var originalContent: String = ""

    var isBinary: Bool {
        guard let data = content.data(using: .utf8) else { return false }
        let checkLength = min(data.count, 8192)
        return data.prefix(checkLength).contains(0)
    }

    var isEmpty: Bool {
        url == nil && content.isEmpty
    }

    static func load(from fileURL: URL) throws -> DiffFile {
        let file = DiffFile()
        file.url = fileURL

        // Check for binary content
        let data = try Data(contentsOf: fileURL)
        let checkLength = min(data.count, 8192)
        let isBinaryFile = data.prefix(checkLength).contains(0)

        if isBinaryFile {
            // Generate hex dump for binary files
            file.content = DiffFile.hexDump(data: data)
        } else {
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
                throw NSError(domain: "ezdiff", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode file as text"])
            }
            file.content = text
        }

        file.originalContent = file.content
        file.filename = fileURL.lastPathComponent

        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        file.lastModified = attrs?[.modificationDate] as? Date

        file.detectedLanguage = LanguageDetector.detect(filename: file.filename, content: file.content)
        file.hasUnsavedChanges = false

        return file
    }

    func save() throws {
        guard let url = url else {
            throw NSError(domain: "ezdiff", code: 2, userInfo: [NSLocalizedDescriptionKey: "No file URL to save to"])
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
        originalContent = content
        hasUnsavedChanges = false

        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        lastModified = attrs?[.modificationDate] as? Date
    }

    func markEdited() {
        if content != originalContent {
            hasUnsavedChanges = true
        }
    }

    func clear() {
        url = nil
        filename = ""
        content = ""
        originalContent = ""
        detectedLanguage = .plainText
        lastModified = nil
        hasUnsavedChanges = false
    }

    private static func hexDump(data: Data) -> String {
        var result = ""
        let bytesPerLine = 16
        for offset in stride(from: 0, to: data.count, by: bytesPerLine) {
            let end = min(offset + bytesPerLine, data.count)
            let chunk = data[offset..<end]

            // Offset column
            result += String(format: "%08x  ", offset)

            // Hex columns
            for (i, byte) in chunk.enumerated() {
                result += String(format: "%02x ", byte)
                if i == 7 { result += " " }
            }
            // Pad if short line
            let missing = bytesPerLine - chunk.count
            for i in 0..<missing {
                result += "   "
                if chunk.count + i == 7 { result += " " }
            }

            // ASCII column
            result += " |"
            for byte in chunk {
                let char = (byte >= 0x20 && byte <= 0x7E) ? Character(UnicodeScalar(byte)) : Character(".")
                result.append(char)
            }
            result += "|\n"
        }
        return result
    }
}
