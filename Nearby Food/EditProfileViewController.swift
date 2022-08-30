//
//  EditProfileViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/24/22.
//

import UIKit
import Firebase
import FirebaseAuth
import CoreMedia
import OSLog

class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var changeEmail: UITextField! // textbox with email in. All need to do is edit textbox. Then confirm with verfication
    @IBOutlet weak var changeName: UITextField! //textbox with current name. Change firebase display name.
    @IBOutlet weak var changePassword: UIButton!
    var hasChangesProcessed1 = 0
    @IBAction func cancel(_ sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func saveChanges(_ sender: UIButton!) {
        if changeEmail.hasText {
            askForPassoword()
        } else {
            hasChangesProcessed1 += 1
            hasChangesProcessed(value: hasChangesProcessed1)
        }
        if changeName.hasText {
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = changeName.text
            changeRequest?.commitChanges(completion: { [self]
                error in
                if let error = error {
                    Logger().error("\(error.localizedDescription)")
                }
                hasChangesProcessed1 += 1
                hasChangesProcessed(value: hasChangesProcessed1)
            })
        } else {
            hasChangesProcessed1 += 1
            hasChangesProcessed(value: hasChangesProcessed1)
        }
    }
    @IBAction func changePasswordAct(_ sender: UIButton!) {
        let alertController = UIAlertController(title: "Change Password", message: "", preferredStyle: .alert)
        alertController.addTextField { currentTextField in
            currentTextField.placeholder = "Enter Current Password"
            currentTextField.isSecureTextEntry = true
            currentTextField.autocorrectionType = .no
            currentTextField.autocapitalizationType = .none
        }
        alertController.addTextField { enterTextField in
            enterTextField.placeholder = "Enter New password"
            enterTextField.isSecureTextEntry = true
            enterTextField.autocorrectionType = .no
            enterTextField.autocapitalizationType = .none
        }
        alertController.addTextField { reenterTextField in
            reenterTextField.placeholder = "Reenter New Password"
            reenterTextField.isSecureTextEntry = true
            reenterTextField.autocorrectionType = .no
            reenterTextField.autocapitalizationType = .none
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let currentTextField = alertController.textFields?[0], let enterNewPassword = alertController.textFields?[1], let reenter = alertController.textFields?[2] else { return }
            if reenter.text == enterNewPassword.text && enterNewPassword.hasText {
                self.changePassword(currentPassword: currentTextField, enterNewPassword: enterNewPassword, reeenterNewPassword: reenter)
            } else {
                alertController.dismiss(animated: true, completion: nil)
                alertController.message = "Passwords did not match"
                self.present(alertController, animated: true, completion: nil)
            }
            
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    func hasChangesProcessed(value: Int) {
        if value == 2 {
            self.dismiss(animated: true, completion: nil)
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
            self.emailUpdate(password: textField.text ?? "")
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    func emailUpdate(password: String) {
        var credential: AuthCredential!
        let email = Auth.auth().currentUser?.email
        credential = EmailAuthProvider.credential(withEmail: email ?? "", password: password)
        Auth.auth().currentUser!.reauthenticate(with: credential, completion: { [self]
            authResults, error in
            if let error = error {
                Logger().error("\(error.localizedDescription)")
                hasChangesProcessed1 += 1
                hasChangesProcessed(value: hasChangesProcessed1)
                return
            }
            /*
            Auth.auth().currentUser?.updateEmail(to: changeEmail.text ?? "", completion: {
                error in
                if let error = error {
                    print("error commiting profile email changes with error: \(error)")
                }
            })
             */
            
            Auth.auth().currentUser?.sendEmailVerification(beforeUpdatingEmail: changeEmail.text ?? "", completion: {
                error in
                if let error = error {
                    Logger().error("\(error.localizedDescription)")
                    self.hasChangesProcessed1 += 1
                    self.hasChangesProcessed(value: self.hasChangesProcessed1)
                } else {
                    let emailsent = UIAlertController(title: "Email Verfication Sent", message: "You have to verify the email address before it updates in your account. You will now be logged out. You can log in with your old email until you verify your new email.", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: {
                        _ in
                        let firebaseAuth = Auth.auth()
                        do {
                            try firebaseAuth.signOut()
                        } catch let signOutError as NSError {
                            Logger().error("\(signOutError)")
                        }
                        self.isUserSignedOutOverUser = true
                        //hasChangesProcessed1 += 1
                        //hasChangesProcessed(value: hasChangesProcessed1)
                    })
                    emailsent.addAction(ok)
                    self.present(emailsent, animated: true, completion: nil)
                }
            })
            
        })
    }
    func changePassword(currentPassword: UITextField, enterNewPassword: UITextField, reeenterNewPassword: UITextField) {
        
        var credential: AuthCredential!
        let email = Auth.auth().currentUser?.email
        credential = EmailAuthProvider.credential(withEmail: email ?? "", password: currentPassword.text ?? "")
        Auth.auth().currentUser!.reauthenticate(with: credential, completion: { [self]
            authResults, error in
            if let error = error {
                Logger().error("\(error.localizedDescription)")
                let passwordChangeFail = UIAlertController(title: "Error Changing Password", message: "There was an error updating your password please try again. Or visit the support page to get help", preferredStyle: .alert)
                let supportPage = UIAlertAction(title: "Support Page", style: .default, handler: {
                    _ in
                    guard let url = URL(string: "https://google.com") else { return }
                    UIApplication.shared.open(url)
                    passwordChangeFail.dismiss(animated: true, completion: nil)
                })
                
                let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                passwordChangeFail.addAction(ok)
                passwordChangeFail.addAction(supportPage)
                present(passwordChangeFail, animated: true, completion: nil)
            } else {
                Auth.auth().currentUser?.updatePassword(to: enterNewPassword.text!, completion: {
                    error in
                    if let error = error {
                        Logger().error("\(error.localizedDescription)")
                        let passwordChangeFail = UIAlertController(title: "Error Changing Password", message: "There was an error updating your password please try again. Or visit the support page to get help", preferredStyle: .alert)
                        let supportPage = UIAlertAction(title: "Support Page", style: .default, handler: {
                            _ in
                            guard let url = URL(string: "https://google.com") else { return }
                            UIApplication.shared.open(url)
                            passwordChangeFail.dismiss(animated: true, completion: nil)
                        })
                        
                        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        passwordChangeFail.addAction(ok)
                        passwordChangeFail.addAction(supportPage)
                        self.present(passwordChangeFail, animated: true, completion: nil)
                    } else {
                        let passwordChangeSuccess = UIAlertController(title: "Password Updated", message: "", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        passwordChangeSuccess.addAction(ok)
                        self.present(passwordChangeSuccess, animated: true, completion: nil)
                        
                    }
                })
            }
        })
    }
    var handle: AuthStateDidChangeListenerHandle?
    var isUserSignedOutOverUser = false
    override func viewDidLoad() {
        super.viewDidLoad()
        changeEmail.delegate = self
        changeName.delegate = self
        setUpView()
        handle = Auth.auth().addStateDidChangeListener { [self] (auth, user) in
            if isUserSignedOutOverUser {
                if user == nil {
                    hasChangesProcessed1 += 1
                    hasChangesProcessed(value: hasChangesProcessed1)
                }
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
        handle = nil
        NotificationCenter.default.removeObserver(self)
    }
    var currentuser: User!
    func setUpView() {
        mainView.layer.masksToBounds = true
        mainView.layer.cornerRadius = 6.5
        if Auth.auth().currentUser != nil {
            currentuser = Auth.auth().currentUser
        } else {
            fatalError("No user logged in and tried to edit profile details")
        }
        DispatchQueue.main.async { [self] in
            changeEmail.placeholder = currentuser.email
            changeName.placeholder = "No Name"
            changeName.placeholder = currentuser.displayName
        }
        for provider in currentuser.providerData {
            if let name = provider.displayName  {
                if changeName.placeholder == nil || changeName.placeholder == "" {
                    changeName.placeholder = name
                }
            }
            if changeEmail.placeholder == "" || changeEmail.placeholder == nil{
                changeEmail.placeholder = provider.email
            }
        }
    }
}
extension EditProfileViewController: UITextFieldDelegate {
    //tag 0 is Name
    //tag 1 is email
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            
        } else if textField.tag == 1{
            //email changed
            
        }
    }
}
