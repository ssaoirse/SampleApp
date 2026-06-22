import Observation
import Foundation
@testable import SampleApp

@Observable
@MainActor
final class MockProductsViewModel: ProductsViewModel {

    var loadingState: LoadingState = .initial
    var products: [Product] = []
    var configuration: ProductsEndpoint.Configuration = .init()

    // Test inspection
    private(set) var loadCallCount = 0
    private(set) var lastIntent: FetchIntent?

    // Stubbing
    var stubbedProducts: [Product] = [.example]
    var stubbedError: Error? = nil

    func load(for intent: FetchIntent) {
        loadCallCount += 1
        lastIntent = intent

        if let error = stubbedError {
            loadingState = .loadingError(error.localizedDescription)
            return
        }

        if intent == .loadMore {
            products.append(contentsOf: stubbedProducts)
        } else {
            products = stubbedProducts
        }
        loadingState = .loadingComplete
    }
}
