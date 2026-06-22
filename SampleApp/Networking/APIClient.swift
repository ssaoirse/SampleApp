import Foundation

struct APIClient {
    let baseUrl: URL
    let urlSession: URLSession
    
    init(
        baseUrl: URL = URLConstants.baseUrl,
        urlSession: URLSession = .shared
    ) {
        self.baseUrl = baseUrl
        self.urlSession = urlSession
    }
    
    func fetch<E: Endpoint>(endPoint: E) async throws -> E.ResponseType {
        let request = try endPoint.makeUrlRequest(baseUrl: baseUrl)
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw APIError.taskCancelled
        } catch is CancellationError {
            throw APIError.taskCancelled
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Only http GET requests are supported and status code other than 200
        // are considered as failure.
        guard httpResponse.statusCode == 200 else {
            let serverError = try? JSONDecoder().decode(ServerError.self, from: data)
            throw APIError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: serverError?.errorMessage
            )
        }
        
        return try endPoint.map(data)
    }
}
