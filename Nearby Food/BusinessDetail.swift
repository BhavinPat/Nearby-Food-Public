//
//  BusinessDetail.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 11/13/21.
//

import Foundation

struct BusinessDetail: Decodable {
    var id: String
    var alias: String?
    var name: String
    var image_url: String
    var url: String
    var rating: Double
    var is_claimed: Bool?
    var is_closed: Bool?
    var phone: String?
    var display_phone: String
    var review_count: Int
    var categories: [Categories]
    var photos: [String]?
    var price: String?
    var hours: [Hours?]
    var location: Location
    var coordinates: Coordinates
    var transactions: [String]?
    var messaging: [String: String]?
}
struct Hours: Decodable {
    var open: [OpenTimes]
    var hours_type: String?
    var is_open_now: Bool?
}
struct OpenTimes: Decodable {
    var is_overnight: Bool?
    var start: String
    var end: String
    var day: Int
}
