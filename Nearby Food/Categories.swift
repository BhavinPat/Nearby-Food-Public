//
//  Categories.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 12/14/21.
//

import Foundation
struct CategoriesResults: Decodable {
    var categories: [CategoryDetails]
}
struct CategoryDetails: Decodable {
    var alias, title: String
    var parent_aliases: [String]
}
