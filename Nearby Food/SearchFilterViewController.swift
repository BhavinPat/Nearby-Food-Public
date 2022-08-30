//
//  SearchFilterViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 11/5/21.
//

import UIKit
import OSLog

class SearchFilterViewController: UIViewController {

    
    let defaults = UserDefaults.standard
    var categories: [CategoryDetails?] = []
    let notBuyAvailableCategoriesAlias: [String] = ["coffee", "desserts", "icecream", "newamerican", "burgers", "cafes", "chinese", "italian", "mexican", "seafood", "pizza", "sandwiches", "vegan"]
    @IBOutlet weak var categoryTableView: UITableView!
    //@IBOutlet weak var ratingImage: UIImageView!
    //@IBOutlet weak var ratingStepper: UIStepper!
    @IBOutlet weak var basePriceLabel: UILabel!
    @IBOutlet weak var basePriceStepper: UIStepper!
    @IBOutlet weak var maxPriceLabel: UILabel!
    @IBOutlet weak var maxPriceStepper: UIStepper!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var distanceTextBox: UITextField! {
        didSet {
                distanceTextBox?.addDoneButtonOnKeyboard()            }
    }
    @IBOutlet weak var moreCategories: UIButton!
    @IBOutlet weak var hoursSegementedControl: UISegmentedControl!
    /*
    @IBAction func ratingStepperAction(_ sender: UIStepper) {
        var imageName = "large_"
        let stringValue = String(sender.value)
        let stringArray = Array(stringValue)
        let decimalValue = stringArray[2]
        let firstValue = stringArray[0]
        imageName.append(firstValue)
        if decimalValue != "0" {
            imageName.append("_half")
        }
        ratingImage.image = UIImage(named: imageName)
        defaults.set(sender.value, forKey: "filterRating")
    }
     */
    @IBAction func moreCategoriesAct(_ sender: UIButton!) {
        if defaults.bool(forKey: "didBuyCategoryIAP") {
            moreCategories.isHidden = true
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "store") as! StoreViewController
            vc.modalPresentationStyle = .fullScreen
            vc.howIsComing = HowIsComingToStore.mapViewMoreCategories
            self.present(vc, animated: true, completion: nil)
        }
    }
    @IBAction func basePriceStepperAction(_ sender: UIStepper) {
        var priceString = ""
        let value = Int(sender.value)
        for _ in 0..<value {
            priceString.append("$")
        }
        basePriceLabel.text = priceString
        let basePrice = sender.value
        if basePrice > maxPriceStepper.value {
            maxPriceStepper.value = basePrice
            maxPriceLabel.text = basePriceLabel.text
        }
        defaults.set(value, forKey: "baseFilterPrice")
        defaults.set(priceRange(), forKey: "filterPrice")
    }
    
    @IBAction func maxPriceStepperAction(_ sender: UIStepper) {
        var priceString = ""
        let value = Int(sender.value)
        for _ in 0..<value {
            priceString.append("$")
        }
        maxPriceLabel.text = priceString
        let maxPrice = sender.value
        if maxPrice < basePriceStepper.value {
            basePriceStepper.value = maxPrice
            basePriceLabel.text = maxPriceLabel.text
        }
        defaults.set(value, forKey: "maxFilterPrice")
        defaults.set(priceRange(), forKey: "filterPrice")
    }
    func priceRange() -> String {
        let basePrice = Int(basePriceStepper.value)
        let maxPrice = Int(maxPriceStepper.value)
        var priceRange: String = ""
        for x in basePrice...maxPrice {
            priceRange.append("\(x),")
        }
        priceRange.removeLast()
        return priceRange
    }
    
    @IBAction func hoursSegmentedControlAction(_ sender: UISegmentedControl) {
        var notOpen: Bool
        if sender.selectedSegmentIndex == 0 {
            notOpen = false
        } else {
            notOpen = true
        }
        defaults.set(notOpen, forKey: "filterIsNotOpenNow")
    }
    @IBAction func backButton(_ sender: UIButton) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "searchFilterBackToMap"), object: nil, userInfo: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        distanceTextBox.delegate = self
        distanceTextBox.keyboardType = .decimalPad
        categoryTableView.delegate = self
        categoryTableView.dataSource = self
        categoryTableView.layer.masksToBounds = true
        categoryTableView.layer.cornerRadius = 20
        categoryTableView.backgroundColor = .secondarySystemBackground
        NotificationCenter.default.addObserver(self, selector: #selector(reloadtableView), name: NSNotification.Name(rawValue: "reloadCategoryTableView"), object: nil)
        // Do any additional setup after loading the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "searchFilterBackToMap"), object: nil, userInfo: nil)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: scrollView.contentSize.height)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //setUpRating()
        setUpMaxprice()
        setUpBasePrice()
        setUpHours()
        setUpDistance()
        setUpMoreCategories()
        let categoryRequest = CategoriesRequest()
        categoryRequest.getCategories { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
            case .success(let categories1):
                self?.categories = []
                var allFoodCategories: [CategoryDetails] = []
                for category in categories1 {
                    let parents = category.parent_aliases.joined(separator: "-")
                    if parents.contains("food") || parents.contains("restaurants") {
                        allFoodCategories.append(category)
                        if self?.defaults.bool(forKey: "didBuyCategoryIAP") == true {
                            self?.categories.append(category)
                        } else {
                            if (self?.notBuyAvailableCategoriesAlias.contains(category.alias)) == true {
                                self?.categories.append(category)
                            }
                        }
                    }
                }
                var newAllFoodCategory: [CategoryDetails] = []
                for allFoodCategory in allFoodCategories {
                    if !self!.notBuyAvailableCategoriesAlias.contains(allFoodCategory.alias) {
                        newAllFoodCategory.append(allFoodCategory)
                    }
                }
                AllCategoryAvailable.shared.allCategoriesAvailable = newAllFoodCategory
                DispatchQueue.main.async {
                    self?.categoryTableView.reloadData()
                }
            }
        }
    }
    @objc func reloadtableView() {
        self.categoryTableView.reloadData()
    }
    func setUpMoreCategories() {
        if defaults.bool(forKey: "didBuyCategoryIAP") {
            moreCategories.isHidden = true
        } else {
            moreCategories.isHidden = false
        }
    }
    func setUpDistance() {
        
        if Locale.current.usesMetricSystem {
            distanceTextBox.placeholder = "Kilometers"
            if defaults.integer(forKey: "filterDistance") != 0 {
                distanceTextBox.text = String((defaults.integer(forKey: "filterDistance"))/1000)
            }
        } else {
            distanceTextBox.placeholder = "Miles"
            if defaults.integer(forKey: "filterDistance") != 0 {
                distanceTextBox.text = String((defaults.integer(forKey: "filterDistance"))/1069)
            }
        }
    }
    /*
    func setUpRating() {
        var rating = defaults.double(forKey: "filterRating")
        if rating == 0 {
            rating = 3.0
            defaults.set(rating, forKey: "filterRating")
        }
        ratingStepper.value = rating
        var imageName = "large_"
        let stringValue = String(rating)
        let stringArray = Array(stringValue)
        let decimalValue = stringArray[2]
        let firstValue = stringArray[0]
        imageName.append(firstValue)
        if decimalValue != "0" {
            imageName.append("_half")
        }
        ratingImage.image = UIImage(named: imageName)
    }
     */
    func setUpBasePrice() {
        var basePrice = defaults.integer(forKey: "baseFilterPrice")
        if basePrice == 0 {
            basePrice = 1
            defaults.set(1, forKey: "baseFilterPrice")
        }
        basePriceStepper.value = Double(basePrice)
        
        var basePriceString = ""
        let baseValue = Int(basePrice)
        for _ in 0..<baseValue {
            basePriceString.append("$")
        }
        basePriceLabel.text = basePriceString
        
    }
    func setUpMaxprice() {
        var maxPrice = defaults.integer(forKey: "maxFilterPrice")
        if maxPrice == 0 {
            maxPrice = 4
            defaults.set(4, forKey: "maxFilterPrice")
            defaults.set("1,2,3,4", forKey: "filterPrice")
        }
        maxPriceStepper.value = Double(maxPrice)
        var maxPriceString = ""
        let maxValue = Int(maxPrice)
        for _ in 0..<maxValue {
            maxPriceString.append("$")
        }
        maxPriceLabel.text = maxPriceString
    }
    func setUpHours() {
        let notOpen = defaults.bool(forKey: "filterIsNotOpenNow")
        if notOpen {
            hoursSegementedControl.selectedSegmentIndex = 1
        } else {
            hoursSegementedControl.selectedSegmentIndex = 0
        }
    }
    @objc func donePressedTextField() {
        func textFieldDidEndEditing(_ textField: UITextField) {
            guard let distance = Int(textField.text ?? "") else {
                return
            }
            if !Locale.current.usesMetricSystem {
                //miles
                let radius = distance * 1069
                defaults.set(radius, forKey: "filterDistance")
            } else {
                let radius = distance * 1000
                defaults.set(radius, forKey: "filterDistance")
            }
        }
        distanceTextBox.resignFirstResponder()
    }
    func distanceTextFieldWorking(_ textField: UITextField) {
        guard let distance = Int(textField.text ?? "") else {
            if Locale.current.usesMetricSystem {
                if defaults.integer(forKey: "filterDistance") != 0 {
                    distanceTextBox.text = String((defaults.integer(forKey: "filterDistance"))/1000)
                } else {
                    distanceTextBox.text = nil
                }
            } else {
                if defaults.integer(forKey: "filterDistance") != 0 {
                    distanceTextBox.text = String((defaults.integer(forKey: "filterDistance"))/1069)
                } else {
                    distanceTextBox.text = nil
                }
            }
            return
        }
        if !Locale.current.usesMetricSystem {
            //miles
            let radius = distance * 1069
            defaults.set(radius, forKey: "filterDistance")
        } else {
            let radius = distance * 1000
            defaults.set(radius, forKey: "filterDistance")
        }
    }
    deinit {
    }
}

