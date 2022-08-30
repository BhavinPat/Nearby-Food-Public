//
//  MainTabViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/2/21.
//

import UIKit
import SwiftUI
import OSLog
import MapKit
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseEmailAuthUI
import FirebaseOAuthUI

class MainTabViewController: UITabBarController, UITabBarControllerDelegate {
    
    var locationSelectorButton: locationBarButtonItem!
    var locationManager: CLLocationManager!
    @IBOutlet var settingsSelectorButton: UIBarButtonItem!
    @IBAction func settingsButtonAction(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "settings") as! SettingsTableViewController
        self.present(vc, animated: true, completion: nil)
         //SwiftUI is not a feasable feature for this app. It's simplily too big. All apps I create in the future will be SwiftUI. 
        /*
        let swiftUIController = UIHostingController(rootView: SettingsView())
        self.present(swiftUIController, animated: true)
         */
    }
    @objc func moveLocationAction() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "locationSelectorVC") as! LocationSelectorViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.navigationItem.title = "Home"
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(goToLogInCreateAccountView), name: NSNotification.Name(rawValue: "presentLogInCreateVC"), object: nil)
        // Do any additional setup after loading the view.
    }
    fileprivate(set) var customAuthUIDelegate: FUIAuthDelegate = FUICustomAuthDelegate()
    @objc func goToLogInCreateAccountView() {
        let authUI = FUIAuth.defaultAuthUI()!
        authUI.delegate = customAuthUIDelegate
        authUI.privacyPolicyURL = URL(string: "https://www.google.com")
        authUI.tosurl = URL(string: "https://www.google.com")
        let googleAuthProvider = FUIGoogleAuth(authUI: authUI)
        let appleProvider = FUIOAuth.appleAuthProvider()
        let authProviders: [FUIAuthProvider] = [googleAuthProvider,FUIEmailAuth(), appleProvider]
        authUI.providers = authProviders
        let authViewController = authUI.authViewController()
        authViewController.modalPresentationStyle = .overFullScreen
        self.present(authViewController, animated: true)
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        /*
         if item.tag:
         0: Home
         1: Nearby
         2. Map
         3. Favorites
        */
        let method = MethodOfLocation(rawValue: LocalData.CurrentLocationMethodInfo.first!.currentLocationMethod!)
        locationSelectorButton.title = method?.userDescription
        if item.title == "Map" {
            navigationController?.viewControllers.first?.navigationItem.title = nil
            navigationController?.viewControllers.first?.navigationItem.titleView?.isHidden = false
            navigationController?.viewControllers.first?.navigationItem.rightBarButtonItems = []
        } else if item.title == "Nearby" || item.title == "Home"  {
            navigationController?.viewControllers.first?.navigationItem.rightBarButtonItems = [locationSelectorButton]
        }
    }
    @objc func updateLocationUsedTitle() {
        let method = MethodOfLocation(rawValue: LocalData.CurrentLocationMethodInfo.first!.currentLocationMethod!)
        
        locationSelectorButton.button.setTitle(method?.userDescription ?? "", for: .normal)
    }
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let nameOfVC = viewController.title ?? "no title"
        /*
         if viewController.title:
         0: Home
         1: Nearby
         2. Map
         3. Favorites
        */
        if nameOfVC == "Home" {
            
        } else if nameOfVC == "Nearby" {
            
        } else if nameOfVC == "Map" {
            
        } else if nameOfVC == "Favorites" {
            
        } else if nameOfVC == "no title" {
            
        }
    }
    deinit {
        Logger().info("mainTabBar viewController deinit")
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
extension MainTabViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            if LocalData.CurrentLocationMethodInfo.isEmpty {
                let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: 0, longitude: 0, currentLocationMethod: 0)]
                LocalData.CurrentLocationMethodInfo = dict
            }
        } else {
            if LocalData.CurrentLocationMethodInfo.isEmpty {
                let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: Defualts.locationDefaults.latitude, longitude: Defualts.locationDefaults.longitude, currentLocationMethod: 1)]
                LocalData.CurrentLocationMethodInfo = dict
            }
        }
        if manager.location?.coordinate.latitude == nil && LocalData.CurrentLocationMethodInfo.first!.currentLocationMethod != 2 {
            let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: Defualts.locationDefaults.latitude, longitude: Defualts.locationDefaults.longitude, currentLocationMethod: 1)]
            LocalData.CurrentLocationMethodInfo = dict
        }
        
        let method = MethodOfLocation(rawValue: LocalData.CurrentLocationMethodInfo.first!.currentLocationMethod!)
        //locationSelectorButton.title = method?.userDescription
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocationUsedTitle), name: NSNotification.Name(rawValue: "updateLocationUsedTitle"), object: nil)
        let image = UIImage(systemName: "mappin.circle.fill")!
        locationSelectorButton = locationBarButtonItem(image: image, title: method?.userDescription ?? "", target: self, action: #selector(moveLocationAction))
        navigationController?.viewControllers.first?.navigationItem.rightBarButtonItems = [locationSelectorButton]
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
}
