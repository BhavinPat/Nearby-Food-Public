//
//  TryMeNearbyNotification.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 2/26/22.
//

import UIKit
import CoreLocation
import UserNotifications
import OSLog
class TryMeNearbyNotification: NSObject, ObservableObject {
    var location = CLLocationCoordinate2D()
    let notificationCenter = UNUserNotificationCenter.current()
    // 1
    lazy var locationManager = makeLocationManager()
    // 2
    private func makeLocationManager() -> CLLocationManager {
        // 3
        let manager = CLLocationManager()
        manager.allowsBackgroundLocationUpdates = true
        // 4
        return manager
    }
    
    // 1
    private func makeStoreRegion() -> CLCircularRegion {
        // 2
        let region = CLCircularRegion(
            center: location,
            radius: 2,
            identifier: UUID().uuidString)
        // 3
        region.notifyOnEntry = true
        // 4
        return region
    }
    
    // 1
    func validateLocationAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            locationManager.requestWhenInUseAuthorization()
            requestNotificationAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            
            requestNotificationAuthorization()
            
        default:
            break
        }
    }
    private func requestNotificationAuthorization() {
        let options: UNAuthorizationOptions = [.sound, .alert]
        notificationCenter
            .requestAuthorization(options: options) { [weak self] result, _ in
                if result {
                    self?.registerNotification()
                }
            }
    }
    
    // 1
    private func registerNotification() {
        // 2
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Welcome to Swifty TakeOut"
        notificationContent.body = "Your order will be ready shortly."
        notificationContent.sound = .default
        
        // 3
        
        //let trigger = UNLocationNotificationTrigger(region: storeRegion, repeats: false)
        
        // 4
        
        //let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        
        // 5
        /*
         notificationCenter.add(request) { error in
         if error != nil {
         print("Error: \(String(describing: error))")
         }
         }
         */
    }
    // 1
    override init() {
        super.init()
        // 2
        notificationCenter.delegate = self
    }
}
extension TryMeNearbyNotification: UNUserNotificationCenterDelegate {
    // 1
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 2
        Logger().info("Received Notification")
        //didArriveAtTakeout = true
        // 3
        completionHandler()
    }
    
    // 4
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 5
        Logger().info("Received Notification in Foreground")
        //didArriveAtTakeout = true
        // 6
        completionHandler(.sound)
    }
}
