import SwiftUI

@main
struct SampleApp: App {
    @State private var productsViewModel = DefaultProductsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ProductsListView(productsViewModel: productsViewModel)
        }
    }
}
