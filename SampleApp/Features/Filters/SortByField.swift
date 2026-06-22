import Foundation

enum SortByField: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case title
    case priceAscending
    case priceDescending
    case rating
    case stock
    case discount
    
    var displayName: String {
        switch self {
        case .title:
            "Name"
        case .priceAscending:
            "Price (Low to High)"
        case .priceDescending:
            "Price (High to Low)"
        case .rating:
            "Rating"
        case .stock:
            "Stock"
        case .discount:
            "Discount"
        }
    }
}
