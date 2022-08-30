//
//  StoreViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/14/22.
//

import UIKit
import StoreKit
import OSLog

class StoreViewController: UIViewController {
    var howIsComing: HowIsComingToStore!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var buyCategories: UIButton!
    @IBOutlet weak var buyNearbyCategories: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var spinny: UIActivityIndicatorView!
    @IBOutlet weak var blurScreen: UIVisualEffectView!
    @IBOutlet weak var buyCategoryView: UIView!
    @IBOutlet weak var nearbyCategoryView: UIView!
    @IBOutlet weak var buyCategoryTextView: UITextView!
    @IBOutlet weak var nearbyCategoryTextView: UITextView!
    @IBOutlet weak var buyCategoriesPrice: UILabel!
    @IBOutlet weak var nearbyCategoryPrice: UILabel!
    @IBAction func buyCategoriesAct(_ sender: UIButton!) {
        StoreManager.shared.requestProductWithID()
        let productID = "com.bhavinp.NearbyFood.buyCategories"
        for product in StoreManager.shared.validProducts {
            if product.productIdentifier == productID {
                StoreManager.shared.buyProduct(product: product)
                blurScreen.isHidden = false
                spinny.isHidden = false
                spinny.startAnimating()
                view.isUserInteractionEnabled = false
                break
            }
        }
    }
    @IBAction func buyNearbyCategoriesAct(_ sender: UIButton!) {
        StoreManager.shared.requestProductWithID()
        let productID = "com.bhavinp.NearbyFood.nearbyCustomization"
        for product in StoreManager.shared.validProducts {
            if product.productIdentifier == productID {
                StoreManager.shared.buyProduct(product: product)
                blurScreen.isHidden = false
                spinny.isHidden = false
                spinny.startAnimating()
                view.isUserInteractionEnabled = false
                break
            }
        }
    }
    @IBAction func restoreButtonAct(_ sender: UIButton!) {
        StoreManager.shared.requestProductWithID()
        StoreManager.shared.restorePurchases()
        blurScreen.isHidden = false
        spinny.isHidden = false
        spinny.startAnimating()
    }
    @IBAction func doneButtonAct(_ sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
        //make sure redirect is correct. when dismissed
    }
    
    let defualts = UserDefaults.standard
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //check if bought then hide
        StoreManager.shared.requestProductWithID()
        setUpBuyView()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        buyCategories.isEnabled = false
        buyNearbyCategories.isEnabled = false
        StoreManager.shared.requestProductWithID()
        NotificationCenter.default.addObserver(self, selector: #selector(setUpPrices), name: NSNotification.Name(rawValue: "validProductsStore"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(completeTransaction(notification:)), name: NSNotification.Name(rawValue: "completeTransaction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreTransaction(notification:)), name: NSNotification.Name(rawValue: "restoredTransaction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deferredTransaction), name: NSNotification.Name(rawValue: "deferredTransaction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchasingTransaction), name: NSNotification.Name(rawValue: "purchasingTransaction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failedTransaction), name: NSNotification.Name(rawValue: "failedTransaction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFinished), name: NSNotification.Name(rawValue: "retoreFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFailed(notification:)), name: NSNotification.Name(rawValue: "restoreFailed"), object: nil)
    

        // Do any additional setup after loading the view.
    }
    deinit {
        Logger().info("StoreViewController did deinit")
    }
    @objc func setUpPrices() {
        //set up price labels
        let validProducts = StoreManager.shared.validProducts
        for product in validProducts {
            let numberFormatter = NumberFormatter()
            //numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = product.priceLocale
            let string1 = (numberFormatter.string(from: product.price)!)
            DispatchQueue.main.async { [self] in
                if product.productIdentifier == "com.bhavinp.NearbyFood.buyCategories" {
                    buyCategoriesPrice.text = string1
                    buyCategories.isEnabled = true
                    if defualts.bool(forKey: "didBuyCategoryIAP") {
                        buyCategoriesPrice.text = "Bought"
                        buyCategories.isHidden = true
                    }
                } else if product.productIdentifier == "com.bhavinp.NearbyFood.nearbyCustomization" {
                    Logger().info("\(string1)")
                    nearbyCategoryPrice.text = string1
                    buyNearbyCategories.isEnabled = true
                    if defualts.bool(forKey: "didBuyCustomNearbyIAP") {
                        nearbyCategoryPrice.text = "Bought"
                        buyNearbyCategories.isHidden = true
                    }
                }
            }
        }
    }
    func setUpBuyView() {
        buyCategoryView.layer.masksToBounds = true
        nearbyCategoryView.layer.masksToBounds = true
        buyCategoryView.layer.cornerRadius = 6.5
        nearbyCategoryView.layer.cornerRadius = 6.5
        buyCategoryTextView.text =
"""
1. Access to 100+ food categories
2. Access to all 100+ categories in the nearby and map filters
3. Finds exactly what type of meal you are looking for
4. The more specific your filters are the better chance you will find a place you love
"""
        nearbyCategoryTextView.text =
"""
1. Ability to change what food categories are shown nearby
2. If you bought the more categories option you will also be able to customize your nearby list with hundreds of categories
3. Add up to 9 categories to explore at once in your nearby tab
"""
        if defualts.bool(forKey: "didBuyCategoryIAP") {
            buyCategoriesPrice.text = "Bought"
            buyCategories.isHidden = true
        } else {
            buyCategories.isHidden = false
        }
        if defualts.bool(forKey: "didBuyCustomNearbyIAP") {
            nearbyCategoryPrice.text = "Bought"
            buyNearbyCategories.isHidden = true
        } else {
            buyNearbyCategories.isHidden = false
        }
    }
    
