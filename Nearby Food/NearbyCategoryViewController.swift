//
//  NearbyCategoryViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/14/22.
//
import OSLog
import UIKit

class NearbyCategoryViewController: UIViewController {
    @IBOutlet weak var categoryTableView: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var moreCategories: UIButton!
    @IBAction func doneButtonAct(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RequestNewDataNearbyVC"), object: nil, userInfo: nil)
    }
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
    var categories: [CategoryDetails?] = []
    let defaults = UserDefaults.standard
    let notBuyAvailableCategoriesAlias: [String] = ["coffee", "desserts", "icecream", "newamerican", "burgers", "cafes", "chinese", "italian", "mexican", "seafood", "pizza", "sandwiches", "vegan"]
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        categoryTableView.delegate = self
        categoryTableView.dataSource = self
        categoryTableView.sectionHeaderTopPadding = .leastNormalMagnitude
        NotificationCenter.default.addObserver(self, selector: #selector(toMuchAlert), name: NSNotification.Name(rawValue: "toMuchcategoriesSelected"), object: nil)
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if defaults.bool(forKey: "didBuyCategoryIAP") {
            moreCategories.isHidden = true
        } else {
            moreCategories.isHidden = false
        }
        let categoryRequest = CategoriesRequest()
        categoryRequest.getCategories { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
            case .success(let categories1):
                self?.categories = []
                for category in categories1 {
                    let parents = category.parent_aliases.joined(separator: "-")
                    if parents.contains("food") || parents.contains("restaurants") {
                        if self?.defaults.bool(forKey: "didBuyCategoryIAP") == true {
                            self?.categories.append(category)
                        } else {
                            if (self?.notBuyAvailableCategoriesAlias.contains(category.alias)) == true {
                                self?.categories.append(category)
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self?.categoryTableView.reloadData()
                }
            }
        }
    }
    @objc func toMuchAlert() {
        let toMuchAlert = UIAlertController(title: "To Many Categories", message: "Remove selected categories to add more", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel)
        toMuchAlert.addAction(ok)
        self.present(toMuchAlert, animated: true, completion: nil)
    }
    deinit {
        Logger().info("NearbyCategoryVC deinit")
    }

}
extension NearbyCategoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = categoryTableView.dequeueReusableCell(withIdentifier: "nearbyCategoryTableViewCell", for: indexPath) as! NearbyCategoryTableViewCell
        if categories.count == 0 {
            cell.categoryName.text = ""
            return cell
        }
        if indexPath.row - 2 >= categories.count {
            cell.categoryName.text = ""
            return cell
        }
        guard let category = categories[indexPath.row ] else {
            cell.categoryName.text = ""
            return cell
        }
        cell.titleName = category.title
        cell.categoryName.text = category.title
        cell.aliasName = category.alias
        let checkmarkedCategories = defaults.array(forKey: "nearbyCategoriesSelected") as! [String]
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
        return "Select Up to 9"
    }
    
}
