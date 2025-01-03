//
//  Model.swift
//  Swipe
//
//  Created by Prateek Kumar Rai on 05/12/24.
//
import SwiftUI


struct Product: Identifiable, Codable, Hashable {
    let id: String
    let product_name: String
    let product_type: String
    let price: Double
    let tax: Double
    let image: String
    
    enum CodingKeys: String, CodingKey {
        case product_name, product_type, price, tax, image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.product_name = try container.decode(String.self, forKey: .product_name)
        self.product_type = try container.decode(String.self, forKey: .product_type)
        self.price = try container.decode(Double.self, forKey: .price)
        self.tax = try container.decode(Double.self, forKey: .tax)
        self.image = try container.decode(String.self, forKey: .image)
        
        // Generate a unique id by hashing combined values
        self.id = "\(product_name)\(product_type)\(price)\(tax)"
    }
    
    // Default initializer for manual usage
    init(product_name: String, product_type: String, price: Double, tax: Double, image: String) {
        self.product_name = product_name
        self.product_type = product_type
        self.price = price
        self.tax = tax
        self.image = image
        self.id = "\(product_name)\(product_type)\(price)\(tax)"
    }
}



struct LocalProduct: Codable, Hashable {
    let product_name: String
    let product_type: String
    let price: Double
    let tax: Double
    let image: String
}
