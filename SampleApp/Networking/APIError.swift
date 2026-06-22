import Foundation

enum APIError: Error, LocalizedError {
    case invalidUrl
    case invalidResponse
    case requestFailed(statusCode: Int, message: String?)
    case taskCancelled
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .requestFailed(statusCode: let statusCode, message: let message):
            var description = "Request failed with status code: \(statusCode)"
            if let message = message {
                description += " - \(message)"
            }
            return description
        case .taskCancelled:
            return "Task cancelled"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

struct ServerError: Decodable {
    let errorMessage: String
}
