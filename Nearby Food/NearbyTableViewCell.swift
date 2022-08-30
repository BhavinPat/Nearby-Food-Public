//
//  NearbyTableViewCell.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/4/22.
//
//nearbyTableViewCell

import UIKit
import Firebase
import MapKit
class NearbyTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    var userLocation: CLLocation!
    let defaults = UserDefaults.standard
    var isIwantToTry = false
    var business: BusinessDetailSearch!
    var ref: DatabaseReference!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var iWantToTryButton: UIButton!
    @IBOutlet weak var businessImage: UIImageView!
    @IBOutlet weak var peopleLove: UILabel!
    @IBAction func iWant2TryAct(_ sender: UIButton) {
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
                    iWantToTryArray.removeAll {$0 == business.id}
                } else {
                    isIwantToTry = true
                    iWantToTryWithAdd()
                    iWantToTryArray.append(business.id)
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
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setUpDistance() {
        let busLocation = CLLocation(latitude: business.coordinates.latitude, longitude: business.coordinates.longitude)
        if let usersPos =  userLocation {
            let userLoc = CLLocation(latitude: usersPos.coordinate.latitude, longitude: usersPos.coordinate.longitude)
            let distance1 = userLoc.distance(from: busLocation)
            let MkDistanceFormatter = MKDistanceFormatter()
            MkDistanceFormatter.locale = .current
            MkDistanceFormatter.unitStyle = .default
            MkDistanceFormatter.units = .default
            let distanceAwayString = MkDistanceFormatter.string(fromDistance: distance1)
            distance.text = distanceAwayString
        } else {
            distance.text = ""
        }
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
                        if business == self.business.id {
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
    func setUpFavoriteLabel() {
        ref = Database.database().reference()
        ref.keepSynced(true)
        let communityRef = ref.child("communityFavorites/")
        let businessID = business.id
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
    @objc func goToLogInCreateAccountView() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "presentLogInCreateVC"), object: nil)
    }
}
