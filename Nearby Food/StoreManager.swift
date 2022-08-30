//
//  StoreManager.swift
//  Nearby Food
//
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/7/22.
//

import Foundation
import StoreKit
import Firebase
import FirebaseAuth
import OSLog

class StoreManager: NSObject {  
    var validProducts = [SKProduct]()
    var requestProd = SKProductsRequest()
    var totalRestoredPurchases = 0
    let defaults = UserDefaults.standard
    var ref: DatabaseReference!
    /**
     Initialize StoreManager and load subscriptions SKProducts from Store
     */
    static let shared = StoreManager()

    func Begin() {
        Logger().info("StoreManager did init")
        ref = Database.database().reference()
    }

    deinit {
        Logger().info("StoreManager did deinit")
    }
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    func requestProductWithID() {
        let identifiers = Set(["com.bhavinp.NearbyFood.buyCategories", "com.bhavinp.NearbyFood.nearbyCustomization"])
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: identifiers)
            self.requestProd = request
            request.delegate = self
            request.start()
        } else {
            Logger().error("ERROR: Store Not Available")
        }
    }
    
    func buyProduct(product: SKProduct) {
        if canMakePurchases() {
            Logger().info("Buying \(product.productIdentifier)...")
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            Logger().info("cant make payment")
        }
    }

    func restorePurchases() {
        totalRestoredPurchases = 0
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK:
// MARK: SKProductsRequestDelegate

//The delegate receives the product information that the request was interested in.
extension StoreManager:SKProductsRequestDelegate{
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        let products = response.products as [SKProduct]

        //var buys = [SKProduct]()

        if (products.count > 0) {
            for i in 0 ..< products.count {
                let product = products[i]
                Logger().info("Product Found: \(product.localizedTitle)")
            }
        } else {
            Logger().error("couldnt find any products")
        }

        let productsInvalidIds = response.invalidProductIdentifiers

        for product in productsInvalidIds {
            Logger().error("couldnt find product: \(product)")
        }
        
        Logger().error("\(response.invalidProductIdentifiers)")
        if (response.products.count > 0) {
            validProducts = response.products
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "validProductsStore"), object: nil, userInfo: nil)
        }
        
        
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        Logger().error("\(error.localizedDescription)")
    }
    
}

// MARK:
// MARK: SKTransactions

extension StoreManager: SKPaymentTransactionObserver {

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction: transaction)
                break
            case .failed:
                failedTransaction(transaction: transaction)
                break
            case .restored:
                totalRestoredPurchases += 1
                restoreTransaction(transaction: transaction)
                break
            case .deferred:
                deferredTransaction(transaction: transaction)
                break
            case .purchasing:
                purchasingTransaction(transaction: transaction)
                break
            @unknown default:
                fatalError()
            }
        }
    }

    private func completeTransaction(transaction: SKPaymentTransaction) {
        let productIdentiferBought = transaction.payment.productIdentifier
        let transactionString = "\(transaction.transactionIdentifier ?? "error transaction ID") -> Bought: \(transaction.payment.productIdentifier) Type: non restore first time purchase on account"
        if productIdentiferBought == "com.bhavinp.NearbyFood.buyCategories" {
            defaults.set(true, forKey: "didBuyCategoryIAP")
        } else if productIdentiferBought == "com.bhavinp.NearbyFood.nearbyCustomization" {
            defaults.set(true, forKey: "didBuyCustomNearbyIAP")
        }
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("IAPTransactionStore").observeSingleEvent(of: .value, with: { [self]
                (snapshot) in
                var transactionArray: [String] = []
                if let transactionArray1 = snapshot.value as? [String] {
                    transactionArray = transactionArray1
                }
                transactionArray.append(transactionString)
                let userRef = ref.child("users/" + user.uid)
                userRef.child("IAPTransactionStore").setValue(transactionArray)
            })
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "completeTransaction"), object: nil, userInfo: ["value": productIdentiferBought])
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restoreTransaction(transaction: SKPaymentTransaction) {
        guard let productIdentiferBought = transaction.original?.payment.productIdentifier else { return }
        if productIdentiferBought == "com.bhavinp.NearbyFood.buyCategories" {
            defaults.set(true, forKey: "didBuyCategoryIAP")
        } else if productIdentiferBought == "com.bhavinp.NearbyFood.nearbyCustomization" {
            defaults.set(true, forKey: "didBuyCustomNearbyIAP")
        }
        let transactionString = "\(transaction.transactionIdentifier ?? "error transaction ID") -> Bought: \(transaction.payment.productIdentifier) Type: Restored"
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("IAPTransactionStore").observeSingleEvent(of: .value, with: { [self]
                (snapshot) in
                var transactionArray: [String] = []
                if let transactionArray1 = snapshot.value as? [String] {
                    transactionArray = transactionArray1
                }
                transactionArray.append(transactionString)
                let userRef = ref.child("users/" + user.uid)
                userRef.child("IAPTransactionStore").setValue(transactionArray)
            })
        }
        Logger().error("restoreTransaction... \(productIdentiferBought)")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "restoredTransaction"), object: nil, userInfo: ["value": productIdentiferBought])
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    private func deferredTransaction(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "deferredTransaction"), object: nil, userInfo: nil)
    }
    private func purchasingTransaction(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "purchasingTransaction"), object: nil, userInfo: nil)
    }
    private func failedTransaction(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "failedTransaction"), object: nil, userInfo: nil)
        
        SKPaymentQueue.default().finishTransaction(transaction)
        if let error = transaction.error as NSError? {
            if error.domain == SKErrorDomain {
                // handle all possible errors
                switch (error.code) {
                case SKError.unknown.rawValue:
                    Logger().error("Unknown error")
                case SKError.clientInvalid.rawValue:
                    Logger().error("client is not allowed to issue the request")
                case SKError.paymentCancelled.rawValue:
                    Logger().error("user cancelled the request")
                case SKError.paymentInvalid.rawValue:
                    Logger().error("purchase identifier was invalid")
                case SKError.paymentNotAllowed.rawValue:
                    Logger().error("this device is not allowed to make the payment")
                default:
                    break;
                }
            }

        }

        SKPaymentQueue.default().finishTransaction(transaction)
    }
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        Logger().info("restore finished")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "retoreFinished"), object: nil, userInfo: nil)
    }
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        Logger().error("restore finished")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "restoreFailed"), object: nil, userInfo: ["value": error])
    }
}

//In-App Purchases App Store
extension StoreManager{
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        requestProductWithID()
        buyProduct(product: product)
        return true
        //To hold
        //return false

        //And then to continue
        //SKPaymentQueue.default().add(savedPayment)
        
        
        
        //here do product index. then call purchaseMyproduct
        //or does it automatically do it? skipping purcheseMyProduct
        //either way need to do product index here
        
    }
}

