import Observation
import Foundation
@testable import SampleApp

@Observable
final class MockCategoryViewModel: CategoryViewModel {

    var categories: [String] = []
    var loadingError: String? = nil

    // Test inspection
    private(set) var loadCallCount = 0

    // Stubbing
    var stubbedCategories: [String] = ["beauty", "electronics"]
    var stubbedError: Error? = nil

    func load() async {
        loadCallCount += 1
        guard categories.isEmpty else { return }

        if let error = stubbedError {
            loadingError = error.localizedDescription
        } else {
            categories = stubbedCategories
        }
    }
}
