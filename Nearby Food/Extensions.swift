//
//  Extensions.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 7/18/22.
//

import Foundation
import UIKit
import OSLog
import CoreLocation
import FirebaseAuth

enum whatloggedIn {
    case Apple
    case Google
    case Email
}
enum whatloggedInString: String {
    case Apple = "Apple"
    case Google = "Google"
    case Email = "Email"
}
enum HowIsComingToStore {
    case nearbyFromFilterPressed
    case nearbyMoreCategories //if pressed nearby category customization has to also be bought
    case mapViewMoreCategories
}
enum BusinessesError: Error {
    case someError
    case canNotprocessData
}
struct Defualts {
    static let locationDefaults: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 41.878876, longitude: -87.635918)
    static let defaultSearchRequest: String = "https://api.yelp.com/v3/businesses/search?longitude=-87.635918&latitude=41.878876"
    static let defailtSearchRequestURL: URL = URL(string: defaultSearchRequest)!
}
extension UITextField{
    @IBInspectable var doneAccessory: Bool{
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        self.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction()
    {
        self.resignFirstResponder()
    }
}

extension UIView {
    
    func fadeIn(_ duration: TimeInterval? = 0.6, onCompletion: (() -> Void)? = nil) {
        self.layer.removeAllAnimations()
        DispatchQueue.main.async {
            if self.isHidden {
                self.alpha = 0
                self.isHidden = false
                UIView.animate(withDuration: duration!, animations: { self.alpha = 1 }, completion: { (value: Bool) in
                    if let complete = onCompletion { complete() }
                })
            }
        }
    }
    
    func fadeOut(_ duration: TimeInterval? = 0.4, onCompletion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.layer.removeAllAnimations()
            self.alpha = 1.0
            self.isHidden = true
            //if !self.isHidden {
            //    UIView.animate(withDuration: duration!, animations: { self.alpha = 0 }, completion: { (value: Bool) in
              //      self.isHidden = true
                //    if let complete = onCompletion { complete() }
                //})
         //   }
        }
    }
}
extension UIButton {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.setBackgroundImage(image, for: .normal)
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
    func makeRounded() {
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
}
extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFill) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFill) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
    func makeRounded() {
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
}
extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
extension UIApplication {
    
