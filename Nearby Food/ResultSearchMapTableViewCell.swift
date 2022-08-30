//
//  ResultSearchMapTableViewCell.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/8/21.
//

import UIKit
import Firebase
import OSLog

class ResultSearchMapTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    let defaults = UserDefaults.standard
    var isIwantToTry = false
    var business: BusinessDetailSearch!
    var businessID = ""
    var ref: DatabaseReference!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var iWantToTryButton: UIButton!
    @IBOutlet weak var businessImage: UIImageView!
    @IBOutlet weak var peopleLove: UILabel!
    @IBAction func iWantToTryButtonAction(_ sender: UIButton) {
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
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setUpIWantToTry() {
        ref = Database.database().reference()
        ref.keepSynced(true)
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
            iWantToTryButton.isHidden = true
        }
    }
    func setUpPeopleLove() {
        let communityRef = ref.child("communityFavorites/")
        communityRef.child(businessID).observeSingleEvent(of: .value, with: { [self]
            (snapshot) in
            let intOfBus = (snapshot.value as? Int) ?? 0
            if intOfBus == 0 {
                peopleLove.isHidden = true
            } else {
                peopleLove.isHidden = false
            }
            let heartAttachmnet = NSTextAttachment()
            let heartCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .red)
            heartAttachmnet.image = UIImage(systemName: "heart.circle.fill", withConfiguration: heartCongifuration)
            let starString = NSMutableAttributedString(attachment: heartAttachmnet)
            let textString = NSMutableAttributedString(string: "\(intOfBus) ")
            textString.append(starString)
            peopleLove.attributedText = textString
            
        })
    }
    func iWantToTryWithAdd() {
        //user added to like or is added
        iWantToTryButton.backgroundColor = .secondarySystemFill
        iWantToTryButton.setTitleColor(.link, for: .normal)
        
        let checkmarkAttachment = NSTextAttachment()
        let starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
        checkmarkAttachment.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: starCongifuration)
        let checkmarkString = NSMutableAttributedString(attachment: checkmarkAttachment)
        let textString = NSMutableAttributedString(string: " Try ")
        textString.append(checkmarkString)
        iWantToTryButton.setAttributedTitle(textString, for: .normal)
    }
    func iWantToTryWithRemove() {
        iWantToTryButton.backgroundColor = .secondarySystemFill
        iWantToTryButton.setTitleColor(.link, for: .normal)
        
        let checkmarkAttachment = NSTextAttachment()
        let starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
        checkmarkAttachment.image = UIImage(systemName: "circle", withConfiguration: starCongifuration)
        let checkmarkString = NSMutableAttributedString(attachment: checkmarkAttachment)
        let textString = NSMutableAttributedString(string: " Try ")
        textString.append(checkmarkString)
        iWantToTryButton.setAttributedTitle(textString, for: .normal)
        //user removed
    }
}
