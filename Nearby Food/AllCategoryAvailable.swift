//
//  AllCategoryAvailable.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 2/20/22.
//

import Foundation
import OSLog

class AllCategoryAvailable: NSObject {
    static let shared = AllCategoryAvailable()
    var allCategoriesAvailable: [CategoryDetails] = []
    override init() {
        super.init()
    }
    let notBuyAvailableCategoriesAlias: [String] = ["coffee", "desserts", "icecream", "newamerican", "burgers", "cafes", "chinese", "italian", "mexican", "seafood", "pizza", "sandwiches", "vegan"]
    func Begin() {
        let categoryRequest = CategoriesRequest()
        categoryRequest.getCategories { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
            case .success(let categories1):
                var allFoodCategories: [CategoryDetails] = []
                for category in categories1 {
                    let parents = category.parent_aliases.joined(separator: "-")
                    if parents.contains("food") || parents.contains("restaurants") {
                        allFoodCategories.append(category)
                    }
                }
                var newAllFoodCategory: [CategoryDetails] = []
                for allFoodCategory in allFoodCategories {
                    if !self!.notBuyAvailableCategoriesAlias.contains(allFoodCategory.alias) {
                        newAllFoodCategory.append(allFoodCategory)
                    }
                }
                self!.allCategoriesAvailable = newAllFoodCategory
            }
        }
    }
    deinit {
        Logger().info("All Category Available deinit")
    }
}
