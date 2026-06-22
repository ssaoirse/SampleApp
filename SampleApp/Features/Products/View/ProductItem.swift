import SwiftUI

struct ProductItem: View {
    let product: Product
    
    var body: some View {
        HStack {
            
            ProductImage(url: URL(string: product.thumbnail))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(product.category.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if product.discountPercentage > 0 {
                        Text("\(product.discountPercentage, specifier: "%.0f")% off")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text("\(product.rating, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
            }
        }
    }
}

struct ProductImage: View {
    let url: URL?
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Image(systemName: "photo")
                    .scaledToFit()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure(_):
                Image(systemName: "xmark.icloud")
                    .scaledToFit()
                
            @unknown default:
                Image(systemName: "photo")
                    .scaledToFit()
            }
        }
        .frame(width: 100, height: 100)
    }
}

#Preview {
    ProductItem(product: .example)
}
