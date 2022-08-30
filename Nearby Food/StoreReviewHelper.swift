//
//  StoreReviewHelper.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/7/22.
//

import Foundation
import StoreKit
import OSLog

struct StoreReviewHelper { 
    
    static func incrementAppOpenedCount() { // called from appdelegate didfinishLaunchingWithOptions:
        guard var appOpenCount = UserDefaults.standard.value(forKey: UserDefaultsKeys.APP_OPENED_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: UserDefaultsKeys.APP_OPENED_COUNT)
            return
        }
        appOpenCount += 1
        UserDefaults.standard.set(appOpenCount, forKey: UserDefaultsKeys.APP_OPENED_COUNT)
    }
    
    @MainActor static func checkAndAskForReview() {
        // Call this whenever appropriate.
        incrementAppOpenedCount()
        // This will not be shown everytime. Apple has some internal logic on how to show this.
        guard let appOpenCount = UserDefaults.standard.value(forKey: UserDefaultsKeys.APP_OPENED_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: UserDefaultsKeys.APP_OPENED_COUNT)
            return
        }
        
        switch appOpenCount {
        case 2, 4, 6:
            StoreReviewHelper().requestReview()
        case _ where appOpenCount%6 == 0 :
            StoreReviewHelper().requestReview()
        default:
            Logger().info("App run count is : \(appOpenCount)")
            break;
        }
        
    }
    
    @MainActor func requestReview() {
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.currentScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
}

extension UIApplication {
    var currentScene: UIWindowScene? {
        connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}

struct UserDefaultsKeys {
    static let APP_OPENED_COUNT = "APP_OPENED_COUNT"
}

