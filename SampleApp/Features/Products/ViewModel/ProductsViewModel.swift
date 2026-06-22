import Foundation
import Observation

protocol ProductsViewModel: Observable, AnyObject {
    var loadingState: LoadingState { get }
    var products: [Product] { get }
    var configuration: ProductsEndpoint.Configuration { get set }
    @MainActor
    func load(for intent: FetchIntent)
}

@Observable
final class DefaultProductsViewModel: ProductsViewModel {
    
    private let service: ProductService
    private let searchDebounce: Duration
    private(set) var loadingState: LoadingState = .initial
    private(set) var products: [Product] = []

    private var totalNumberOfProducts: Int? = nil
    private let pageSize: Int = 20

    var configuration: ProductsEndpoint.Configuration = .init()
    private var previousConfiguration: ProductsEndpoint.Configuration? = nil
    private var task: Task<(), Error>? = nil

    init(service: ProductService = DefaultProductService(), searchDebounce: Duration = .seconds(1)) {
        self.service = service
        self.searchDebounce = searchDebounce
    }
    
    @MainActor
    func load(for intent: FetchIntent) {
        guard canLoad(for: intent) else {
            return
        }
        
        task?.cancel()
        task = Task {
            await performLoad(for: intent)
        }
    }
    
    private func performLoad(for intent: FetchIntent) async {
        if intent.shouldDebounce, !configuration.searchText.isEmpty {
            try? await Task.sleep(for: searchDebounce)
            guard !Task.isCancelled else { return }
        }
        
        let isFullReload = intent.resetProducts
        loadingState = isFullReload ? .loading : .loadingMore
        
        do {
            let skip = isFullReload ? 0 : products.count
            let response = try await service.fetch(
                skip: skip,
                limit: pageSize,
                configuration: configuration
            )
            
            guard !Task.isCancelled else { return }
            
            if intent.resetProducts {
                self.products = response.products
            } else {
                self.products.append(contentsOf: response.products)
            }
            self.totalNumberOfProducts = response.total
            self.loadingState = .loadingComplete
            self.previousConfiguration = configuration
            
        } catch APIError.taskCancelled {
            // Ignore intermediate task cancelled errors.
        } catch {
            self.loadingState = isFullReload
                ? .loadingError(error.localizedDescription)
                : .loadingMoreError(error.localizedDescription)
        }
    }
    
    private func canLoad(for intent: FetchIntent) -> Bool {
        switch intent {
        // Should only load for the initial onAppear, when products is empty
        // and we are not already loading.
        case .initial:
            let result = products.isEmpty && !loadingState.isCurrentlyLoading
            return result
            
        case .loadMore:
            return !loadingState.isCurrentlyLoading && hasMoreProducts()
            
        // load only if the configuration has changed.
        case .search, .filterChanged:
            return previousConfiguration != configuration
            
        case .retry:
            return true
        }
    }
    
    private func hasMoreProducts() -> Bool {
        guard let totalNumberOfProducts else { return false }
        return products.count < totalNumberOfProducts
    }
}


