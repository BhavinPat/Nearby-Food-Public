//
//  Search.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/31/21.
//

import Foundation
struct BusinessDetailSearchRequest: Decodable {
    var businesses: [BusinessDetailSearch]
    var region: Region
    var error: ErrorsSearch?
}
struct ErrorsSearch: Decodable {
    var code: String?
    var description: String?
    
}
struct Region: Decodable {
    var center: Center
}
struct Center: Decodable {
    var longitude: Double
    var latitude: Double
}
struct BusinessDetailSearch: Decodable {
    var id: String
    var alias: String
    var name: String
    var image_url: String?
    var is_closed: Bool?
    var url: String
    var review_count: Int
    var categories: [Categories]
    var rating: Decimal
    var coordinates: Coordinates
    var transactions: [String]
    var price: String?
    var location: Location
    var phone: String?
    var display_phone: String?
    var distance: Double
    
}
struct Location: Decodable {
    var address1: String?
    var address2: String?
    var address3: String?
    var city: String?
    var zip_code: String?
    var country: String?
    var state: String?
    var display_address: [String?]
    
}
struct Coordinates: Decodable {
    var latitude: Double
    var longitude: Double
}

struct Categories: Decodable {
    var alias: String?
    var title: String?
}
