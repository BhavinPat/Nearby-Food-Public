//
//  SettingsViewController.swift
//  Nearby Food
//
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/2/21.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseEmailAuthUI
import FirebaseOAuthUI
import GoogleSignIn
import OSLog

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var versionNumber: UILabel!
    @IBOutlet weak var buildNumber: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var uidButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var leaveARating: UIButton!
    @IBOutlet weak var nearbyFoodWebsiteButton: UIButton!
    @IBOutlet weak var helpWebsiteButton: UIButton!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var mapLocationSegmented: UISegmentedControl!
    @IBOutlet weak var providerApple: UIImageView!
    @IBOutlet weak var providerEmail: UIImageView!
    @IBOutlet weak var providerGoogle: UIImageView!
    @IBOutlet weak var bhavinImage: UIImageView!
    @IBOutlet weak var deleteAccountButton: UIButton!
    @IBOutlet weak var editInfoButton: UIButton!
    @IBOutlet weak var movingSwitch: UISwitch!
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    let defaults = UserDefaults.standard
    var UIDDelete = ""
    var currentuser: User!
    var whatLoggedIn1: [whatloggedIn] = []
    var userIsDeletingAccount = false
    var isThereAUser = false
    fileprivate(set) var customAuthUIDelegate: FUIAuthDelegate = FUICustomAuthDelegate()
    @IBAction func recieveNotificationCloseToTryMeAction(_ sender: UISwitch!) {
        //defaults.set(recieveNotificationCloseToTryMe.isOn, forKey: "recieveNotificationCloseToTryMe")
    }
    @IBAction func deleteAccountButtonAction(_ sender: UIButton!) {
        let deleteAccountAlert = UIAlertController(title: "Delete Account", message: "Deleting your account will delete all data. Are you sure you want to do this?", preferredStyle: .alert)
        let delete = UIAlertAction(title: "Yes, Delete", style: .destructive, handler: { [self]
            _ in
            UIDDelete = currentuser.uid
            deleteAccount()
            userIsDeletingAccount = true
        })
        let no = UIAlertAction(title: "No", style: .cancel, handler: nil)
        deleteAccountAlert.addAction(delete)
        deleteAccountAlert.addAction(no)
        present(deleteAccountAlert, animated: true, completion: nil)
    }
    @IBAction func editInfoButtonAction(_ sender: UIButton!) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "editProfileViewController") as! EditProfileViewController
        nextViewController.modalPresentationStyle = .fullScreen
        self.present(nextViewController, animated:true, completion:nil)
    }
    @IBAction func uidButtonAct(_ sender: UIButton!) {
        if isThereAUser {
            let uidAlert = UIAlertController(title: "\(currentuser.uid)", message: "This is your UID. If there is ever a problem with your account please provide me with this value to help me find your account", preferredStyle: .alert)
            let copyuid = UIAlertAction(title: "Copy", style: .default, handler: {_ in
                UIPasteboard.general.string = self.currentuser.uid
            })
            uidAlert.addAction(copyuid)
            self.present(uidAlert, animated: true, completion: nil)
        }
    }
    @IBAction func signOutButtonAct(_ sender: UIButton!) {
        if isThereAUser {
            let signOutAlert = UIAlertController(title: "Log Out", message: "If you logout all your data will still be linked to your account.", preferredStyle: .alert)
            let signOutAction = UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                self.signOut()
                signOutAlert.dismiss(animated: true, completion: nil)
                //show loading view
                
            })
            let ok = UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
                signOutAlert.dismiss(animated: true, completion: nil)
            })
            signOutAlert.addAction(signOutAction)
            signOutAlert.addAction(ok)
            self.present(signOutAlert, animated: true, completion: nil)
        }  else {
            self.showLoginVC()
        }
    }
    
    func showLoginVC() {
        if !userIsDeletingAccount {
            let authUI = FUIAuth.defaultAuthUI()!
            let googleAuthProvider = FUIGoogleAuth(authUI: authUI)
            let appleProvider = FUIOAuth.appleAuthProvider()
            let authProviders: [FUIAuthProvider] = [googleAuthProvider,FUIEmailAuth(), appleProvider]
            authUI.delegate = customAuthUIDelegate
            authUI.privacyPolicyURL = URL(string: "https://www.google.com")
            authUI.tosurl = URL(string: "https://www.google.com")
            authUI.providers = authProviders
            authUI.privacyPolicyURL = URL(string: "")
            let authViewController = authUI.authViewController()
            authViewController.modalPresentationStyle = .overFullScreen
            self.present(authViewController, animated: true, completion: nil)
        } else {
            prepareToDelete()
        }
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            Logger().error("Error signing out: \(signOutError)")
        }
        isThereAUser = false
        currentuser = nil
        showLoginVC()
    }
    @IBAction func leaveARatingButtonAct(_ sender: UIButton!) {
        guard let writeReviewURL = URL(string: "https://www.google.com")
        else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
    @IBAction func nearbyFoodWebsiteButtonAct(_ sender: UIButton!) {
        guard let url = URL(string: "https://www.google.com") else { return }
        UIApplication.shared.open(url)
    }
    @IBAction func helpWebsiteButtonAcr(_ sender: UIButton!) {
        guard let url = URL(string: "https://www.google.com") else { return }
        UIApplication.shared.open(url)
    }
    @IBAction func mapLocationSegmentedAct(_ sender: UISegmentedControl!) {
        switch mapLocationSegmented.selectedSegmentIndex {
        case 0:
            defaults.set(false, forKey: "userCurrentLocation")
        case 1:
            defaults.set(true, forKey: "userCurrentLocation")
        default:
            break
        }
        
    }
    @IBAction func movingSwitchAction(_ sender: UISwitch) {
        defaults.set(movingSwitch.isOn, forKey: "updateBusinessesWhenMoving")
        movingSwitch.isOn = defaults.bool(forKey: "updateBusinessesWhenMoving")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ref = Database.database().reference()
        ref.keepSynced(true)
        handle = Auth.auth().addStateDidChangeListener { [self] (auth, user) in
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
                                Logger().error("Error signing out: \(signOutError)")
                            }
                        }
                        let didCheckEmail = UIAlertController(title: "Confirm Verfication", message: "You need to confirm your email address before you can continue. If you have done so press \"Reload\", if you would like to recieve another email press \"Resend\", if you would like to log out press \"Log Out\"", preferredStyle: .alert)
                        let logOut = UIAlertAction(title: "Log Out", style: .destructive, handler: {
                            _ in
                            let firebaseAuth = Auth.auth()
                            do {
                                try firebaseAuth.signOut()
                            } catch let signOutError as NSError {
                                Logger().error("Error signing out: \(signOutError)")
                            }
                        })
                        let reload = UIAlertAction(title: "Reload", style: .default, handler: {
                            _ in
                            let firebaseAuth = Auth.auth()
                            do {
                                try firebaseAuth.signOut()
                            } catch let signOutError as NSError {
                                Logger().error("Error signing out: \(signOutError)")
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
                                    Logger().error("Error signing out: \(error.localizedDescription)")
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
                    self.setUpView()
                }
            } else {
                if !self.userIsDeletingAccount {
                    //self.showLoginVC()
                    setUpView()
                }
            }
        }
        let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        let navigationItem = UINavigationItem()
        navigationItem.title = "Settings"
        navigationItem.leftItemsSupplementBackButton = true
        navigationBar.items = [navigationItem]
        self.view.addSubview(navigationBar)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
        handle = nil
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(userIsDeletingAccountNotif(_:)), name: NSNotification.Name(rawValue: "UserIsDeletingAccountNotfication"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 100
        }
        return 40
    }
    deinit {
        Logger().info("SettingdTableVC did deinit")
    }
    func setUpView() {
        bhavinImage.image = UIImage(named: "bhavinImage")
        bhavinImage.makeRounded()
        //recieveNotificationCloseToTryMe.setOn(defaults.bool(forKey: "recieveNotificationCloseToTryMe"), animated: false)
        if Auth.auth().currentUser != nil {
            currentuser = Auth.auth().currentUser
            isThereAUser = true
        } else {
            isThereAUser = false
        }
        DispatchQueue.main.async { [self] in
            if isThereAUser {
                userEmail.text = currentuser.email
                signOutButton.setTitleColor(.red, for: .normal)
                signOutButton.setTitle("Log Out", for: .normal)
                uidButton.isHidden = false
                providerApple.isHidden = true
                providerEmail.isHidden = true
                providerGoogle.isHidden = true
                userImage.image = UIImage(systemName: "person.circle.fill")
                userName.text = "No Name"
                userName.text = currentuser.displayName
                movingSwitch.isOn = defaults.bool(forKey: "updateBusinessesWhenMoving")
                if let googleImageURl = URL(string: "https://raw.githubusercontent.com/google/GoogleSignIn-iOS/main/GoogleSignIn/Sources/Resources/google%403x.png") {
                    providerGoogle.downloaded(from: googleImageURl)
                }
                if #available(iOS 16.0, *) {
                    providerApple.image = UIImage(systemName: "apple.logo")
                } else {
                    providerApple.image = UIImage(systemName: "applelogo")
                }
                for provider in currentuser.providerData {
                    if let name = provider.displayName  {
                        if userName.text == nil || userName.text == "" {
                            userName.text = name
                        }
                    }
                    if userEmail.text == "" || userEmail.text == nil{
                        userEmail.text = provider.email
                    }
                    if let photoURl = provider.photoURL  {
                        userImage.downloaded(from: photoURl)
                    }
                    if provider.providerID == "apple.com" {
                        providerApple.isHidden = false
                        whatLoggedIn1.append(.Apple)
                    } else if provider.providerID == "google.com" {
                        providerGoogle.isHidden = false
                        whatLoggedIn1.append(.Google)
                    } else if provider.providerID == "password" {
                        whatLoggedIn1.append(.Email)
                        providerEmail.isHidden = false
                    }
                }
                if currentuser.providerData.count == 1 && currentuser.providerData[0].providerID == "password" {
                    editInfoButton.isHidden = false
                } else {
                    editInfoButton.isHidden = true
                }
                deleteAccountButton.isEnabled = true
            } else {
                providerApple.isHidden = true
                providerEmail.isHidden = true
                providerGoogle.isHidden = true
                deleteAccountButton.isEnabled = false
                userName.text = "Not Logged in"
                userEmail.text = ""
                signOutButton.setTitleColor(.blue, for: .normal)
                signOutButton.setTitle("Login", for: .normal)
                uidButton.isHidden = true
                userImage.image = UIImage(systemName: "person.circle.fill")
                editInfoButton.isHidden = true
            }
            let useCurrentLocation = defaults.bool(forKey: "userCurrentLocation")
            if useCurrentLocation {
                mapLocationSegmented.selectedSegmentIndex = 1
            } else {
                mapLocationSegmented.selectedSegmentIndex = 0
            }
            versionNumber.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            buildNumber.text = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        }
    }
    @objc func userIsDeletingAccountNotif(_ sender: NSNotification) {
            Logger().info("Successfully signed in")
            setUpView()
            if userIsDeletingAccount {
                if whatLoggedIn1.contains(.Apple) || whatLoggedIn1.contains(.Google) {
                    let user = sender.userInfo!["user"] as! AuthDataResult
                    continueUserDelete(user: user)
                }
            }
    }
    func askForPassoword() {
        let alertController = UIAlertController(title: "Enter Account Password", message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            self.emailDelete(password: textField.text ?? "")
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    func emailDelete(password: String) {
        var credential: AuthCredential!
        let currentUserUID = UIDDelete
        credential = EmailAuthProvider.credential(withEmail: currentuser.email ?? "", password: password)
        currentuser.reauthenticate(with: credential, completion: {
            authResults, error in
            self.userIsDeletingAccount = false
            if let error = error {
                self.setUpView()
                Logger().error("\(error.localizedDescription)")
                let failedDelete = UIAlertController(title: "Error", message: "There was an error deleting your account please try again. Or visit the support page to get help", preferredStyle: .alert)
                let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                let supportPage = UIAlertAction(title: "Support Page", style: .default, handler: {
                    _ in
                    guard let url = URL(string: "https://www.google.com") else { return }
                    UIApplication.shared.open(url)
                    failedDelete.dismiss(animated: true, completion: nil)
                })
                failedDelete.addAction(supportPage)
                failedDelete.addAction(OK)
                self.present(failedDelete, animated: true, completion: nil)
            } else {
                let userRef = self.ref.child("users/" + (currentUserUID))
                userRef.removeValue()
                userRef.setValue(nil)
                authResults?.user.delete(completion: {
                    error in
                    self.setUpView()
                    if let error = error {
                        Logger().error("\(error.localizedDescription)")
                        let failedDelete = UIAlertController(title: "Error", message: "There was an error deleting your account please try again. Or visit the support page to get help", preferredStyle: .alert)
                        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        let supportPage = UIAlertAction(title: "Support Page", style: .default, handler: {
                            _ in
                            guard let url = URL(string: "https://www.google.com") else { return }
                            UIApplication.shared.open(url)
                            failedDelete.dismiss(animated: true, completion: nil)
                        })
                        failedDelete.addAction(supportPage)
                        failedDelete.addAction(OK)
                        self.present(failedDelete, animated: true, completion: nil)
                    } else {
                        self.setUpView()
                        let accountDeleted = UIAlertController(title: "Account Deleted", message: "Your account has been successfully deleted. You will now go to the log in screen", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: {
                            _ in
                            self.setUpView()
                            self.showLoginVC()
                        })
                        accountDeleted.addAction(ok)
                        self.present(accountDeleted, animated: true, completion: nil)
                    }
                })
            }
        })
    }
    /*
    func googleDelete() {
        var credential: AuthCredential!
        let currentUserUID = UIDDelete
        let accessToken = GIDSignIn.sharedInstance.currentUser?.authentication.accessToken
        let idToken = GIDSignIn.sharedInstance.currentUser?.authentication.idToken
        credential = GoogleAuthProvider.credential(withIDToken: idToken ?? "", accessToken: accessToken ?? "")
        setUpView()
        
        currentuser.reauthenticate(with: credential, completion: {
            authResults, error in
            self.userIsDeletingAccount = false
            if let error = error {
                self.setUpView()
                print(error.localizedDescription)
                let failedDelete = UIAlertController(title: "Error", message: "There was an error deleting your account please try again. Or visit the support page to get help", preferredStyle: .alert)
                let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                let supportPage = UIAlertAction(title: "Support Page", style: .default, handler: {
                    _ in
                    guard let url = URL(string: "https://google.com") else { return }
                    UIApplication.shared.open(url)
                    failedDelete.dismiss(animated: true, completion: nil)
                })
                failedDelete.addAction(supportPage)
                failedDelete.addAction(OK)
                self.present(failedDelete, animated: true, completion: nil)
            } else {
                authResults?.user.delete(completion: {
                    error in
                    self.setUpView()
                    if let error = error {
                        print(error.localizedDescription)
                        let failedDelete = UIAlertController(title: "Error", message: "There was an error deleting your account please try again. Or visit the support page to get help", preferredStyle: .alert)
                        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        let supportPage = UIAlertAction(title: "Support Page", style: .default, handler: {
                            _ in
                            guard let url = URL(string: "https://google.com") else { return }
                            UIApplication.shared.open(url)
                            failedDelete.dismiss(animated: true, completion: nil)
                        })
                        failedDelete.addAction(supportPage)
                        failedDelete.addAction(OK)
                        self.present(failedDelete, animated: true, completion: nil)
                    } else {
                        self.setUpView()
                        let accountDeleted = UIAlertController(title: "Account Deleted", message: "Your account has been successfully deleted. To verfiy this go to your Google or Apple account and verify Nearby Food is no longer connected", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: {
                            _ in
                            self.setUpView()
                            self.showLoginVC()
                            let userRef = self.ref.child("users/" + (currentUserUID))
                            userRef.removeValue()
                            userRef.setValue(nil)
                        })
                        accountDeleted.addAction(ok)
                        self.present(accountDeleted, animated: true, completion: nil)
                    }
                })
            }
        })
    }
    */
    func deleteAccount() {
        prepareToDelete()
    }
    func googleDelete() {
        let authUI = FUIAuth.defaultAuthUI()!
        let googleAuthProvider = FUIGoogleAuth(authUI: authUI)
        let authProviders: [FUIAuthProvider] = [googleAuthProvider]
        authUI.delegate = customAuthUIDelegate
        authUI.privacyPolicyURL = URL(string: "https://www.google.com")
        authUI.tosurl = URL(string: "https://www.google.com")
        authUI.providers = authProviders
        let authViewController = authUI.authViewController()
        authViewController.modalPresentationStyle = .overFullScreen
        self.present(authViewController, animated: true, completion: nil)
    }
    func appleDelete() {
        let authUI = FUIAuth.defaultAuthUI()!
        let appleProvider = FUIOAuth.appleAuthProvider()
        let authProviders: [FUIAuthProvider] = [appleProvider]
        authUI.delegate = customAuthUIDelegate
        authUI.privacyPolicyURL = URL(string: "https://www.google.com")
        authUI.tosurl = URL(string: "https://www.google.com")
        authUI.providers = authProviders
        let authViewController = authUI.authViewController()
        authViewController.modalPresentationStyle = .overFullScreen
        self.present(authViewController, animated: true, completion: nil)
    }
    func continueUserDelete(user: AuthDataResult) {
        let currentUserUID = user.user.uid
        let userRef = self.ref.child("users/" + (currentUserUID))
        userRef.removeValue()
        userRef.setValue(nil)
        user.user.delete(completion: {
            error in
            self.setUpView()
            if let error = error {
                self.userIsDeletingAccount = false
                Logger().error("\(error.localizedDescription)")
                let failedDelete = UIAlertController(title: "Error", message: "There was an error deleting your account please try again. Or visit the support page to get help", preferredStyle: .alert)
                let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                let supportPage = UIAlertAction(title: "Support Page", style: .default, handler: {
                    _ in
                    guard let url = URL(string: "https://www.google.com") else { return }
                    UIApplication.shared.open(url)
                    failedDelete.dismiss(animated: true, completion: nil)
                })
                failedDelete.addAction(supportPage)
                failedDelete.addAction(OK)
                self.present(failedDelete, animated: true, completion: nil)
            } else {
                self.setUpView()
                let accountDeleted = UIAlertController(title: "Account Deleted", message: "Your account has been successfully deleted. To verfiy this go to your Google or Apple account and verify Nearby Food is no longer connected", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { [self]
                    _ in
                    self.userIsDeletingAccount = false
                    self.setUpView()
                    //if the user deletes an account. Do i show sign in or not? 
                    //self.showLoginVC()
                    self.whatLoggedIn1.removeAll()
                })
                accountDeleted.addAction(ok)
                self.present(accountDeleted, animated: true, completion: nil)
            }
        })
    }
    func prepareToDelete() {
        if whatLoggedIn1.contains(.Email) {
            askForPassoword()
        } else if whatLoggedIn1.contains(.Google) {
            googleDelete()
        } else if whatLoggedIn1.contains(.Apple) {
            appleDelete()
        } else {
            fatalError("can't delete no account signed in")
        }
    }
    /*
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        Logger().info("Successfully signed in")
        setUpView()
        if userIsDeletingAccount {
            if whatLoggedIn1.contains(.Apple) || whatLoggedIn1.contains(.Google) {
                continueUserDelete(user: authDataResult!)
            }
        }
    }
     */
}
