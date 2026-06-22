import SwiftUI

struct FilterProductsView<ViewModel: CategoryViewModel>: View {

    let categoryViewModel: ViewModel

    @Binding var sortBy: SortByField?
    @Binding var selectedCategory: String?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Picker("Sort By", selection: $sortBy) {
                    ForEach(SortByField.allCases) {
                        Text($0.displayName)
                            .tag(Optional($0))
                    }
                }
                .pickerStyle(.inline)

                Picker("Categories", selection: $selectedCategory) {
                    if let error = categoryViewModel.loadingError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .selectionDisabled()
                    } else {
                        Text("All").tag(String?.none)
                        ForEach(categoryViewModel.categories, id: \.self) {
                            Text($0.capitalized)
                                .tag(Optional($0))
                        }
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("Filter Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        sortBy = nil
                        selectedCategory = nil
                        dismiss()
                    }
                }
            }
        }
        .task {
            await categoryViewModel.load()
        }
    }
}

#Preview {
    @State @Previewable var sortBy: SortByField? = nil
    @State @Previewable var selectedCategory: String? = nil

    FilterProductsView(
        categoryViewModel: DefaultCategoryViewModel(),
        sortBy: $sortBy,
        selectedCategory: $selectedCategory
    )
}
