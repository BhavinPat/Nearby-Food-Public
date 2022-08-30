//
//  NearbyCategoryTableViewCell.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/14/22.
//

import OSLog
import UIKit

class NearbyCategoryTableViewCell: UITableViewCell {

    @IBAction func categorySelectedButtonAct(_ sender: UIButton) {
        if isCheckmarked {
            var categoryTitles = defaults.array(forKey: "nearbyCategoriesSelectedTitle") as! [String]
            var categories = defaults.array(forKey: "nearbyCategoriesSelected") as! [String]
            categories.removeAll { $0 == aliasName}
            categoryTitles.removeAll { $0 == titleName}
            defaults.set(categories, forKey: "nearbyCategoriesSelected")
            defaults.set(categoryTitles, forKey: "nearbyCategoriesSelectedTitle")
            let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .label)
            let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
            let configuration = colorConfiguration.applying(scaleConfiguration)
            let image = UIImage(systemName: "circle", withConfiguration: configuration)
            categorySelectedButton.setImage(image, for: .normal)
        } else {
            var categoryTitles = defaults.array(forKey: "nearbyCategoriesSelectedTitle") as! [String]
            var categories = defaults.array(forKey: "nearbyCategoriesSelected") as! [String]
            if categories.count == 9 {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "toMuchcategoriesSelected"), object: nil, userInfo: nil)
                return
            }
            categories.append(aliasName)
            categoryTitles.append(titleName)
            defaults.set(categories, forKey: "nearbyCategoriesSelected")
            defaults.set(categoryTitles, forKey: "nearbyCategoriesSelectedTitle")
            let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
            let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
            let configuration = colorConfiguration.applying(scaleConfiguration)
            let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)
            categorySelectedButton.setImage(image, for: .normal)
        }
        
        
        
        
        isCheckmarked = !isCheckmarked
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBOutlet weak var categorySelectedButton: UIButton!
    var isCheckmarked = false
    var titleName = ""
    var aliasName = ""
    let defaults = UserDefaults.standard
    @IBOutlet weak var categoryName: UILabel!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
