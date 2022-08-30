//
//  TryMeTableViewCell.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 12/16/21.
//
//only way to sign in is in settings. in settings if signing out the default = databse. if signing in databse = default. if there is something stored in database ask if want to replace or not
import UIKit
import MapKit
import Firebase
import OSLog

class TryMeTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var open: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var reviews: UILabel!
    @IBOutlet weak var reviewImage: UIImageView!
    @IBOutlet weak var businessImage: UIImageView!
    @IBOutlet weak var businessYelpLinkButton: UIButton!
    @IBOutlet weak var howManyPeopleLoveText: UILabel!
    //@IBOutlet weak var iWantToTryButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBAction func favoriteButtonAct(_ sender: UIButton) {
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
                    favoriteArray.removeAll {$0 == businessID}
                } else {
                    isfavorite = true
                    createFavoriteImage(color: .systemRed)
                    favoriteArray.append(businessID)
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
    @IBAction func businessYelpLinkButtonAct(_ sender: UIButton) {
        let link = business.url
        if let url = URL(string: link) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    var business: BusinessDetail!
    var businessID = ""
    var isIwantToTry = true
    var isfavorite = false
    var userLocation: CLLocation!
    var defaults = UserDefaults.standard
    var ref: DatabaseReference!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func findBusiness() {
        //CALL API
        price.text = "No Price"
        price.textColor = .systemGreen
        name.text = "No Name"
        open.text = "No Hours"
        open.textColor = .systemRed
        reviews.text = "No Reviews"
        reviewImage.image = nil
        
        let businessesRequest = BusinessDetailRequest(id: businessID)
        businessesRequest.getBusiness { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
                //UIAlert please try searching agian.
            case .success(let business):
                DispatchQueue.main.async {
                    self?.business = business
                    self?.setUpView()
                    self?.isHidden = false
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tryMeAddOneToCompletedCell"), object: nil, userInfo: nil)
                }
            }
        }
    }
    func setUpView() {
        ref = Database.database().reference()
        ref.keepSynced(true)
        setUpBasics()
        setUpReviews()
        setUpBusinessimage()
        setUpFavorite()
        setUpOpen()
        setUpDistance()
        setUpIWantToTry()
        setUpYelpImage()
        setUpHowManyPeopleLove()
    }
    func setUpYelpImage() {
        if traitCollection.userInterfaceStyle == .dark {
            businessYelpLinkButton.setBackgroundImage(UIImage(named: "yelp_logo_dark_bg"), for: .normal)
        } else {
            businessYelpLinkButton.setBackgroundImage(UIImage(named: "yelp_logo"), for: .normal)
        }
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
    func setUpIWantToTry() {
        //createIWantToTryImage(color: .link)
        //iWantToTryButton.layer.masksToBounds = true
        //iWantToTryButton.layer.cornerRadius = 6.5
    }
    func setUpReviews() {
        reviews.text = "No Reviews"
        reviewImage.image = nil
        var imageName = "large_"
        let stringValue = String(business.rating)
        let stringArray = Array(stringValue)
        let decimalValue = stringArray[2]
        let firstValue = stringArray[0]
        imageName.append(firstValue)
        if decimalValue != "0" {
            imageName.append("_half")
        }
        reviewImage.image = UIImage(named: imageName)
        reviewImage.layer.masksToBounds = true
        reviews.layer.cornerRadius = 6.5
        if business.rating <= 1.5 {
            reviews.textColor = UIColor(red: 242/255, green: 189/255, blue: 121/255, alpha: 1.0)
        } else if business.rating <= 2.0 {
            reviews.textColor = UIColor(red: 254/255, green: 192/255, blue: 17/255, alpha: 1.0)
        } else if business.rating <= 3.5 {
            reviews.textColor = UIColor(red: 255/255, green: 146/255, blue: 66/255, alpha: 1.0)
        } else if business.rating <= 4.5 {
            reviews.textColor = UIColor(red: 241/255, green: 92/255, blue: 79/255, alpha: 1.0)
        } else {
            reviews.textColor = UIColor(red: 211/255, green: 35/255, blue: 35/255, alpha: 1.0)
        }
        reviews.text = "\(business.review_count) Reviews"
    }
    func setUpFavorite() {
        createFavoriteImage(color: .link)
        isfavorite = false
        var favoriteArray: [String] = []
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("favorite").observeSingleEvent(of: .value, with: { [self]
                (snapshot) in
                if let favoriteArray1 = snapshot.value as? [String] {
                    favoriteArray = favoriteArray1
                    for business in favoriteArray {
                        if business == self.businessID {
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
        }
    }
    func setUpBasics() {
        name.text = "Name"
        price.text = "Price"
        name.text = business.name
        price.text = business.price ?? ""
        price.textColor = .systemGreen
    }
    func setUpBusinessimage() {
        if let url = URL(string: business.image_url) {
            businessImage.downloaded(from: url)
        }
    }
    func setUpDistance() {
        let busLocation = CLLocation(latitude: business.coordinates.latitude, longitude: business.coordinates.longitude)
        if let usersPos = userLocation {
            let distanceString = usersPos.distance(from: busLocation)
            let MkDistanceFormatter = MKDistanceFormatter()
            MkDistanceFormatter.locale = .current
            MkDistanceFormatter.unitStyle = .default
            MkDistanceFormatter.units = .default
            let distanceAwayString = MkDistanceFormatter.string(fromDistance: distanceString)
            distance.text = distanceAwayString
        } else {
            distance.text = ""
        }
    }
    func setUpOpen() {
        guard let hour = business.hours[0] else {
            open.text = "No Info"
            open.textColor = .red
            return
        }
        if hour.is_open_now ?? true {
            open.text = "Open"
            open.textColor = .systemGreen
        } else {
            open.text = "Closed"
            open.textColor = .systemRed
        }
    }
    func createFavoriteImage(color: UIColor) {
        let colorConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: color)
        let scaleConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let configuration = colorConfiguration.applying(scaleConfiguration)
        let image = UIImage(systemName: "heart.circle.fill", withConfiguration: configuration)
        favoriteButton.setBackgroundImage(image, for: .normal)
    }
    /*
    func createIWantToTryImage(color: UIColor) {
        iWantToTryButton.backgroundColor = color
        if iWantToTryButton.backgroundColor == .link {
            iWantToTryButton.setTitleColor(.secondaryLabel, for: .normal)
        } else {
            iWantToTryButton.setTitleColor(.link, for: .normal)
        }
    }
     */
}
