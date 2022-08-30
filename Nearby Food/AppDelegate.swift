//
//  AppDelegate.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/1/21.
//

import UIKit
import Firebase
import FirebaseAnalyticsWithoutAdIdSupportTarget
import FirebaseAuthUI
import AppTrackingTransparency
import AdSupport
import OSLog
import CoreLocation
//import GoogleSignIn
@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let providerFactory = NearbyFoodAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().token { token, error in
            if let error = error {
                Logger().error("Error fetching FCM registration token: \(error.localizedDescription)")
            } else if let token = token {
                Logger().info("FCM registration token: \(token)")            }
        }
        Database.database().isPersistenceEnabled = true
        Auth.auth().currentUser?.reload(completion: {
            error in
            if error != nil {
                let firebaseAuth = Auth.auth()
                do {
                    try firebaseAuth.signOut()
                } catch let signOutError as NSError {
                    Logger().error("Error signing out: \(signOutError)")
                }
            }
            Logger().info("reload successful")
        })
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        UIApplication.shared.applicationIconBadgeNumber = 0
        SettingsBundleHelper.setVersionAndBuildNumber()
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        /*
         let defaults = UserDefaults.standard
         if defaults.bool(forKey: "didDoTutorial") {
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
         let initialViewController = storyboard.instantiateViewController(withIdentifier: "logInVC") as! LoginViewController
         initialViewController.modalPresentationStyle = .fullScreen
         let scenes = UIApplication.shared.connectedScenes
         let windowScene = scenes.first as? UIWindowScene
         let window = windowScene?.windows.first
         if let window = window {
         window.rootViewController = initialViewController
         window.makeKeyAndVisible()
         }
         } else {
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
         let initialViewController = storyboard.instantiateViewController(withIdentifier: "tutorialViewController") as! CarouselViewController
         initialViewController.modalPresentationStyle = .fullScreen
         let scenes = UIApplication.shared.connectedScenes
         let windowScene = scenes.first as? UIWindowScene
         let window = windowScene?.windows.first
         if let window = window {
         window.rootViewController = initialViewController
         window.makeKeyAndVisible()
         }
         }
         */
        
        return true
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    }
    
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let keyWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.filter({$0.isKeyWindow}).first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            // topController should now be your topmost view controller
            
        }
    }
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    //return GIDSignIn.sharedInstance.handle(url)
    //}
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult)
                     -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
        //  print("Message ID: \(messageID)")
        //}
        // Print full message.
        Logger().info("\(userInfo)")
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        // ...
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        Logger().info("\(userInfo)")
        
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // ...
        
        // Print full message.
        Logger().info("\(userInfo)")
        
        // Change this to your preferred presentation option
        completionHandler([[.sound, .badge, .list]])
    }
}

