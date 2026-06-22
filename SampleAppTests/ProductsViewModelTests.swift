import XCTest
@testable import SampleApp

// A call-counting service that lets tests assert how many times fetch was called.
private final class SpyProductsService: ProductService, @unchecked Sendable {
    var fetchCallCount = 0
    var result: [Product]
    var error: APIError?

    init(result: [Product] = [.example], error: APIError? = nil) {
        self.result = result
        self.error = error
    }

    func fetch(skip: Int, limit: Int, configuration: ProductsEndpoint.Configuration) async throws -> ProductResponse {
        fetchCallCount += 1
        if let error { throw error }
        return ProductResponse(products: result, total: result.count, skip: skip, limit: result.count)
    }
}

// A service that suspends indefinitely inside fetch until explicitly completed.
// Lets tests assert behaviour while a load is genuinely in-flight.
private actor BlockingProductsService: ProductService {
    private(set) var fetchCallCount = 0
    private var continuation: CheckedContinuation<ProductResponse, Error>?

    func fetch(skip: Int, limit: Int, configuration: ProductsEndpoint.Configuration) async throws -> ProductResponse {
        fetchCallCount += 1
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func complete() {
        continuation?.resume(returning: ProductResponse(products: [.example], total: 1, skip: 0, limit: 1))
        continuation = nil
    }
}

@MainActor
final class ProductsViewModelTests: XCTestCase {

    // MARK: - Initial load

    func test_load_given_emptyProducts_when_initialIntent_then_transitionsToLoadingComplete() async throws {
        let vm = makeVM()
        vm.load(for: .initial)
        try await settle()
        XCTAssertEqual(vm.loadingState, .loadingComplete)
        XCTAssertFalse(vm.products.isEmpty)
    }

    func test_load_given_productsAlreadyPresent_when_initialIntent_then_doesNotFetch() async throws {
        let service = SpyProductsService()
        let vm = makeVM(service: service)
        vm.load(for: .initial)
        try await settle()

        vm.load(for: .initial)
        try await settle()

        XCTAssertEqual(service.fetchCallCount, 1)
    }

    func test_load_given_loadInFlight_when_initialIntent_then_doesNotFetch() async throws {
        let service = BlockingProductsService()
        let vm = makeVM(service: service)

        vm.load(for: .initial)
        // Yield to the MainActor queue so the spawned task runs until it suspends
        // inside service.fetch, at which point loadingState is .loading.
        await Task.yield()

        XCTAssertEqual(vm.loadingState, .loading)

        // Second call while in-flight: canLoad returns false because isCurrentlyLoading is true.
        vm.load(for: .initial)

        // Unblock the first fetch and wait for completion.
        await service.complete()
        try await settle()

        let fetchCount = await service.fetchCallCount
        XCTAssertEqual(fetchCount, 1)
    }

    // MARK: - Load more

    func test_load_given_moreProductsAvailable_when_loadMoreIntent_then_appendsProducts() async throws {
        let service = SpyProductsService(result: Array(repeating: .example, count: 5))
        // total must be > 5 for hasMoreProducts to return true
        let vm = makeVM(service: service)
        // Override total via a service that returns total > 5
        let unlimitedService = UnlimitedSpyService(pageSize: 5, total: 20)
        let vm2 = makeVM(service: unlimitedService)

        vm2.load(for: .initial)
        try await settle()
        let firstCount = vm2.products.count

        vm2.load(for: .loadMore)
        try await settle()

        XCTAssertGreaterThan(vm2.products.count, firstCount)
        XCTAssertEqual(unlimitedService.fetchCallCount, 2)
    }

    func test_load_given_allProductsLoaded_when_loadMoreIntent_then_doesNotFetch() async throws {
        let service = SpyProductsService(result: [.example])
        let vm = makeVM(service: service)

        vm.load(for: .initial)
        try await settle()
        // total == 1, products.count == 1 → hasMoreProducts is false

        vm.load(for: .loadMore)
        try await settle()

        XCTAssertEqual(service.fetchCallCount, 1)
    }

    // MARK: - Search

    func test_load_given_searchTextChanged_when_searchIntent_then_fetches() async throws {
        let service = SpyProductsService()
        let vm = makeVM(service: service, searchDebounce: .milliseconds(10))

        vm.load(for: .initial)
        try await settle()

        vm.configuration.searchText = "phone"
        vm.load(for: .search)
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(service.fetchCallCount, 2)
    }

    func test_load_given_configurationUnchanged_when_searchIntent_then_doesNotFetch() async throws {
        let service = SpyProductsService()
        let vm = makeVM(service: service)

        vm.load(for: .initial)
        try await settle()

        // configuration hasn't changed since last successful load
        vm.load(for: .search)
        try await settle()

        XCTAssertEqual(service.fetchCallCount, 1)
    }

    func test_load_given_searchTextChanged_when_searchIntent_then_resetsProducts() async throws {
        let service = SpyProductsService(result: [.example])
        let vm = makeVM(service: service, searchDebounce: .milliseconds(10))

        vm.load(for: .initial)
        try await settle()

        vm.configuration.searchText = "phone"
        vm.load(for: .search)
        try await Task.sleep(for: .milliseconds(50))

        // products replaced, not appended
        XCTAssertEqual(vm.products.count, 1)
    }

    // MARK: - Filter changed

    func test_load_given_categoryChanged_when_filterChangedIntent_then_fetches() async throws {
        let service = SpyProductsService()
        let vm = makeVM(service: service)

        vm.load(for: .initial)
        try await settle()

        vm.configuration.category = "beauty"
        vm.load(for: .filterChanged)
        try await settle()

        XCTAssertEqual(service.fetchCallCount, 2)
    }

    func test_load_given_configurationUnchanged_when_filterChangedIntent_then_doesNotFetch() async throws {
        let service = SpyProductsService()
        let vm = makeVM(service: service)

        vm.load(for: .initial)
        try await settle()

        vm.load(for: .filterChanged)
        try await settle()

        XCTAssertEqual(service.fetchCallCount, 1)
    }

    // MARK: - Retry

    func test_load_given_anyState_when_retryIntent_then_alwaysFetches() async throws {
        let service = SpyProductsService()
        let vm = makeVM(service: service)

        vm.load(for: .initial)
        try await settle()

        vm.load(for: .retry)
        try await settle()

        XCTAssertEqual(service.fetchCallCount, 2)
    }

    // MARK: - Error states

    func test_load_given_serviceFailure_when_initialIntent_then_setsLoadingError() async throws {
        let vm = makeVM(service: SpyProductsService(error: .invalidResponse))
        vm.load(for: .initial)
        try await settle()

        if case .loadingError = vm.loadingState { } else {
            XCTFail("Expected loadingError, got \(vm.loadingState)")
        }
    }

    func test_load_given_serviceFailure_when_loadMoreIntent_then_setsLoadingMoreError() async throws {
        let service = UnlimitedSpyService(pageSize: 1, total: 10)
        let vm = makeVM(service: service)

        vm.load(for: .initial)
        try await settle()

        service.shouldFail = true
        vm.load(for: .loadMore)
        try await settle()

        if case .loadingMoreError = vm.loadingState { } else {
            XCTFail("Expected loadingMoreError, got \(vm.loadingState)")
        }
    }

    func test_loadingState_given_newInstance_when_created_then_isInitial() {
        let vm = makeVM()
        XCTAssertEqual(vm.loadingState, .initial)
    }

    // MARK: - Contract

    func test_contract_given_defaultViewModel_when_contractAsserted_then_passes() async throws {
        let vm = DefaultProductsViewModel(service: MockProductsService(), searchDebounce: .zero)
        try await assertContract(vm)
    }

    func test_contract_given_mockViewModel_when_contractAsserted_then_passes() async throws {
        let vm = MockProductsViewModel()
        try await assertContract(vm)
    }

    // MARK: - Mock

    func test_mock_given_loadCalled_when_searchIntent_then_recordsIntentAndCount() {
        let vm = MockProductsViewModel()

        vm.load(for: .search)

        XCTAssertEqual(vm.loadCallCount, 1)
        XCTAssertEqual(vm.lastIntent, .search)
    }

    func test_mock_given_stubbedError_when_loadCalled_then_setsLoadingError() {
        let vm = MockProductsViewModel()
        vm.stubbedError = APIError.invalidResponse

        vm.load(for: .initial)

        guard case .loadingError = vm.loadingState else {
            XCTFail("Expected .loadingError, got \(vm.loadingState)")
            return
        }
    }

    func test_mock_given_productsPresent_when_loadMoreIntent_then_appendsProducts() {
        let vm = MockProductsViewModel()
        vm.stubbedProducts = [.example]

        vm.load(for: .initial)
        let afterInitial = vm.products.count

        vm.load(for: .loadMore)

        XCTAssertEqual(vm.products.count, afterInitial + 1)
    }

    func test_mock_given_productsPresent_when_searchIntent_then_replacesProducts() {
        let vm = MockProductsViewModel()
        vm.stubbedProducts = [.example, .example]

        vm.load(for: .initial)
        vm.stubbedProducts = [.example]
        vm.load(for: .search)

        XCTAssertEqual(vm.products.count, 1)
    }

    func test_mock_given_multipleIntents_when_loadCalledThreeTimes_then_countsEachCall() {
        let vm = MockProductsViewModel()

        vm.load(for: .initial)
        vm.load(for: .retry)
        vm.load(for: .loadMore)

        XCTAssertEqual(vm.loadCallCount, 3)
    }

    func test_mock_given_newConfiguration_when_propertiesSet_then_configurationUpdated() {
        let vm = MockProductsViewModel()
        vm.configuration.searchText = "headphones"
        vm.configuration.category = "electronics"

        XCTAssertEqual(vm.configuration.searchText, "headphones")
        XCTAssertEqual(vm.configuration.category, "electronics")
    }

    // MARK: - Helpers

    private func assertContract<VM: ProductsViewModel>(_ vm: VM) async throws {
        XCTAssertEqual(vm.loadingState, .initial)
        XCTAssertTrue(vm.products.isEmpty)

        vm.load(for: .initial)
        try await Task.sleep(for: .milliseconds(30))

        XCTAssertEqual(vm.loadingState, .loadingComplete)
        XCTAssertFalse(vm.products.isEmpty)

        vm.configuration.searchText = "test"
        XCTAssertEqual(vm.configuration.searchText, "test")
    }

    private func makeVM(
        service: ProductService = SpyProductsService(),
        searchDebounce: Duration = .seconds(0)
    ) -> DefaultProductsViewModel {
        DefaultProductsViewModel(service: service, searchDebounce: searchDebounce)
    }

    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(30))
    }
}

// A service that returns `pageSize` products per call with a configurable total, and can be told to fail.
private final class UnlimitedSpyService: ProductService, @unchecked Sendable {
    var fetchCallCount = 0
    var shouldFail = false
    let pageSize: Int
    let total: Int

    init(pageSize: Int, total: Int) {
        self.pageSize = pageSize
        self.total = total
    }

    func fetch(skip: Int, limit: Int, configuration: ProductsEndpoint.Configuration) async throws -> ProductResponse {
        fetchCallCount += 1
        if shouldFail { throw APIError.invalidResponse }
        let products = Array(repeating: Product.example, count: min(pageSize, total - skip))
        return ProductResponse(products: products, total: total, skip: skip, limit: pageSize)
    }
}
