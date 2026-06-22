import Foundation

struct ProductsEndpoint: Endpoint {
    typealias ResponseType = ProductResponse
    
    struct Configuration: Equatable {
        var searchText: String = ""
        var category: String?
        var sortBy: SortByField?
    }
    
    // loading products for a search term is mutually exclusive to
    // loading products of a Category.
    var path: String {
        if let category = configuration.category {
            "/products/category/\(category)"
        } else if !configuration.searchText.isEmpty {
            "/products/search"
        } else {
            "/products"
        }
    }
    
    
    let method: HTTPMethod = .get
    let skip: Int
    let limit: Int
    var configuration: Configuration
    
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        // When a category is set, searchText is ignored
        if configuration.category == nil && !configuration.searchText.isEmpty {
            items.append(URLQueryItem(name: "q", value: "\(configuration.searchText)"))
        }
        
        let sortByItems = configuration.sortByQueryItems
        if !sortByItems.isEmpty {
            items.append(contentsOf: sortByItems)
        }
        
        return items
    }
}

extension ProductsEndpoint.Configuration {
    var sortByQueryItems: [URLQueryItem] {
        guard let sortBy = sortBy else { return [] }
        
        switch sortBy {
        case .title:
            return [URLQueryItem(name: "sortBy", value: "title")]
        case .priceAscending:
            return [
                URLQueryItem(name: "sortBy", value: "price"),
                URLQueryItem(name: "order", value: "asc")
            ]
        case .priceDescending:
            return [
                URLQueryItem(name: "sortBy", value: "price"),
                URLQueryItem(name: "order", value: "desc")
            ]
        case .rating:
            return [
                URLQueryItem(name: "sortBy", value: "rating"),
                URLQueryItem(name: "order", value: "desc")
            ]
        case .stock:
            return [
                URLQueryItem(name: "sortBy", value: "stock"),
                URLQueryItem(name: "order", value: "desc")
            ]
        case .discount:
            return [
                URLQueryItem(name: "sortBy", value: "discountPercentage"),
                URLQueryItem(name: "order", value: "desc")
            ]
        }
    }
}