extension SearchFilterViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        distanceTextFieldWorking(textField)
        textField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    
}

extension SearchFilterViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count + 2
    }
    //if food is checkedmarked should reset all categories to just food. same thing with restaurant
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCategoryTableViewCell", for: indexPath) as! FilterCategoryTableViewCell
        cell.backgroundColor = .secondarySystemBackground
        if indexPath.row == 0 {
            cell.categoryName.text = "All Food"
            cell.aliasName = "food"
            if let _ = defaults.array(forKey: "filterCheckmarkedCategories") as? [String] {
            } else {
                let arrayString: [String] = ["food", "restaurants"]
                defaults.set(arrayString, forKey: "filterCheckmarkedCategories")
            }
            let checkmarkedCategories = defaults.array(forKey: "filterCheckmarkedCategories") as! [String]
            for checkmarkedCategory in checkmarkedCategories {
                if checkmarkedCategory == "food" {
                    cell.isCheckmarked = true
                    let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
                    let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
                    let configuration = colorConfiguration.applying(scaleConfiguration)
                    let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)
                    cell.categorySelectedButton.setImage(image, for: .normal)
                    break
                } else {
                    cell.isCheckmarked = false
                }
            }
            if !cell.isCheckmarked {
                let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .label)
                let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
                let configuration = colorConfiguration.applying(scaleConfiguration)
                let image = UIImage(systemName: "circle", withConfiguration: configuration)
                cell.categorySelectedButton.setImage(image, for: .normal)
            }
            return cell
        }
        if indexPath.row == 1 {
            cell.categoryName.text = "All Restaurants"
            cell.aliasName = "restaurants"
            let checkmarkedCategories = defaults.array(forKey: "filterCheckmarkedCategories") as! [String]
            for checkmarkedCategory in checkmarkedCategories {
                if checkmarkedCategory == "restaurants" {
                    cell.isCheckmarked = true
                    let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
                    let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
                    let configuration = colorConfiguration.applying(scaleConfiguration)
                    let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)
                    cell.categorySelectedButton.setImage(image, for: .normal)
                    break
                } else {
                    cell.isCheckmarked = false
                }
            }
            if !cell.isCheckmarked {
                let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .label)
                let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
                let configuration = colorConfiguration.applying(scaleConfiguration)
                let image = UIImage(systemName: "circle", withConfiguration: configuration)
                cell.categorySelectedButton.setImage(image, for: .normal)
            }
            return cell
        }
        if categories.count == 0 {
            cell.categoryName.text = ""
            return cell
        }
        if indexPath.row - 2 >= categories.count {
            cell.categoryName.text = ""
            return cell
        }
        guard let category = categories[indexPath.row - 2] else {
            cell.categoryName.text = ""
            return cell
        }
        cell.categoryName.text = category.title
        cell.aliasName = category.alias
        let checkmarkedCategories = defaults.array(forKey: "filterCheckmarkedCategories") as! [String]
        for checkmarkedCategory in checkmarkedCategories {
            if checkmarkedCategory == category.alias {
                cell.isCheckmarked = true
                let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
                let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
                let configuration = colorConfiguration.applying(scaleConfiguration)
                let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)
                cell.categorySelectedButton.setImage(image, for: .normal)
                break
            } else {
                cell.isCheckmarked = false
            }
        }
        if !cell.isCheckmarked {
            let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .label)
            let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
            let configuration = colorConfiguration.applying(scaleConfiguration)
            let image = UIImage(systemName: "circle", withConfiguration: configuration)
            cell.categorySelectedButton.setImage(image, for: .normal)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select Categories"
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    //find if selected and remove it or add it
    //categories in search request no space between commas
}
