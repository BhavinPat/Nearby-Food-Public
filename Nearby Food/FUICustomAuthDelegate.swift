//
//  FUICustomAuthDelegate.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 8/12/22.
//

import Foundation
import FirebaseAuthUI
import FirebaseAuth
class FUICustomAuthDelegate: NSObject, FUIAuthDelegate {
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        switch error {
        case .some(let error as NSError) where UInt(error.code) == FUIAuthErrorCode.userCancelledSignIn.rawValue:
            print("User cancelled sign-in")
        case .some(let error as NSError) where error.userInfo[NSUnderlyingErrorKey] != nil:
            print("Login error: \(error.userInfo[NSUnderlyingErrorKey]!)")
        case .some(let error):
            print("Login error: \(error.localizedDescription)")
        case .none:
            if let results = authDataResult {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UserIsDeletingAccountNotfication"), object: nil, userInfo: ["user": results])
            }
            return
        }
        
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        let vc = FUICustomAuthPickerViewController(nibName: "FUICustomAuthPickerViewController", bundle: Bundle.main, authUI: authUI)
        if authUI.providers.count == 1 {
            vc.skipButton.isHidden = true
        }
        return vc
    }
}
