import SwiftUI

struct ProductListingView: View {
    
    @StateObject private var viewModel = ProductViewModel()
    
    
    @State private var searchText: String = ""
    
    
    var body: some View {
        NavigationView {
            VStack {
                // Product List
                
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(filteredProducts, id: \.id) { product in
                                ProductCardView(product: product, isFavorite: viewModel.favorites.contains(product.id)) {
                                    viewModel.toggleFavorite(productID: product.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            .navigationTitle("Products")
            .searchable(text: $searchText, prompt: "Search products...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddProductView(viewModel: viewModel) {
                                            viewModel.fetchProducts() // Callback to refresh data
                                        }) {
                                            Image(systemName: "plus")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                        }
                }
            }
            .onAppear {
                viewModel.fetchProducts()
            }
            
        }
    }
    
    // Filter products based on the search text
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return viewModel.products.sorted { viewModel.favorites.contains($0.id) && !viewModel.favorites.contains($1.id) }
        } else {
            return viewModel.products.filter { $0.product_name.localizedCaseInsensitiveContains(searchText) }
                .sorted { viewModel.favorites.contains($0.id) && !viewModel.favorites.contains($1.id) }
        }
    }
    
    

}



struct ProductCardView: View {
    let product: Product
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            // Product Image
            AsyncImage(url: URL(string: product.image)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else if phase.error == nil {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                }
            }
            
            // Product Details
            VStack(alignment: .leading, spacing: 4) {
                Text(product.product_name)
                    .font(.headline)
                Text(product.product_type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.subheadline)
                    Text("Tax: \(product.tax)%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            // Favorite Icon
            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}



#Preview{
    ProductListingView()
}
