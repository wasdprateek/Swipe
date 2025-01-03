import SwiftUI
struct AddProductView: View {
    @State private var productName: String = ""
    @State private var productType: String? = nil
    @State private var price: String = ""
    @State private var tax: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @ObservedObject var viewModel : ProductViewModel
    @Environment(\.dismiss) private var dismiss
    var completion: (() -> Void)? // Callback closure
    private let productTypes = ["Electronics", "Clothing", "Beauty", "Books", "Home & Kitchen", "Toys", "Sports", "Grocery", "Pet Supplies", "Baby Products"]
    private var isFormValid: Bool {
            !productName.isEmpty &&
        ((productType?.isEmpty) != nil) &&
            !price.isEmpty &&
            Double(price) != nil &&
            !tax.isEmpty &&
            Double(tax) != nil
        }
    
    var body: some View {
        Form {
            // Product Name
            Section(header: Text("Product Details")) {
                TextField("Product Name", text: $productName)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                
                HStack {
                                    Text("Product Type")
                                    Spacer()
                                    Menu {
                                        ForEach(productTypes, id: \.self) { type in
                                            Button(action: {
                                                productType = type
                                            }) {
                                                HStack {
                                                    Text(type)
                                                    if productType == type {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        Text(productType ?? "Select Product")
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 4)
                                    }
                                }
                
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
                
                TextField("Tax (%)", text: $tax)
                    .keyboardType(.decimalPad)
            }
            
            // Image Picker
            Section(header: Text("Product Image")) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(10)
                } else {
                    Text("No Image Selected")
                        .foregroundColor(.gray)
                }
                
                Button("Select Image") {
                    showImagePicker = true
                }
            }
            
            // Submit Button
            
                Button(action: {
                    let product = Product(
                        product_name: productName,
                        product_type: productType ?? "",
                        price: Double(price) ?? 0.0,
                        tax: Double(tax) ?? 0.0,
                        image: ""
                    )

                    viewModel.addProduct(product, selectedImage: selectedImage)
                    completion?() // Call the completion closure
                    dismiss()
                }) {
                    Text("Add Product")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.accentColor : Color.gray)
                        .cornerRadius(10)
                        .opacity(isFormValid ? 1 : 0.6)
                }
                .disabled(!isFormValid) // Disable when form is invalid
            

        }
        .navigationTitle("Add Product")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
}
