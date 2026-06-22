import Foundation

enum FetchIntent: Equatable {
    case initial                // on first launch, empty products
    case loadMore               // User scrolls, load next available products
    case search                 // User typing, use delay, reset products
    case filterChanged          // selected filters updated, reset products
    case retry                  // retry button tapped, reload
    
    var shouldDebounce: Bool {
        // add delay in case of search
        self == .search
    }
    
    var resetProducts: Bool {
        // append the received products when loading more.
        self != .loadMore
    }
}
