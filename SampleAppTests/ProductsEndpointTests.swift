import XCTest
@testable import SampleApp

final class ProductsEndpointTests: XCTestCase {

    private let baseURL = URL(string: "https://dummyjson.com")!

    // MARK: - Path

    func test_path_given_noSearchOrCategory_when_default_then_isProducts() {
        let endpoint = makeEndpoint()
        XCTAssertEqual(endpoint.path, "/products")
    }

    func test_path_given_searchText_when_noCategory_then_isProductsSearch() {
        let endpoint = makeEndpoint(searchText: "apple")
        XCTAssertEqual(endpoint.path, "/products/search")
    }

    func test_path_given_category_when_noSearch_then_isProductsCategory() {
        let endpoint = makeEndpoint(category: "beauty")
        XCTAssertEqual(endpoint.path, "/products/category/beauty")
    }

    func test_path_given_bothSearchAndCategory_when_configured_then_categoryTakesPrecedence() {
        let endpoint = makeEndpoint(searchText: "apple", category: "beauty")
        XCTAssertEqual(endpoint.path, "/products/category/beauty")
    }

    // MARK: - Query items

    func test_queryItems_given_anyConfiguration_when_built_then_alwaysContainSkipAndLimit() throws {
        let endpoint = makeEndpoint(skip: 10, limit: 5)
        let items = endpoint.queryItems
        XCTAssertEqual(queryValue(items, name: "skip"), "10")
        XCTAssertEqual(queryValue(items, name: "limit"), "5")
    }

    func test_queryItems_given_searchText_when_noCategory_then_includesQParam() {
        let endpoint = makeEndpoint(searchText: "phone")
        XCTAssertEqual(queryValue(endpoint.queryItems, name: "q"), "phone")
    }

    func test_queryItems_given_categorySet_when_searchTextPresent_then_omitsQParam() {
        let endpoint = makeEndpoint(searchText: "phone", category: "electronics")
        XCTAssertNil(queryValue(endpoint.queryItems, name: "q"))
    }

    // MARK: - Sort by query items

    func test_sortBy_given_titleField_when_sorted_then_sendsSortByTitle() {
        let items = sortItems(for: .title)
        XCTAssertEqual(queryValue(items, name: "sortBy"), "title")
        XCTAssertNil(queryValue(items, name: "order"))
    }

    func test_sortBy_given_priceAscendingField_when_sorted_then_sendsPriceAsc() {
        let items = sortItems(for: .priceAscending)
        XCTAssertEqual(queryValue(items, name: "sortBy"), "price")
        XCTAssertEqual(queryValue(items, name: "order"), "asc")
    }

    func test_sortBy_given_priceDescendingField_when_sorted_then_sendsPriceDesc() {
        let items = sortItems(for: .priceDescending)
        XCTAssertEqual(queryValue(items, name: "sortBy"), "price")
        XCTAssertEqual(queryValue(items, name: "order"), "desc")
    }

    func test_sortBy_given_ratingField_when_sorted_then_sendsRatingDesc() {
        let items = sortItems(for: .rating)
        XCTAssertEqual(queryValue(items, name: "sortBy"), "rating")
        XCTAssertEqual(queryValue(items, name: "order"), "desc")
    }

    func test_sortBy_given_stockField_when_sorted_then_sendsStockDesc() {
        let items = sortItems(for: .stock)
        XCTAssertEqual(queryValue(items, name: "sortBy"), "stock")
        XCTAssertEqual(queryValue(items, name: "order"), "desc")
    }

    func test_sortBy_given_discountField_when_sorted_then_sendsDiscountPercentage() {
        let items = sortItems(for: .discount)
        XCTAssertEqual(queryValue(items, name: "sortBy"), "discountPercentage")
        XCTAssertEqual(queryValue(items, name: "order"), "desc")
    }

    func test_sortBy_given_nilSortBy_when_built_then_omitsSortByAndOrder() {
        let endpoint = makeEndpoint()
        XCTAssertNil(queryValue(endpoint.queryItems, name: "sortBy"))
        XCTAssertNil(queryValue(endpoint.queryItems, name: "order"))
    }

    // MARK: - URLRequest construction

    func test_makeUrlRequest_given_searchConfiguration_when_built_then_includesCorrectQueryParams() throws {
        let endpoint = makeEndpoint(searchText: "bag", skip: 0, limit: 20)
        let request = try endpoint.makeUrlRequest(baseUrl: baseURL)
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: true)!
        let queryItems = components.queryItems ?? []
        XCTAssertEqual(queryValue(queryItems, name: "q"), "bag")
        XCTAssertEqual(queryValue(queryItems, name: "skip"), "0")
        XCTAssertEqual(queryValue(queryItems, name: "limit"), "20")
    }

    func test_makeUrlRequest_given_defaultEndpoint_when_built_then_methodIsGET() throws {
        let request = try makeEndpoint().makeUrlRequest(baseUrl: baseURL)
        XCTAssertEqual(request.httpMethod, "GET")
    }

    // MARK: - Helpers

    private func makeEndpoint(
        searchText: String = "",
        category: String? = nil,
        sortBy: SortByField? = nil,
        skip: Int = 0,
        limit: Int = 20
    ) -> ProductsEndpoint {
        ProductsEndpoint(
            skip: skip,
            limit: limit,
            configuration: .init(searchText: searchText, category: category, sortBy: sortBy)
        )
    }

    private func sortItems(for field: SortByField) -> [URLQueryItem] {
        makeEndpoint(sortBy: field).queryItems
    }

    private func queryValue(_ items: [URLQueryItem], name: String) -> String? {
        items.first(where: { $0.name == name })?.value
    }
}
