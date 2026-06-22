import Foundation

protocol ProductService: Sendable {
    func fetch(skip: Int, limit: Int, configuration: ProductsEndpoint.Configuration) async throws -> ProductResponse
}

struct DefaultProductService: ProductService {
    
    let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetch(skip: Int, limit: Int, configuration: ProductsEndpoint.Configuration) async throws -> ProductResponse {
        let endPoint = ProductsEndpoint(
            skip: skip,
            limit: limit,
            configuration: configuration
        )
        return try await apiClient.fetch(endPoint: endPoint)
    }
}

struct MockProductsService: ProductService {
    let result: [Product]
    let error: APIError?
    
    init(
        result: [Product] = [Product.example],
        error: APIError? = nil
    ) {
        self.result = result
        self.error = error
    }

    func fetch(skip: Int, limit: Int, configuration: ProductsEndpoint.Configuration) async throws -> ProductResponse {
        if let error {
            throw error
        } else {
            ProductResponse(products: result, total: 1, skip: 0, limit: result.count)
        }
    }
}
