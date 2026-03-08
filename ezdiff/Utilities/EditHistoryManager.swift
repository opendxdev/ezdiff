import Foundation
import Combine

@MainActor
class EditHistoryManager: ObservableObject {

    struct Edit {
        let file: DiffFile
        let lineNumber: Int
        let oldText: String
        let newText: String
    }

    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    private var undoStack: [Edit] = []
    private var redoStack: [Edit] = []

    func recordEdit(file: DiffFile, lineNumber: Int, oldText: String, newText: String) {
        undoStack.append(Edit(file: file, lineNumber: lineNumber, oldText: oldText, newText: newText))
        redoStack.removeAll()
        updateState()
    }

    func undo() -> Edit? {
        guard let edit = undoStack.popLast() else { return nil }
        redoStack.append(edit)
        updateState()
        return edit
    }

    func redo() -> Edit? {
        guard let edit = redoStack.popLast() else { return nil }
        undoStack.append(edit)
        updateState()
        return edit
    }

    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
