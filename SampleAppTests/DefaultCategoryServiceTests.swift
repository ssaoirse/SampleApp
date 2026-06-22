import XCTest
@testable import SampleApp

final class DefaultCategoryServiceTests: XCTestCase {

    private func makeSUT() -> DefaultCategoryService {
        DefaultCategoryService(apiClient: APIClient(
            baseUrl: URL(string: "https://dummyjson.com")!,
            urlSession: MockURLProtocol.makeSession()
        ))
    }

    // MARK: - Response decoding

    func test_fetch_given_validResponse_when_fetched_then_returnsDecodedCategories() async throws {
        MockURLProtocol.respondWith(statusCode: 200, data: categoriesJSON)

        let categories = try await makeSUT().fetch()

        XCTAssertEqual(categories, ["beauty", "fragrances", "furniture"])
    }

    // MARK: - Endpoint construction

    func test_fetch_given_anyInput_when_fetched_then_requestsCategoryListPath() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, categoriesJSON)
        }

        _ = try await makeSUT().fetch()

        XCTAssertEqual(captured?.url?.path, "/products/category-list")
        XCTAssertEqual(captured?.httpMethod, "GET")
    }

    // MARK: - Error propagation

    func test_fetch_given_networkError_when_fetched_then_propagatesApiError() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await makeSUT().fetch()
            XCTFail("Expected error not thrown")
        } catch APIError.networkError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetch_given_serverError_when_fetched_then_throwsRequestFailed() async throws {
        let body = Data(#"{"errorMessage":"Unauthorized"}"#.utf8)
        MockURLProtocol.respondWith(statusCode: 401, data: body)

        do {
            _ = try await makeSUT().fetch()
            XCTFail("Expected error not thrown")
        } catch APIError.requestFailed(let code, let message) {
            XCTAssertEqual(code, 401)
            XCTAssertEqual(message, "Unauthorized")
        }
    }

    func test_fetch_given_malformedJSON_when_fetched_then_throwsDecodingError() async throws {
        MockURLProtocol.respondWith(statusCode: 200, data: Data("not json".utf8))
 
        do {
            _ = try await makeSUT().fetch()
            XCTFail("Expected error not thrown")
        } catch is DecodingError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private let categoriesJSON = Data("""
["beauty","fragrances","furniture"]
""".utf8)
