import AppKit

final class AttributedStringCache {

    private var cache: [Int: NSAttributedString] = [:]
    private var orderMap: [Int: LinkedListNode] = [:]
    private var head: LinkedListNode?
    private var tail: LinkedListNode?
    private var count = 0
    private let capacity: Int

    init(capacity: Int = Constants.Capacity.attributedStringCache) {
        self.capacity = capacity
    }

    func get(
        row: Int,
        rowData: any DiffRowData,
        lineTokens: [LineHighlightToken],
        appearance: AppearanceManager
    ) -> NSAttributedString {
        if let cached = cache[row] {
            moveToTail(row)
            return cached
        }

        let built = AttributedStringBuilder.build(
            row: rowData,
            lineTokens: lineTokens,
            appearance: appearance
        )

        cache[row] = built
        appendNode(row)

        while count > capacity {
            evictHead()
        }

        return built
    }

    func invalidateAll() {
        cache.removeAll()
        orderMap.removeAll()
        head = nil
        tail = nil
        count = 0
    }

    // MARK: - Doubly-linked list for O(1) LRU

    private final class LinkedListNode {
        let key: Int
        var prev: LinkedListNode?
        var next: LinkedListNode?
        init(key: Int) { self.key = key }
    }

    private func appendNode(_ key: Int) {
        let node = LinkedListNode(key: key)
        orderMap[key] = node
        if let t = tail {
            t.next = node
            node.prev = t
            tail = node
        } else {
            head = node
            tail = node
        }
        count += 1
    }

    private func moveToTail(_ key: Int) {
        guard let node = orderMap[key], node !== tail else { return }
        // Detach
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if node === head { head = node.next }
        // Append at tail
        node.prev = tail
        node.next = nil
        tail?.next = node
        tail = node
    }

    private func evictHead() {
        guard let h = head else { return }
        cache.removeValue(forKey: h.key)
        orderMap.removeValue(forKey: h.key)
        head = h.next
        head?.prev = nil
        if h === tail { tail = nil }
        count -= 1
    }
}
