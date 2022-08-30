//
//  MapDetailViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/24/21.
//

import UIKit
import MapKit
import Foundation
import Firebase
import SwiftUI
import OSLog

class MapDetailView: UIView {
    @IBOutlet weak var mapDetailView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var phoneNumber: UIButton!
    @IBOutlet weak var iWantToTry: UIButton!
    @IBOutlet weak var ratingNum: UILabel!
    @IBOutlet weak var is_open: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var URL_LINK: UIButton!
    @IBOutlet weak var mainPhoto: UIImageView!
    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var sunTimeLabel: UILabel!
    @IBOutlet weak var monTimeLabel: UILabel!
    @IBOutlet weak var tuesTimeLabel: UILabel!
    @IBOutlet weak var wedTimeLabel: UILabel!
    @IBOutlet weak var thursTimeLabel: UILabel!
    @IBOutlet weak var friTimeLabel: UILabel!
    @IBOutlet weak var satTimeLabel: UILabel!
    @IBOutlet weak var messageBusinessButton: UIButton!
    @IBOutlet weak var transactionsLabel: UILabel!
    @IBOutlet weak var busImage1: UIImageView!
    @IBOutlet weak var busImage2: UIImageView!
    @IBOutlet weak var busImage3: UIImageView!
    @IBOutlet weak var howManyPeopleLoveText: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    let defaults = UserDefaults.standard
    var usersLocation: CLLocation?
    var isfavorite = false
    var isIwantToTry = false
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    var messagingURL: URL!
    
