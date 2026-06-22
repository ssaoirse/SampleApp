import Foundation
import Observation

protocol CategoryViewModel: AnyObject, Observable {
    var categories: [String] { get }
    var loadingError: String? { get }
    @MainActor
    func load() async
}

@Observable
final class DefaultCategoryViewModel: CategoryViewModel {
    var categories: [String] = []
    var loadingError: String? = nil
    private let service: CategoryService

    init(service: CategoryService = DefaultCategoryService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        guard categories.isEmpty else { return }
        loadingError = nil
        do {
            categories = try await service.fetch()
        } catch {
            loadingError = error.localizedDescription
        }
    }
}
