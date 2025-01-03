//
//  Network Manager.swift
//  Swipe
//
//  Created by Prateek Kumar Rai on 05/12/24.
//

import SwiftUI
import Network

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
//    {
//        didSet {
//                products = Array(Set(products)) // This ensures unique values
//            }
//    }
    @Published var isLoaded: Bool = true
    @Published var errorMessage: String? = nil
    @Published var favorites: Set<String> = []
    
    
    private let productsKey = "storedProducts"
    private let offlineProductsKey = "offlineProducts"
    private let favoritesKey = "storedFavorites"

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isOnline: Bool = true
    
    private let apiURL = "https://app.getswipe.in/api/public/get"
    
    init() {
            loadProducts()
            loadFavorites()
            startMonitoring()
//        print("hihi")
//            syncOfflineProducts()
        }
    
    func fetchProducts() {
//        print("fetching started")
        isLoaded = true
        errorMessage = nil
        
        guard let url = URL(string: apiURL) else {
            errorMessage = "Invalid URL."
            isLoaded = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                do {
                    let decodedProducts = try JSONDecoder().decode([Product].self, from: data)
//                    print(decodedProducts)
                    DispatchQueue.main.async {
                        self.products = decodedProducts
                        self.saveProducts()
                    }
                    self.isLoaded = false
//                    print(self.products)
                } catch {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func saveProducts() {
            if let encoded = try? JSONEncoder().encode(products) {
                UserDefaults.standard.set(encoded, forKey: productsKey)
            }
        }
    
    func loadProducts() {
            if let data = UserDefaults.standard.data(forKey: productsKey),
               let decodedProducts = try? JSONDecoder().decode([Product].self, from: data) {
                products = decodedProducts
            }
        }
    
    func saveFavorites() {
        let ids = Array(favorites)
            UserDefaults.standard.set(ids, forKey: favoritesKey)
        }
    
    func loadFavorites() {
            if let ids = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
                favorites = Set(ids)
            }
        }
    
    func toggleFavorite(productID: String) {
        withAnimation{
            if favorites.contains(productID) {
                favorites.remove(productID)
            } else {
                favorites.insert(productID)
            }
            saveFavorites()
        }
        }
    
    private func startMonitoring() {
            monitor.pathUpdateHandler = { path in
                DispatchQueue.main.async {
                    self.isOnline = path.status == .satisfied
                    if self.isOnline {
                        self.syncOfflineProducts()
//                        print("sync in progres")
                    }
                }
            }
            monitor.start(queue: queue)
        }
    private func syncOfflineProducts() {
//        print("try to sync")
            guard isOnline else { return }
//        print("Device online")
            let offlineProducts = loadOfflineProducts()
        print(offlineProducts)
            for product in offlineProducts {
//                if products.contains(product){continue}
                print(product)
                submitProduct(product: product,selectedImage: nil)
//                print("Submitting")
            }
//        print("clearing saved data")
            UserDefaults.standard.removeObject(forKey: offlineProductsKey)
        }
    
    private func loadOfflineProducts() -> [Product] {
        if let data = UserDefaults.standard.data(forKey: offlineProductsKey) {
            print("Raw data from UserDefaults: \(String(data: data, encoding: .utf8) ?? "")")

            do {
                // Decoding into LocalProduct first
                let decoded = try JSONDecoder().decode([LocalProduct].self, from: data)
                print("Decoded LocalProducts: \(decoded)")

                // Mapping LocalProduct to Product
                var list: [Product] = []
                for localProduct in decoded {
                    // Initialize Product with values from LocalProduct
                    let product = Product(
                        product_name: localProduct.product_name,
                        product_type: localProduct.product_type,
                        price: localProduct.price,
                        tax: localProduct.tax,
                        image: "" // Placeholder for now
                    )
                    list.append(product)
                }
                return list
            } catch {
                print("Failed to decode data: \(error)")
            }
        } else {
            print("No data found in UserDefaults.")
        }
        return []
    }

    

    func submitProduct(product:Product, selectedImage:UIImage?) {
        guard !product.product_name.isEmpty else {
            showErrorWithMessage("Product name cannot be empty.")
            return
        }
//        print(103)
        
        let priceValue = product.price
        
        let taxValue = product.tax
        
        // Construct form-data
        let parameters: [String: String] = [
            "product_name": product.product_name,
            "product_type": product.product_type,
            "price": String(priceValue),
            "tax": String(taxValue)
        ]
        
        // Prepare the multipart form data request
        guard let url = URL(string: "https://app.getswipe.in/api/public/add") else {
            showErrorWithMessage("Invalid URL.")
            return
        }
//        print(104)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        print(105)
        let httpBody = createFormData(parameters: parameters, image: selectedImage, boundary: boundary)
        request.httpBody = httpBody
//        print(108)
        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showErrorWithMessage("Error: \(error.localizedDescription)")
//                    print(109)
                }
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.showErrorWithMessage("Failed to add the product.")
//                    print(110)
                }
                return
            }
            
            // Handle the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = json["success"] as? Bool {
//                    print("\(success)")
//                    print(111)
                } else {
                    DispatchQueue.main.async {
                        self.showErrorWithMessage("Failed to parse response.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showErrorWithMessage("Error parsing response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func createFormData(parameters: [String: String], image: UIImage?, boundary: String) -> Data {
        var body = Data()
//        print(106)
        // Add parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add image
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let filename = "image.jpg"
            let mimeType = "image/jpeg"
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files[]\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // End of form-data
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//        print(107)
        return body
    }

    func showErrorWithMessage(_ message: String) {
        errorMessage = message
//        showError = true
    }

    
    func addProduct(_ product: Product,selectedImage:UIImage?) {
            products.append(product)
//        print("appended 101")
            saveProducts()

            if isOnline {
//                print(102)
                submitProduct(product: product,selectedImage: selectedImage)
            } else {
                saveOfflineProduct(product)
            }
        }
    
    private func saveOfflineProduct(_ product: Product) {
            var offlineProducts = loadOfflineProducts()
            offlineProducts.append(product)
        
            if let encoded = try? JSONEncoder().encode(offlineProducts) {
                UserDefaults.standard.set(encoded, forKey: offlineProductsKey)
                print("\(product.id): saved success")
            }
        }
}
