import XCTest
@testable import SampleApp

final class DefaultProductServiceTests: XCTestCase {

    private func makeSUT() -> DefaultProductService {
        DefaultProductService(apiClient: APIClient(
            baseUrl: URL(string: "https://dummyjson.com")!,
            urlSession: MockURLProtocol.makeSession()
        ))
    }

    // MARK: - Response decoding

    func test_fetch_given_validResponse_when_fetched_then_returnsDecodedProductResponse() async throws {
        MockURLProtocol.respondWith(statusCode: 200, data: productResponseJSON)

        let response = try await makeSUT().fetch(skip: 0, limit: 20, configuration: .init())

        XCTAssertEqual(response.total, 100)
        XCTAssertEqual(response.products.count, 1)
        XCTAssertEqual(response.products.first?.title, "Mascara")
        XCTAssertEqual(response.products.first?.category, "beauty")
    }

    // MARK: - Endpoint construction

    func test_fetch_given_paginationParams_when_fetched_then_sendsCorrectSkipAndLimit() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, productResponseJSON)
        }

        _ = try await makeSUT().fetch(skip: 40, limit: 10, configuration: .init())

        let items = queryItems(from: captured)
        XCTAssertEqual(queryValue(items, name: "skip"), "40")
        XCTAssertEqual(queryValue(items, name: "limit"), "10")
    }

    func test_fetch_given_searchText_when_fetched_then_sendsSearchPathAndQParam() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, productResponseJSON)
        }

        var config = ProductsEndpoint.Configuration()
        config.searchText = "phone"
        _ = try await makeSUT().fetch(skip: 0, limit: 20, configuration: config)

        XCTAssertTrue(captured?.url?.path.contains("/products/search") == true)
        XCTAssertEqual(queryValue(queryItems(from: captured), name: "q"), "phone")
    }

    func test_fetch_given_category_when_fetched_then_sendsCategoryPath() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, productResponseJSON)
        }

        var config = ProductsEndpoint.Configuration()
        config.category = "beauty"
        _ = try await makeSUT().fetch(skip: 0, limit: 20, configuration: config)

        XCTAssertTrue(captured?.url?.path.contains("/products/category/beauty") == true)
    }

    func test_fetch_given_sortBy_when_fetched_then_sendsSortByParam() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, productResponseJSON)
        }

        var config = ProductsEndpoint.Configuration()
        config.sortBy = .rating
        _ = try await makeSUT().fetch(skip: 0, limit: 20, configuration: config)

        let items = queryItems(from: captured)
        XCTAssertEqual(queryValue(items, name: "sortBy"), "rating")
        XCTAssertEqual(queryValue(items, name: "order"), "desc")
    }

    // MARK: - Error propagation

    func test_fetch_given_networkError_when_fetched_then_propagatesApiError() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await makeSUT().fetch(skip: 0, limit: 20, configuration: .init())
            XCTFail("Expected error not thrown")
        } catch APIError.networkError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetch_given_serverError_when_fetched_then_throwsRequestFailed() async throws {
        let body = Data(#"{"errorMessage":"Not found"}"#.utf8)
        MockURLProtocol.respondWith(statusCode: 404, data: body)

        do {
            _ = try await makeSUT().fetch(skip: 0, limit: 20, configuration: .init())
            XCTFail("Expected error not thrown")
        } catch APIError.requestFailed(let code, let message) {
            XCTAssertEqual(code, 404)
            XCTAssertEqual(message, "Not found")
        }
    }

    // MARK: - Helpers

    private func queryItems(from request: URLRequest?) -> [URLQueryItem] {
        guard let url = request?.url else { return [] }
        return URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
    }

    private func queryValue(_ items: [URLQueryItem], name: String) -> String? {
        items.first(where: { $0.name == name })?.value
    }
}

private let productResponseJSON = Data("""
{
    "products": [{
        "id": 1,
        "title": "Mascara",
        "description": "Great mascara",
        "category": "beauty",
        "price": 9.99,
        "discountPercentage": 7.17,
        "rating": 4.69,
        "stock": 5,
        "thumbnail": "https://example.com/thumb.jpg",
        "images": []
    }],
    "total": 100,
    "skip": 0,
    "limit": 20
}
""".utf8)
