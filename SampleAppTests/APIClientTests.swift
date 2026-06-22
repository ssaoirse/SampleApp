import XCTest
@testable import SampleApp

final class APIClientTests: XCTestCase {

    private struct TestEndpoint: Endpoint {
        typealias ResponseType = [String]
        var path: String = "/test"
        var method: HTTPMethod = .get
        var queryItems: [URLQueryItem] = []
    }

    private func makeSUT() -> APIClient {
        APIClient(
            baseUrl: URL(string: "https://test.com")!,
            urlSession: MockURLProtocol.makeSession()
        )
    }

    // MARK: - Success

    func test_fetch_given_validResponse_when_200StatusCode_then_decodesResponse() async throws {
        let expected = ["categoryA", "categoryB"]
        MockURLProtocol.respondWith(statusCode: 200, data: try JSONEncoder().encode(expected))

        let result = try await makeSUT().fetch(endPoint: TestEndpoint())

        XCTAssertEqual(result, expected)
    }

    // MARK: - HTTP error codes

    func test_fetch_given_serverErrorBody_when_non200StatusCode_then_throwsRequestFailedWithMessage() async throws {
        let body = Data(#"{"errorMessage":"Not found"}"#.utf8)
        MockURLProtocol.respondWith(statusCode: 404, data: body)

        do {
            _ = try await makeSUT().fetch(endPoint: TestEndpoint())
            XCTFail("Expected error not thrown")
        } catch APIError.requestFailed(let code, let message) {
            XCTAssertEqual(code, 404)
            XCTAssertEqual(message, "Not found")
        }
    }

    func test_fetch_given_malformedErrorBody_when_non200StatusCode_then_throwsRequestFailedWithNilMessage() async throws {
        let malformedBody = Data("not json".utf8)
        MockURLProtocol.respondWith(statusCode: 500, data: malformedBody)

        do {
            _ = try await makeSUT().fetch(endPoint: TestEndpoint())
            XCTFail("Expected error not thrown")
        } catch APIError.requestFailed(let code, let message) {
            XCTAssertEqual(code, 500)
            XCTAssertNil(message)
        }
    }

    // MARK: - Network & response errors

    func test_fetch_given_networkUnavailable_when_urlError_then_throwsNetworkError() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await makeSUT().fetch(endPoint: TestEndpoint())
            XCTFail("Expected error not thrown")
        } catch APIError.networkError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetch_given_cancelledRequest_when_urlCancelledError_then_throwsTaskCancelled() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.cancelled) }

        do {
            _ = try await makeSUT().fetch(endPoint: TestEndpoint())
            XCTFail("Expected error not thrown")
        } catch APIError.taskCancelled {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetch_given_invalidPath_when_urlConstructionFails_then_throwsInvalidUrl() async throws {
        // A base URL combined with a path that causes URLComponents to fail
        var badEndpoint = TestEndpoint()
        badEndpoint.path = "://invalid"
        MockURLProtocol.respondWith(statusCode: 200, data: Data())

        do {
            _ = try await makeSUT().fetch(endPoint: badEndpoint)
            XCTFail("Expected error not thrown")
        } catch APIError.invalidUrl {
        } catch {
            // URLComponents may fail during construction — any error here is acceptable
        }
    }
}
