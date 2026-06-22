import Foundation

struct CategoryEndpoint: Endpoint {
    typealias ResponseType = [String]
    
    let path: String = "/products/category-list"
    let method: HTTPMethod = .get
    var queryItems: [URLQueryItem] { [] }
}
