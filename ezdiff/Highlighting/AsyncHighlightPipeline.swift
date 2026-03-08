import Foundation
import Combine

@MainActor
class AsyncHighlightPipeline: ObservableObject {
    @Published var tokens: [HighlightToken] = []

    private var cancellable: AnyCancellable?
    private let inputSubject = PassthroughSubject<(String, DetectedLanguage), Never>()
    private let highlightQueue = DispatchQueue(label: "dev.opendx.ezdiff.highlight", qos: .userInitiated)

    init() {
        cancellable = inputSubject
            .debounce(for: .milliseconds(Constants.Timing.highlightDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] source, language in
                self?.runHighlight(source: source, language: language)
            }
    }

    func update(source: String, language: DetectedLanguage) {
        inputSubject.send((source, language))
    }

    private func runHighlight(source: String, language: DetectedLanguage) {
        let queue = highlightQueue
        let src = source
        let lang = language
        Task.detached {
            let result = await withCheckedContinuation { continuation in
                queue.async {
                    let tokens = SyntaxHighlighter.highlight(src, language: lang)
                    continuation.resume(returning: tokens)
                }
            }
            await MainActor.run { [weak self] in
                self?.tokens = result
            }
        }
    }
}
