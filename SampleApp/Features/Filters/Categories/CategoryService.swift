import Foundation

protocol CategoryService: Sendable {
    func fetch() async throws -> [String]
}

struct DefaultCategoryService: CategoryService {
    
    let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetch() async throws -> [String] {
        return try await apiClient.fetch(endPoint: CategoryEndpoint())
    }
}
