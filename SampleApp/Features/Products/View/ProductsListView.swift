import SwiftUI

struct ProductsListView<ProductVM: ProductsViewModel, CategoryVM: CategoryViewModel>: View {

    @Bindable var productsViewModel: ProductVM
    @State private var categoryViewModel: CategoryVM
    private let loadMoreTriggerOffset: CGFloat = 300
    @State private var filterSheetIsOpen = false

    init(productsViewModel: ProductVM, categoryViewModel: CategoryVM) {
        self.productsViewModel = productsViewModel
        self._categoryViewModel = State(initialValue: categoryViewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(productsViewModel.products) { product in
                    ProductItem(product: product)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Products")
            .toolbar(content: {
                Button {
                    filterSheetIsOpen.toggle()
                } label: {
                    Label("Show Filter", systemImage: "slider.horizontal.3")
                }
            })
            .sheet(isPresented: $filterSheetIsOpen, onDismiss: {
                productsViewModel.load(for: .filterChanged)
            }, content: {
                FilterProductsView(
                    categoryViewModel: categoryViewModel,
                    sortBy: $productsViewModel.configuration.sortBy,
                    selectedCategory: $productsViewModel.configuration.category
                )
            })
            .searchable(text: $productsViewModel.configuration.searchText)
            .overlay(content: {
                ProgressViewOverlay(
                    loadingState: productsViewModel.loadingState,
                    isEmpty: productsViewModel.products.isEmpty,
                    onRetry: {
                        productsViewModel.load(for: .retry)
                    }
                )
            })
            .onChange(of: productsViewModel.configuration.searchText) { _, _ in
                productsViewModel.load(for: .search)
            }
            .onAppear {
                productsViewModel.load(for: .initial)
            }
            .onTriggerLoadMoreAt(offset: loadMoreTriggerOffset) {
                productsViewModel.load(for: .loadMore)
            }
        }
    }
}

// Convenience init.
extension ProductsListView where CategoryVM == DefaultCategoryViewModel {
    init(productsViewModel: ProductVM) {
        self.init(productsViewModel: productsViewModel, categoryViewModel: DefaultCategoryViewModel())
    }
}

private extension View {

    func onTriggerLoadMoreAt(offset: CGFloat, action: @escaping () -> Void) -> some View {
        return self
            .onScrollGeometryChange(for: Bool.self) { geometry in
                guard geometry.contentSize.height > 0 else { return false }

                let maxOffset = geometry.contentSize.height - geometry.containerSize.height
                let currentOffset = geometry.contentOffset.y

                return currentOffset >= maxOffset - offset

            } action: { _, isNearBottom in
                if isNearBottom {
                    action()
                }
            }
    }
}

struct ProgressViewOverlay: View {
    let loadingState: LoadingState
    let isEmpty: Bool
    var onRetry: (() -> Void)? = nil

    var body: some View {
        switch loadingState {
        case .initial, .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxHeight: .infinity)

        case .loadingMore:
            ProgressView()
                .controlSize(.large)
                .padding()
                .frame(maxHeight: .infinity, alignment: .bottom)

        case .loadingComplete:
            if isEmpty {
                ContentUnavailableView(
                    "No products available",
                    systemImage: "basket"
                )
            }

        case .loadingError(let error):
            VStack(spacing: 16) {
                Text(error)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    onRetry?()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxHeight: .infinity)

        case .loadingMoreError(let error):
            Text(error)
                .foregroundStyle(.red)
                .padding()
                .background(.thinMaterial).cornerRadius(5).shadow(radius: 5)
        }
    }
}


#Preview("Happy Path") {
    @State @Previewable var viewModel = DefaultProductsViewModel(service: MockProductsService())
    ProductsListView(productsViewModel: viewModel)
}

#Preview("Error") {
    @State @Previewable var viewModel = DefaultProductsViewModel(service: MockProductsService(error: APIError.invalidResponse))
    ProductsListView(productsViewModel: viewModel)
}
