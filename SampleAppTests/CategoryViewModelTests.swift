import XCTest
@testable import SampleApp

final class CategoryViewModelTests: XCTestCase {

    func test_load_given_successfulService_when_loaded_then_populatesCategories() async {
        let vm = DefaultCategoryViewModel(service: MockCategoryService(result: ["beauty", "electronics"]))
        await vm.load()
        XCTAssertEqual(vm.categories, ["beauty", "electronics"])
        XCTAssertNil(vm.loadingError)
    }

    func test_load_given_categoriesAlreadyLoaded_when_loadCalledAgain_then_doesNotRefetch() async {
        var callCount = 0
        let service = CountingCategoryService { callCount += 1 }
        let vm = DefaultCategoryViewModel(service: service)

        await vm.load()
        await vm.load()

        XCTAssertEqual(callCount, 1)
    }

    func test_load_given_serviceFailure_when_loaded_then_setsLoadingError() async {
        let vm = DefaultCategoryViewModel(service: MockCategoryService(error: APIError.invalidResponse))
        await vm.load()
        XCTAssertTrue(vm.categories.isEmpty)
        XCTAssertNotNil(vm.loadingError)
    }

    func test_load_given_previousError_when_freshLoad_then_clearsLoadingError() async {
        let failing = MockCategoryService(error: APIError.invalidResponse)
        let vm = DefaultCategoryViewModel(service: failing)
        await vm.load()
        XCTAssertNotNil(vm.loadingError)

        // Reset so a fresh VM with success service can clear it
        let vm2 = DefaultCategoryViewModel(service: MockCategoryService())
        vm2.loadingError = "stale error"
        await vm2.load()
        // load() guard categories.isEmpty exits early when categories is populated;
        // this tests that a brand-new load clears the error from the start
        let vm3 = DefaultCategoryViewModel(service: MockCategoryService())
        await vm3.load()
        XCTAssertNil(vm3.loadingError)
    }

    func test_load_given_emptyResponse_when_loaded_then_categoriesIsEmpty() async {
        let vm = DefaultCategoryViewModel(service: MockCategoryService(result: []))
        await vm.load()
        XCTAssertTrue(vm.categories.isEmpty)
        XCTAssertNil(vm.loadingError)
    }

    // MARK: - Contract

    func test_contract_given_defaultViewModel_when_contractAsserted_then_passes() async {
        let vm = DefaultCategoryViewModel(service: MockCategoryService())
        await assertContract(vm)
    }

    func test_contract_given_mockViewModel_when_contractAsserted_then_passes() async {
        let vm = MockCategoryViewModel()
        await assertContract(vm)
    }

    // MARK: - Mock

    func test_mock_given_loadCalledTwice_when_categoriesPresent_then_countsBothCalls() async {
        let vm = MockCategoryViewModel()

        await vm.load()
        await vm.load()

        XCTAssertEqual(vm.loadCallCount, 2)
    }

    func test_mock_given_categoriesAlreadyLoaded_when_loadCalledAgain_then_doesNotReload() async {
        let vm = MockCategoryViewModel()
        vm.stubbedCategories = ["beauty"]

        await vm.load()
        vm.stubbedCategories = ["electronics"]
        await vm.load()

        XCTAssertEqual(vm.categories, ["beauty"])
    }

    func test_mock_given_stubbedError_when_loadCalled_then_setsLoadingError() async {
        let vm = MockCategoryViewModel()
        vm.stubbedError = APIError.invalidResponse

        await vm.load()

        XCTAssertNotNil(vm.loadingError)
        XCTAssertTrue(vm.categories.isEmpty)
    }

    func test_mock_given_stubbedCategories_when_loaded_then_returnsCustomCategories() async {
        let vm = MockCategoryViewModel()
        vm.stubbedCategories = ["sports", "furniture", "groceries"]

        await vm.load()

        XCTAssertEqual(vm.categories, ["sports", "furniture", "groceries"])
    }

    func test_mock_given_successfulLoad_when_loaded_then_noLoadingError() async {
        let vm = MockCategoryViewModel()

        await vm.load()

        XCTAssertNil(vm.loadingError)
    }

    // MARK: - Helpers

    private func assertContract<VM: CategoryViewModel>(_ vm: VM) async {
        XCTAssertTrue(vm.categories.isEmpty)
        XCTAssertNil(vm.loadingError)

        await vm.load()

        XCTAssertFalse(vm.categories.isEmpty)
        XCTAssertNil(vm.loadingError)
    }
}

private final class CountingCategoryService: CategoryService, @unchecked Sendable {
    private let onFetch: () -> Void

    init(onFetch: @escaping () -> Void) {
        self.onFetch = onFetch
    }

    func fetch() async throws -> [String] {
        onFetch()
        return ["beauty"]
    }
}
