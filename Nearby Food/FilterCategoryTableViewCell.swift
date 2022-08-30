//
//  FilterCategoryTableViewCell.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 12/14/21.
//

import UIKit
import OSLog

class FilterCategoryTableViewCell: UITableViewCell {

    @IBAction func categorySelectedButtonAct(_ sender: UIButton) {
        if isCheckmarked {
            //uncheck or remove from list
            var categories = defaults.array(forKey: "filterCheckmarkedCategories") as! [String]
            var value = 0
            for category in categories {
                if category == aliasName {
                    categories.remove(at: value)
                    break
                }
                value += 1
            }
            defaults.set(categories, forKey: "filterCheckmarkedCategories")
        } else {
            if aliasName == "food" || aliasName == "restaurants"{
                defaults.set(["food", "restaurants"], forKey: "filterCheckmarkedCategories")
                //send notification  to reload table cells. do same thing if any other alais is done
            } else {
                var categories = defaults.array(forKey: "filterCheckmarkedCategories") as! [String]
                categories.removeAll { $0 == "food"}
                categories.removeAll { $0 == "restaurants"}
                categories.append(aliasName)
                defaults.set(categories, forKey: "filterCheckmarkedCategories")

                //send notification to reload table cell. remove selected food and restaurants from categories
            }
        }
        isCheckmarked = !isCheckmarked
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadCategoryTableView"), object: nil, userInfo: nil)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBOutlet weak var categorySelectedButton: UIButton!
    var isCheckmarked = false
    var aliasName = ""
    let defaults = UserDefaults.standard
    @IBOutlet weak var categoryName: UILabel!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