    @objc func completeTransaction(notification: NSNotification) {
        view.isUserInteractionEnabled = true
        spinny.isHidden = true
        spinny.stopAnimating()
        blurScreen.isHidden = true
        guard let productIdentiferBought = notification.userInfo!["value"] as? String else {return}
        if productIdentiferBought == "com.bhavinp.NearbyFood.buyCategories" {
            setUpBuyView()
        } else if productIdentiferBought == "com.bhavinp.NearbyFood.nearbyCustomization" {
            setUpBuyView()
        }
    }
    @objc func restoreTransaction(notification: NSNotification) {
        guard let productIdentiferBought = notification.userInfo!["value"] as? String else {return}
        if productIdentiferBought == "com.bhavinp.NearbyFood.buyCategories" {
            setUpBuyView()
        } else if productIdentiferBought == "com.bhavinp.NearbyFood.nearbyCustomization" {
            setUpBuyView()
        }
    }
    @objc func deferredTransaction() {
        Logger().info("payment has deferred")
        view.isUserInteractionEnabled = false
        spinny.isHidden = false
        spinny.startAnimating()
        blurScreen.isHidden = false
    }
    @objc func purchasingTransaction() {
        view.isUserInteractionEnabled = false
        spinny.isHidden = false
        spinny.startAnimating()
        blurScreen.isHidden = false
    }
    @objc func failedTransaction() {
        Logger().info("payment has failed")
        view.isUserInteractionEnabled = true
        spinny.isHidden = true
        spinny.stopAnimating()
        blurScreen.isHidden = true
    }
    @objc func restoreFinished() {
        Logger().info("finish restore")
        view.isUserInteractionEnabled = true
        spinny.isHidden = true
        spinny.stopAnimating()
        blurScreen.isHidden = true
        if StoreManager.shared.totalRestoredPurchases != 0 {
            let alert = UIAlertController(title: "Restored", message: "All purchases have been restored have fun!!!", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        } else {
            Logger().info("IAP: No purchases to restore!")
            let alert = UIAlertController(title: "Restore Failed", message: "It looks like there are no past purchases", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    @objc func restoreFailed(notification: NSNotification) {
        guard let error1 = notification.userInfo!["value"] as? SKError else {return}
        view.isUserInteractionEnabled = true
        spinny.isHidden = true
        spinny.stopAnimating()
        blurScreen.isHidden = true
            if error1.code != .paymentCancelled {
                Logger().error("IAP Restore Error: \(error1.localizedDescription)")
                let alert = UIAlertController(title: "Restore Failed", message: "Error. Try again later!", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
                Logger().error("purchased failed \(error1.localizedDescription)")
            } else {
                Logger().error("purchased failed \(error1.localizedDescription)")
            }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