    var keyWindow: UIWindow? {
        // Get connected scenes
        return UIApplication.shared.connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
}

enum MethodOfLocation: Int {
    case current
    case willisTower
    case custom
}

extension MethodOfLocation {
    var userDescription: String {
        switch self {
        case .current:
            return " Current"
        case .willisTower:
            return " Default"
        case .custom:
            return " Custom"
        }
    }
}




struct LocalData {
    static var CurrentLocationMethodInfo: [CurrentLocationInfo] {
        get {
            guard let data = UserDefaults.standard.data(forKey: #function) else { return [] }
            do {
                let myDict = try JSONDecoder().decode([CurrentLocationInfo].self, from: data)
                return myDict
            } catch {
                print(error)
            }
            return []
        }
        set{
            let data = try! JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: #function)
            UserDefaults.standard.synchronize()
        }
        
    }
}


struct CurrentLocationInfo: Codable {
    var latitude: Double?
    var longitude: Double?
    var currentLocationMethod: Int?
}
class locationBarButtonItem: UIBarButtonItem {
    var button: UIButton!
    @objc convenience init(image :UIImage, title :String, target: Any?, action: Selector?) {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        //button.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        button.sizeToFit()
        if let target = target, let action = action {
            button.addTarget(target, action: action, for: .touchUpInside)
        }
        button.setTitleColor(.link, for: .normal)
        self.init(customView: button)
        self.button = button
    }
}
/*
extension UIBarButtonItem {
    
    convenience init(image :UIImage, title :String, target: Any?, action: Selector?) {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        //button.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        button.sizeToFit()
        if let target = target, let action = action {
            button.addTarget(target, action: action, for: .touchUpInside)
        }

        self.init(customView: button)
    }
}

 */
extension AuthErrorCode.Code{
    /// A user displayable description of the error
    var description: String {
        switch self {
        case .accountExistsWithDifferentCredential:
            return "\(self)"
        case .invalidCustomToken:
            return "\(self)"
        case .customTokenMismatch:
            return "\(self)"
        case .invalidCredential:
            return "Invalid credentials try logging in again"
        case .userDisabled:
            return "Your account has been disabled please contact support"
        case .operationNotAllowed:
            return "\(self)"
        case .emailAlreadyInUse:
            return "Email is in use please try logging in"
        case .invalidEmail:
            return "Enter valid email"
        case .wrongPassword:
            return "Incorrect password"
        case .tooManyRequests:
            return "Too many request please try again later"
        case .userNotFound:
            return "User not found please try creating an account"
        case .requiresRecentLogin:
            return "\(self)"
        case .providerAlreadyLinked:
            return "\(self)"
        case .noSuchProvider:
            return "\(self)"
        case .invalidUserToken:
            return "\(self)"
        case .networkError:
            return "No internet connection"
        case .userTokenExpired:
            return "\(self)"
        case .invalidAPIKey:
            return "\(self)"
        case .userMismatch:
            return "\(self)"
        case .credentialAlreadyInUse:
            return "\(self)"
        case .weakPassword:
            return "password is too weak"
        case .appNotAuthorized:
            return "\(self)"
        case .expiredActionCode:
            return "\(self)"
        case .invalidActionCode:
            return "\(self)"
        case .invalidMessagePayload:
            return "\(self)"
        case .invalidSender:
            return "\(self)"
        case .invalidRecipientEmail:
            return "\(self)"
        case .missingEmail:
            return "No email provided"
        case .missingIosBundleID:
            return "\(self)"
        case .missingAndroidPackageName:
            return "\(self)"
        case .unauthorizedDomain:
            return "\(self)"
        case .invalidContinueURI:
            return "\(self)"
        case .missingContinueURI:
            return "\(self)"
        case .missingPhoneNumber:
            return "\(self)"
        case .invalidPhoneNumber:
            return "\(self)"
        case .missingVerificationCode:
            return "\(self)"
        case .invalidVerificationCode:
            return "\(self)"
        case .missingVerificationID:
            return "\(self)"
        case .invalidVerificationID:
            return "\(self)"
        case .missingAppCredential:
            return "\(self)"
        case .invalidAppCredential:
            return "\(self)"
        case .sessionExpired:
            return "\(self)"
        case .quotaExceeded:
            return "\(self)"
        case .missingAppToken:
            return "\(self)"
        case .notificationNotForwarded:
            return "\(self)"
        case .appNotVerified:
            return "\(self)"
        case .captchaCheckFailed:
            return "\(self)"
        case .webContextAlreadyPresented:
            return "\(self)"
        case .webContextCancelled:
            return "\(self)"
        case .appVerificationUserInteractionFailure:
            return "\(self)"
        case .invalidClientID:
            return "\(self)"
        case .webNetworkRequestFailed:
            return "\(self)"
        case .webInternalError:
            return "\(self)"
        case .webSignInUserInteractionFailure:
            return "\(self)"
        case .localPlayerNotAuthenticated:
            return "\(self)"
        case .nullUser:
            return "\(self)"
        case .dynamicLinkNotActivated:
            return "\(self)"
        case .invalidProviderID:
            return "\(self)"
        case .tenantIDMismatch:
            return "\(self)"
        case .unsupportedTenantOperation:
            return "\(self)"
        case .invalidDynamicLinkDomain:
            return "\(self)"
        case .rejectedCredential:
            return "\(self)"
        case .gameKitNotLinked:
            return "\(self)"
        case .secondFactorRequired:
            return "\(self)"
        case .missingMultiFactorSession:
            return "\(self)"
        case .missingMultiFactorInfo:
            return "\(self)"
        case .invalidMultiFactorSession:
            return "\(self)"
        case .multiFactorInfoNotFound:
            return "\(self)"
        case .adminRestrictedOperation:
            return "\(self)"
        case .unverifiedEmail:
            return "\(self)"
        case .secondFactorAlreadyEnrolled:
            return "\(self)"
        case .maximumSecondFactorCountExceeded:
            return "\(self)"
        case .unsupportedFirstFactor:
            return "\(self)"
        case .emailChangeNeedsVerification:
            return "\(self)"
        case .missingOrInvalidNonce:
            return "\(self)"
        case .missingClientIdentifier:
            return "\(self)"
        case .keychainError:
            return "\(self)"
        case .internalError:
            return "Internal error please try again later"
        case .malformedJWT:
            return "\(self)"
        @unknown default:
            return "Error"
        }
    }
}




