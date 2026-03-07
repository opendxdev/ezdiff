import AppKit

final class AttributedStringCache {

    private var cache: [Int: NSAttributedString] = [:]
    private var accessOrder: [Int] = []
    private let capacity: Int

    init(capacity: Int = 500) {
        self.capacity = capacity
    }

    func get(
        row: Int,
        rowData: any DiffRowData,
        lineTokens: [LineHighlightToken],
        appearance: AppearanceManager
    ) -> NSAttributedString {
        if let cached = cache[row] {
            // Move to end of access order
            if let idx = accessOrder.firstIndex(of: row) {
                accessOrder.remove(at: idx)
            }
            accessOrder.append(row)
            return cached
        }

        let built = AttributedStringBuilder.build(
            row: rowData,
            lineTokens: lineTokens,
            appearance: appearance
        )

        cache[row] = built
        accessOrder.append(row)

        // Evict oldest if over capacity
        while accessOrder.count > capacity {
            let evicted = accessOrder.removeFirst()
            cache.removeValue(forKey: evicted)
        }

        return built
    }

    func invalidateAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}