    @IBAction func messageBusinessButtonAction(_ sender: UIButton!) {
        guard let url = messagingURL else {
            return
        }
        UIApplication.shared.open(url)
        
    }
    @IBAction func yelpURLAction(_ sender: UIButton) {
        let link = business.url
        if let url = URL(string: link) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    @IBAction func phoneNumberAction(_ sender: Any) {
        let urlString = business.phone?.filter("0123456789".contains)
        if let url = URL(string: "tel://\(urlString ?? "")"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func shareBusiness(_ sender: UIButton!) {
        let link = business.url
        if let url = URL(string: link) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "shareBusinessButtonPressed"), object: nil,userInfo: ["urlToBus": url])
        }
    }
    @IBAction func iWantToTryAct(_ sender: UIButton!) {
        //need way to make sure data is stored in database when user switched from default to sign in
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
    @IBAction func favortieButtonAction(_ sender: Any) {
        var favoriteArray: [String] = []
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("favorite").observeSingleEvent(of: .value, with: { [self]
                (snapshot) in
                if let favoriteArray1 = snapshot.value as? [String] {
                    favoriteArray = favoriteArray1
                }
                if isfavorite {
                    isfavorite = false
                    createFavoriteImage(color: .label)
                    favoriteArray.removeAll {$0 == business.id}
                } else {
                    isfavorite = true
                    createFavoriteImage(color: .systemRed)
                    favoriteArray.append(business.id)
                }
                if let user = Auth.auth().currentUser {
                    let userRef = ref.child("users/" + user.uid)
                    userRef.child("favorite").setValue(favoriteArray)
                }
                var communityLoved = 0
                let communityRef = ref.child("communityFavorites/")
                communityRef.child(business.id).observeSingleEvent(of: .value, with: { [self]
                    (snapshot) in
                    let intOfBus = (snapshot.value as? Int) ?? 0
                    communityLoved = intOfBus
                    if isfavorite {
                        communityLoved += 1
                    } else {
                        communityLoved -= 1
                    }
                    if communityLoved < 0 {
                        communityLoved = 0
                    }
                    communityRef.child(business.id).setValue(communityLoved)
                    setUpHowManyPeopleLove()
                })
            })
        }
    }
    var businessSearch: BusinessDetailSearch!
    var business: BusinessDetail!
    //from businesss just need business ID. Create New API request fro all the rest of the detail. Need to rewrite all the API stuff
    deinit {
        Logger().info("MapDetailViewController was deinit")
        NotificationCenter.default.removeObserver(self)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        let name = String(describing: type(of: self))
        let nib = UINib(nibName: name, bundle: .main)
        nib.instantiate(withOwner: self, options: nil)
        self.addSubview(self.mapDetailView)
        ref = Database.database().reference()
        ref.keepSynced(true)
        self.mapDetailView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.mapDetailView.topAnchor.constraint(equalTo: self.topAnchor),
            self.mapDetailView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.mapDetailView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.mapDetailView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }
    func findBusiness() {
        //CALL API
        let businessesRequest = BusinessDetailRequest(id: businessSearch.id)
        businessesRequest.getBusiness { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
                //UIAlert please try searching agian.
            case .success(let business):
                DispatchQueue.main.async { [self] in
                    self?.business = business
                    self?.handle = Auth.auth().addStateDidChangeListener { [self] auth, user in
                        self?.setUpBusiness()
                    }
                }
            }
        }
    }
    func setUpBusiness() {
        isIwantToTry = false
        isfavorite = false
        name.text = "Name"
        price.text = "Price"
        phoneNumber.setTitle("No Phone Number", for: .normal)
        name.text = "   \(business.name)"
        price.text = business.price ?? ""
        price.textColor = .systemGreen
        phoneNumber.setTitle(business.display_phone, for: .normal)
        if let url = URL(string: business.image_url) {
            mainPhoto.downloaded(from: url)
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
            mainPhoto.isUserInteractionEnabled = true
            mainPhoto.addGestureRecognizer(tapGestureRecognizer)
        }
        setUpReviews()
        setUpYelpImageURL()
        setUpFavoriteButton()
        setUpAddress()
        setUpOpenTimes()
        setUpDistance()
        setUpIWantToTryButton()
        isMessagable()
        setPhotos()
        setTransactions()
        setUpHowManyPeopleLove()
    }
    func setTransactions() {
        transactionsLabel.isHidden = true
        guard let transactions = business.transactions else {
            return
        }
        var transactionString = "Business has: "
        
        for transaction in transactions {
            if transaction == "pickup" {
                transactionString.append("\nTakeout")
            }
            if transaction == "delivery" {
                transactionString.append("\nDelivery")
            }
            if transaction == "restaurant_reservation" {
                transactionString.append("\nReservation")
            }
            transactionsLabel.isHidden = false
        }
        transactionsLabel.text = transactionString
        
    }
    func setUpHowManyPeopleLove() {
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
    }
    func setPhotos() {
        guard let photoString = business.photos else {
            busImage1.isHidden = true
            busImage1.gestureRecognizers?.forEach(busImage1.removeGestureRecognizer)
            busImage2.isHidden = true
            busImage2.gestureRecognizers?.forEach(busImage2.removeGestureRecognizer)
            busImage3.isHidden = true
            busImage3.gestureRecognizers?.forEach(busImage3.removeGestureRecognizer)
            return
        }
        if 1 <= photoString.count {
            busImage1.isHidden = false
            busImage1.downloaded(from: photoString[0])
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
            busImage1.isUserInteractionEnabled = true
            busImage1.addGestureRecognizer(tapGestureRecognizer)
        } else {
            busImage1.isHidden = true
        }
        if 2 <= photoString.count {
            busImage2.isHidden = false
            busImage2.downloaded(from: photoString[1])
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
            busImage2.isUserInteractionEnabled = true
            busImage2.addGestureRecognizer(tapGestureRecognizer)
        } else {
            busImage2.isHidden = true
        }
        if 3 <= photoString.count {
            busImage3.isHidden = false
            busImage3.downloaded(from: photoString[2])
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
            busImage3.isUserInteractionEnabled = true
            busImage3.addGestureRecognizer(tapGestureRecognizer)
        } else {
            busImage3.isHidden = true
        }
    }
    @objc func handleTap(sender: UIGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        let vc = PresentImageViewController()
        //vc.view.backgroundColor = UIColor.blue
        vc.modalPresentationStyle = .popover
        
        //vc.preferredContentSize = CGSize(width: 200, height: 200)
        
        let ppc = vc.popoverPresentationController
        ppc?.permittedArrowDirections = .any
        ppc?.delegate = self
        //ppc?.barButtonItem = navigationItem.rightBarButtonItem
        ppc?.sourceView = imageView
        let keyWindow = UIApplication.shared.keyWindow
        if let topController = keyWindow?.rootViewController {
            if let presentedViewController = topController.presentedViewController {
                presentedViewController.present(vc, animated: true)
                vc.image = imageView.image
            }// topController should now be your topmost view controller
        }
       // self.present(vc, animated: true, completion: nil)
        
    }
    func isMessagable() {
        if let urlString = business.messaging?["url"], let textMessage = business.messaging?["use_case_text"] {
            messagingURL = URL(string: urlString)
            messageBusinessButton.isHidden = false
            messageBusinessButton.setTitle(textMessage, for: .normal)
        } else {
            messageBusinessButton.isHidden = true
            messagingURL = nil
        }
    }
    func setUpDistance() {
        distance.text = "No Distance"
        let busLocation = CLLocation(latitude: business.coordinates.latitude, longitude: business.coordinates.longitude)
        if let usersPos = usersLocation {
            let distanceString = usersPos.distance(from: busLocation)
            let MkDistanceFormatter = MKDistanceFormatter()
            MkDistanceFormatter.locale = .current
            MkDistanceFormatter.unitStyle = .default
            MkDistanceFormatter.units = .default
            let distanceAwayString = MkDistanceFormatter.string(fromDistance: distanceString)
            distance.text = distanceAwayString
        }
    }
    func setUpFavoriteButton() {
        favoriteButton.isHidden = false
        createFavoriteImage(color: .label)
        isfavorite = false
        var favoriteArray: [String] = []
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("favorite").observeSingleEvent(of: .value, with: { [self]
                (snapshot) in
                if let favoriteArray1 = snapshot.value as? [String] {
                    favoriteArray = favoriteArray1
                    for business in favoriteArray {
                        if business == self.business.id {
                            createFavoriteImage(color: .systemRed)
                            isfavorite = true
                            break
                        } else {
                            createFavoriteImage(color: .label)
                            isfavorite = false
                        }
                    }
                }
            })
        } else {
            favoriteButton.isHidden = true
        }
    }
    func setUpIWantToTryButton() {
        iWantToTryWithRemove()
        iWantToTry.layer.masksToBounds = true
        iWantToTry.layer.cornerRadius = 6.5
        isIwantToTry = false
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
    func createFavoriteImage(color: UIColor) {
        let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: color)
        let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let configuration = colorConfiguration.applying(scaleConfiguration)
        let image = UIImage(systemName: "heart.circle.fill", withConfiguration: configuration)
        favoriteButton.setImage(image, for: .normal)
    }
    func iWantToTryWithAdd() {
        //user added to like or is added
        iWantToTry.backgroundColor = .secondarySystemFill
        iWantToTry.setTitleColor(.link, for: .normal)
        
        let checkmarkAttachment = NSTextAttachment()
        let starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
        checkmarkAttachment.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: starCongifuration)
        let checkmarkString = NSMutableAttributedString(attachment: checkmarkAttachment)
        let textString = NSMutableAttributedString(string: " I Want To Try ")
        textString.append(checkmarkString)
        iWantToTry.setAttributedTitle(textString, for: .normal)
    }
    func iWantToTryWithRemove() {
        iWantToTry.backgroundColor = .secondarySystemFill
        iWantToTry.setTitleColor(.link, for: .normal)
        
        let checkmarkAttachment = NSTextAttachment()
        let starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .link)
        checkmarkAttachment.image = UIImage(systemName: "circle", withConfiguration: starCongifuration)
        let checkmarkString = NSMutableAttributedString(attachment: checkmarkAttachment)
        let textString = NSMutableAttributedString(string: " I Want To Try ")
        textString.append(checkmarkString)
        iWantToTry.setAttributedTitle(textString, for: .normal)
        //user removed
    }
    func setUpOpenTimes() {
        sunTimeLabel.text = "Closed"
        satTimeLabel.text = "Closed"
        monTimeLabel.text = "Closed"
        tuesTimeLabel.text = "Closed"
        wedTimeLabel.text = "Closed"
        thursTimeLabel.text = "Closed"
        friTimeLabel.text = "Closed"
        guard let hour = business.hours[0] else {
            sunTimeLabel.text = "No Time Available"
            satTimeLabel.text = "No Time Available"
            monTimeLabel.text = "No Time Available"
            tuesTimeLabel.text = "No Time Available"
            wedTimeLabel.text = "No Time Available"
            thursTimeLabel.text = "No Time Available"
            friTimeLabel.text = "No Time Available"
            return
        }
        
        if hour.is_open_now ?? true {
            is_open.text = "Open"
            is_open.textColor = .systemGreen
        } else {
            is_open.text = "Closed"
            is_open.textColor = .systemRed
        }
        
        sunTimeLabel.textColor = .systemRed
        satTimeLabel.textColor = .systemRed
        monTimeLabel.textColor = .systemRed
        tuesTimeLabel.textColor = .systemRed
        wedTimeLabel.textColor = .systemRed
        thursTimeLabel.textColor = .systemRed
        friTimeLabel.textColor = .systemRed
        for day in hour.open {
            if day.day == 6 {
                sunTimeLabel.text = convertToRegularTime(startString: day.start, endString: day.end)
                sunTimeLabel.textColor = .secondaryLabel
            } else if day.day == 0 {
                monTimeLabel.text = convertToRegularTime(startString: day.start, endString: day.end)
                monTimeLabel.textColor = .secondaryLabel
            } else if day.day == 1 {
                tuesTimeLabel.text = convertToRegularTime(startString: day.start, endString: day.end)
                tuesTimeLabel.textColor = .secondaryLabel
            } else if day.day == 2 {
                wedTimeLabel.text = convertToRegularTime(startString: day.start, endString: day.end)
                wedTimeLabel.textColor = .secondaryLabel
            } else if day.day == 3 {
                thursTimeLabel.text = convertToRegularTime(startString: day.start, endString: day.end)
                thursTimeLabel.textColor = .secondaryLabel
            } else if day.day == 4 {
                friTimeLabel.text = convertToRegularTime(startString: day.start, endString: day.end)
                friTimeLabel.textColor = .secondaryLabel
            } else if day.day == 5 {
                satTimeLabel.text = convertToRegularTime(startString: day.start, endString: day.end)
                satTimeLabel.textColor = .secondaryLabel
            }
        }
    }
    func convertToRegularTime(startString: String, endString: String) -> String {
        var finalString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        let startDate24 = dateFormatter.date(from: startString)
        dateFormatter.dateFormat = "h:mm a"
        let startDate12 = dateFormatter.string(from: startDate24!)
        finalString.append("\(startDate12) - ")
        dateFormatter.dateFormat = "HHmm"
        let endDate24 = dateFormatter.date(from: endString)
        dateFormatter.dateFormat = "h:mm a"
        let endDate12 = dateFormatter.string(from: endDate24!)
        finalString.append("\(endDate12)")
        return finalString
    }
    func setUpAddress() {
        address.text? = ""
        address.text?.append(business.location.display_address[0] ?? "")
        address.text?.append("\n")
        if business.location.display_address.count >= 3 {
            if let _ = business.location.display_address[1] {
                address.text?.append(business.location.display_address[1] ?? "")
            }
            if let _ = business.location.display_address[2] {
                address.text?.append("\n")
                address.text?.append(business.location.display_address[2] ?? "")
            }
        }
        if address.text?.suffix(1) == ["\n"] {
            address.text?.removeLast()
        }
        if address.text == "\n" || address.text == "" {
            address.text = "No Address"
        }
    }
    func setUpYelpImageURL() {
        if traitCollection.userInterfaceStyle == .dark {
            URL_LINK.setBackgroundImage(UIImage(named: "yelp_logo_dark_bg"), for: .normal)
        } else {
            URL_LINK.setBackgroundImage(UIImage(named: "yelp_logo"), for: .normal)
        }
    }
    func setUpReviews() {
        ratingNum.text = "No Reviews"
        ratingImage.image = nil
        var imageName = "extra_large_"
        let stringValue = String(business.rating)
        let stringArray = Array(stringValue)
        let decimalValue = stringArray[2]
        let firstValue = stringArray[0]
        imageName.append(firstValue)
        if decimalValue != "0" {
            imageName.append("_half")
        }
        ratingImage.image = UIImage(named: imageName)
        ratingImage.layer.masksToBounds = true
        ratingImage.layer.cornerRadius = 6.5
        if business.rating <= 1.5 {
            ratingNum.textColor = UIColor(red: 242/255, green: 189/255, blue: 121/255, alpha: 1.0)
        } else if business.rating <= 2.0 {
            ratingNum.textColor = UIColor(red: 254/255, green: 192/255, blue: 17/255, alpha: 1.0)
        } else if business.rating <= 3.5 {
            ratingNum.textColor = UIColor(red: 255/255, green: 146/255, blue: 66/255, alpha: 1.0)
        } else if business.rating <= 4.5 {
            ratingNum.textColor = UIColor(red: 241/255, green: 92/255, blue: 79/255, alpha: 1.0)
        } else {
            ratingNum.textColor = UIColor(red: 211/255, green: 35/255, blue: 35/255, alpha: 1.0)
        }
        ratingNum.text = "\(business.review_count) Reviews"
    }
    func setUpSignIn() {
        iWantToTry.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        iWantToTry.setTitleColor(.link, for: .normal)
        
        let textString = NSMutableAttributedString(string: "Log In")
        iWantToTry.setAttributedTitle(textString, for: .normal)
    }
    @objc func goToLogInCreateAccountView() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "presentLogInCreateVC"), object: nil)
    }
}
//MARK: - UIPopoverPresentationControllerDelegate
extension MapDetailView: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .overCurrentContext
    }
}
extension NearbyTableViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .overCurrentContext
    }
}
extension LocationSearchTable: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .overCurrentContext
    }
}



