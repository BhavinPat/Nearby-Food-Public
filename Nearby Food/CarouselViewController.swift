//
//  CarouselViewController.swift
//  Nearby Food
//
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 2/3/22.
//

import UIKit
import OSLog

class CarouselViewController: UIViewController {
    @IBOutlet weak var imageViewContainer: UIView!
    @IBOutlet weak var nextButton: UIButton!
    let defaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(nextUnhind), name: NSNotification.Name("notificationOneFinalPage"), object: nil)
        /*
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
        }
        */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    deinit {
        Logger().info("carouselViewController did deinit")
    }
    @objc func nextUnhind() {
        NotificationCenter.default.removeObserver(self)
        nextButton.isHidden = false
    }
    @IBAction func nextButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        defaults.set(true, forKey: "didDoTutorial")
        defaults.set(true, forKey: "recieveNotificationCloseToTryMe")
        NotificationCenter.default.post(name: NSNotification.Name("launchLogin"), object: self, userInfo: nil)
        //let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //let initialViewController = storyboard.instantiateViewController(withIdentifier: "logInVC") as! LoginViewController
        //initialViewController.modalPresentationStyle = .fullScreen
        //self.present(initialViewController, animated: true, completion: nil)
    }
}

