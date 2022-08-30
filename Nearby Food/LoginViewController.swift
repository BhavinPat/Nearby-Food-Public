//
//  LoginViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 12/31/21.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseEmailAuthUI
import FirebaseOAuthUI
import OSLog

class LoginViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?
    let defaults = UserDefaults.standard
    var ref: DatabaseReference!
    var didShowSignInScreen = false
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let handle = handle else { return }
        Auth.auth().removeStateDidChangeListener(handle)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if defaults.bool(forKey: "didDoTutorial") {
            launchLogin()
        } 
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(launchLogin), name: NSNotification.Name("launchLogin"), object: nil)
        // Do any additional setup after loading the view.
    }
    @IBAction func continuePressed(_ sender: UIButton!) {
        if !defaults.bool(forKey: "didDoTutorial") {
            self.dismiss(animated: true, completion: nil)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "tutorialViewController") as! CarouselViewController
            initialViewController.modalPresentationStyle = .fullScreen
            self.present(initialViewController, animated: true, completion: nil)
        } else if didShowSignInScreen {
            didShowSignInScreen = false
            self.dismiss(animated: true, completion: nil)
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "initialNavViewController") as! InitialNavViewController
            nextViewController.modalPresentationStyle = .fullScreen
            self.present(nextViewController, animated:true, completion:nil)
        } else {
            launchLogin()
        }
    }
    fileprivate(set) var customAuthUIDelegate: FUIAuthDelegate = FUICustomAuthDelegate()
    func showLoginVC() {
        didShowSignInScreen = true
        let authUI = FUIAuth.defaultAuthUI()!
        authUI.delegate = customAuthUIDelegate
        authUI.privacyPolicyURL = URL(string: "https://www.google.com")
        authUI.tosurl = URL(string: "https://www.google.com")
        let googleAuthProvider = FUIGoogleAuth(authUI: authUI)
        let appleProvider = FUIOAuth.appleAuthProvider()
        let authProviders: [FUIAuthProvider] = [googleAuthProvider,FUIEmailAuth(), appleProvider]
        authUI.providers = authProviders
        let authViewController = authUI.authViewController()
        authViewController.modalPresentationStyle = .overCurrentContext
        self.present(authViewController, animated: true, completion: nil)
    }
    @objc func launchLogin() {
        ref = Database.database().reference()
        ref.keepSynced(true)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                if !user.isEmailVerified {
                    user.sendEmailVerification(completion: {
                        error in
                        if let error = error {
                            Logger().error("\(error.localizedDescription)")
                            let firebaseAuth = Auth.auth()
                            do {
                                try firebaseAuth.signOut()
                            } catch let signOutError as NSError {
                                Logger().error("\(signOutError.localizedDescription)")
                            }
                        }
                        let didCheckEmail = UIAlertController(title: "Confirm Verfication", message: "You need to confirm your email address before you can continue. If you have done so press \"Reload\", if you would like to recieve another email press \"Resend\", if you would like to log out press \"Log Out\"", preferredStyle: .alert)
                        let logOut = UIAlertAction(title: "Log Out", style: .destructive, handler: {
                            _ in
                            let firebaseAuth = Auth.auth()
                            do {
                                try firebaseAuth.signOut()
                            } catch let signOutError as NSError {
                                Logger().error("\(signOutError.localizedDescription)")
                            }
                        })
                        let reload = UIAlertAction(title: "Reload", style: .default, handler: {
                            _ in
                            let firebaseAuth = Auth.auth()
                            do {
                                try firebaseAuth.signOut()
                            } catch let signOutError as NSError {
                                Logger().error("\(signOutError.localizedDescription)")
                            }
                            /*
                            let newUser = Auth.auth().currentUser!
                            if newUser.isEmailVerified {
                                didCheckEmail.dismiss(animated: true, completion: nil)
                                didCheckEmail.dismiss(animated: true, completion: nil)
                                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "initialNavViewController") as! InitialNavViewController
                                nextViewController.modalPresentationStyle = .fullScreen
                                self.present(nextViewController, animated:true, completion:nil)
                            } else {
                                self.present(didCheckEmail, animated: true, completion: nil)
                            }
                            */
                        })
                        let resend = UIAlertAction(title: "Resend", style: .default, handler: {
                            _ in
                            Auth.auth().currentUser!.sendEmailVerification(completion: {
                                error in
                                if let error = error {
                                    Logger().error("\(error.localizedDescription)")
                                }
                            })
                            didCheckEmail.dismiss(animated: true, completion: nil)
                            self.present(didCheckEmail, animated: true, completion: nil)
                        })
                        didCheckEmail.addAction(reload)
                        didCheckEmail.addAction(resend)
                        didCheckEmail.addAction(logOut)
                        self.present(didCheckEmail, animated: true, completion: nil)
                    })
                } else {
                    self.dismiss(animated: true, completion: nil)
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "initialNavViewController") as! InitialNavViewController
                    nextViewController.modalPresentationStyle = .fullScreen
                    self.present(nextViewController, animated:true, completion:nil)
                }
            } else {
                self.showLoginVC()
            }
        }
    }
    @objc func logoutButtonPressed() {
        let firebaseAuth = Auth.auth()
        
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            Logger().error("\(signOutError.localizedDescription)")
        }
    }
    func displayError(error: NSError) {
        let e = AuthErrorCode(_nsError: error)
        let code = e.code
        let errorAlert = UIAlertController(title: "Error", message: code.description, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: {
            _ in
            errorAlert.dismiss(animated: true)
        })
        errorAlert.addAction(ok)
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: {
            _ in
            self.present(errorAlert, animated: true)
        })
    }
}
extension FUIAuthBaseViewController{
    open override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.leftBarButtonItem = nil
    }
}



