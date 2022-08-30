//
//  HomeCollectionViewCell.swift
//  Nearby Food
//
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 2/26/22.
//

import UIKit
import MapKit
import Firebase
import FirebaseAuth
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseEmailAuthUI
import FirebaseOAuthUI

class HomeCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var businessTitle: UILabel!
    @IBOutlet weak var businessImage: UIImageView!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var iWantToTryButton: UIButton!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var howManyPeopleLoveText: UILabel!
    
    var business: BusinessDetailSearch!
    var businessID = ""
    var isIwantToTry = false
    var defaults = UserDefaults.standard
    var ref: DatabaseReference!
    
    @IBAction func iwantToTryButtonAct(_ sender: UIButton) {
        var iWantToTryArray: [String] = []
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("iWantToTry").observeSingleEvent(of: .value, with: { [self]
                (snapshot) in
                if let iWantToTryArray1 = snapshot.value as? [String] {
                    iWantToTryArray = iWantToTryArray1
                }
                if isIwantToTry {
                    isIwantToTry = false
                    iWantToTryWithRemove()
                    iWantToTryArray.removeAll {$0 == businessID}
                } else {
                    isIwantToTry = true
                    iWantToTryWithAdd()
                    iWantToTryArray.append(businessID)
                }
                if let user = Auth.auth().currentUser {
                    let userRef = ref.child("users/" + user.uid)
                    userRef.child("iWantToTry").setValue(iWantToTryArray)
                    defaults.set(iWantToTryArray, forKey: "iWantToTryLocal")
                }
            })
        } else {
            goToLogInCreateAccountView()
        }
    }

    func setUpView() {
        ref = Database.database().reference()
        ref.keepSynced(true)
        setUpBasics()
        setUpIWantToTry()
        setUpHowManyPeopleLoveThis()
    }
    func setUpIWantToTry() {
        iWantToTryWithRemove()
        isIwantToTry = false
        iWantToTryButton.layer.masksToBounds = true
        iWantToTryButton.layer.cornerRadius = 6.5
        var iWantToTryArray: [String] = []
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("iWantToTry").observeSingleEvent(of: .value, with: { [self]
                (snapshot) in
                if let iWantToTryArray1 = snapshot.value as? [String] {
                    iWantToTryArray = iWantToTryArray1
                    for business in iWantToTryArray {
                        if business == self.businessID {
                            iWantToTryWithAdd()
                            isIwantToTry = true
                            break
                        } else {
                            iWantToTryWithRemove()
                            isIwantToTry = false
                        }
                    }
                }
            })
        } else {
            setUpSignIn()
        }
    }
    func setUpSignIn() {
        iWantToTryButton.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        iWantToTryButton.setTitleColor(.link, for: .normal)
        
        let textString = NSMutableAttributedString(string: "Log In")
        iWantToTryButton.setAttributedTitle(textString, for: .normal)
    }
    func setUpBasics() {
        price.text = " Price "
        price.text = "\(business.price ?? "")"
        price.textColor = .systemGreen
        
        price.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        howManyPeopleLoveText.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        price.layer.masksToBounds = true
        price.layer.cornerRadius = 6.5
        howManyPeopleLoveText.layer.masksToBounds = true
        howManyPeopleLoveText.layer.cornerRadius = 6.5
        
        let starAttachmnet = NSTextAttachment()
        var starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .yellow)
        if business.rating <= 1.5 {
            rating.backgroundColor = UIColor(red: 242/255, green: 189/255, blue: 121/255, alpha: 1.0)
            rating.textColor = .black
            starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .black)
        } else if business.rating <= 2.0 {
            rating.backgroundColor = UIColor(red: 254/255, green: 192/255, blue: 17/255, alpha: 1.0)
            starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .black)
            rating.textColor = .black
        } else if business.rating <= 3.5 {
            rating.backgroundColor = UIColor(red: 255/255, green: 146/255, blue: 66/255, alpha: 1.0)
        } else if business.rating <= 4.5 {
            rating.backgroundColor = UIColor(red: 241/255, green: 92/255, blue: 79/255, alpha: 1.0)
        } else {
            rating.backgroundColor = UIColor(red: 211/255, green: 35/255, blue: 35/255, alpha: 1.0)
        }
        rating.layer.masksToBounds = true
        rating.layer.cornerRadius = 6.5
        price.textColor = .systemGreen
        starAttachmnet.image = UIImage(systemName: "star.fill", withConfiguration: starCongifuration)
        let starString = NSMutableAttributedString(attachment: starAttachmnet)
        let textString = NSMutableAttributedString(string: " \(business.rating)/5")
        textString.append(starString)
        rating.attributedText = textString
        
        //businessTitle.layer.masksToBounds = true
        //businessTitle.layer.cornerRadius = 6.5
        //businessTitle.textColor = .white
        //businessTitle.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.6)
    }
    func setUpHowManyPeopleLoveThis() {
        //both ways work. Which one is better.
        /*
        let communityRef = ref.child("communityFavorites/")
        communityRef.observeSingleEvent(of: .value, with: { [self]
            (snapshot) in
            let intOfBus = (snapshot.value as? [String: Int])
            let some = intOfBus?[business.id, default: 0] ?? 0
            howManyPeopleLoveText.text = "\(some) people love this business"
            
        })
         */
        
        
        ref = Database.database().reference()
        ref.keepSynced(true)
        let communityRef = ref.child("communityFavorites/")
        let businessID = business.id
        communityRef.child(businessID).observeSingleEvent(of: .value, with: { [self]
            (snapshot) in
            let intOfBus = (snapshot.value as? Int) ?? 0
            if intOfBus == 0 {
                howManyPeopleLoveText.isHidden = true
            } else {
                howManyPeopleLoveText.isHidden = false
            }
            let heartAttachmnet = NSTextAttachment()
            let heartCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .red)
            heartAttachmnet.image = UIImage(systemName: "heart.circle.fill", withConfiguration: heartCongifuration)
            let starString = NSMutableAttributedString(attachment: heartAttachmnet)
            let textString = NSMutableAttributedString(string: " \(intOfBus) ")
            textString.append(starString)
            textString.append(NSMutableAttributedString(string: " "))
            howManyPeopleLoveText.attributedText = textString
            
        })
        
        /*
        let communityRef = ref.child("communityFavorites/")
        communityRef.child(businessID).observeSingleEvent(of: .value, with: { [self]
            (snapshot) in
            let intOfBus = (snapshot.value as? Int) ?? 0
            if intOfBus == 0 {
                howManyPeopleLoveText.isHidden = true
            } else {
                howManyPeopleLoveText.isHidden = false
            }
            howManyPeopleLoveText.text = "\(intOfBus) people love this business"
            
        })
         */
    }

    func iWantToTryWithAdd() {
        //user added to like or is added
        iWantToTryButton.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        iWantToTryButton.setTitleColor(.link, for: .normal)
        
        let checkmarkAttachment = NSTextAttachment()
        let starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
        checkmarkAttachment.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: starCongifuration)
        let checkmarkString = NSMutableAttributedString(attachment: checkmarkAttachment)
        let textString = NSMutableAttributedString(string: " I Want To Try ")
        textString.append(checkmarkString)
        iWantToTryButton.setAttributedTitle(textString, for: .normal)
    }
    func iWantToTryWithRemove() {
        iWantToTryButton.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        iWantToTryButton.setTitleColor(.link, for: .normal)
        
        let checkmarkAttachment = NSTextAttachment()
        let starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
        checkmarkAttachment.image = UIImage(systemName: "circle", withConfiguration: starCongifuration)
        let checkmarkString = NSMutableAttributedString(attachment: checkmarkAttachment)
        let textString = NSMutableAttributedString(string: " I Want To Try ")
        textString.append(checkmarkString)
        iWantToTryButton.setAttributedTitle(textString, for: .normal)
        //user removed
    }
    @objc func goToLogInCreateAccountView() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "presentLogInCreateVC"), object: nil)
    }
}
