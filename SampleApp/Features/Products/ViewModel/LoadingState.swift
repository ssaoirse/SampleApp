import Foundation

enum LoadingState: Equatable {
    case initial
    case loading
    case loadingMore
    case loadingComplete
    case loadingError(String)
    case loadingMoreError(String)
    
    var isCurrentlyLoading: Bool {
        switch self {
        case .loading, .loadingMore:
            true
        default:
            false
        }
    }
}
