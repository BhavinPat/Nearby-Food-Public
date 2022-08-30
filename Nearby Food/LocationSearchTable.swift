//
//  LocationSearchTable.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/8/21.
//

import UIKit
import MapKit
import OSLog

class LocationSearchTable: UITableViewController {
    
    weak var handleMapSearchDelegate: HandleMapSearch?
    var matchingItems: [BusinessDetailSearch?] = []
    var nextSetRegionCenter: CLLocationCoordinate2D? = nil
    var mapView: MKMapView?
    let defaults = UserDefaults.standard
}
extension LocationSearchTable: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hideMapDetailView"), object: nil, userInfo: nil)
    }
    
}
extension LocationSearchTable : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = self.mapView,
              var searchBarText = searchController.searchBar.text else { return }
        var longitude = mapView.region.center.longitude
        var latitude = mapView.region.center.latitude
        let useCurrentLocation = defaults.bool(forKey: "userCurrentLocation")
        if useCurrentLocation, let userLocation = mapView.userLocation.location {
            longitude = userLocation.coordinate.longitude
            latitude =  userLocation.coordinate.latitude
        }
        let open_now = !defaults.bool(forKey: "filterIsNotOpenNow")
        let rating = defaults.string(forKey: "filterRating") ?? "3"
        let price = defaults.string(forKey: "filterPrice") ?? "1,2,3,4"
        let distance = defaults.integer(forKey: "filterDistance")
        var categoryString = ""
        if let categoryArray = defaults.array(forKey: "filterCheckmarkedCategories") as? [String] {
            for category1 in categoryArray {
                categoryString.append("\(category1),")
            }
            if !categoryString.isEmpty {
                categoryString.removeLast()
            }
        } else {
            categoryString = "food,restaurants"
        }
        if !defaults.bool(forKey: "didBuyCategoryIAP") {
            for stuff in AllCategoryAvailable.shared.allCategoriesAvailable {
                let categorysearchtern = JaroSimilarity.shared.jaroWinkler(searchBarText, stuff.title)
                if categorysearchtern >= 0.95 {
                    searchBarText = ""
                }
            }
        }
        let businessesRequest = SearchRequest(longitude: "\(longitude)", latitude: "\(latitude)", term: searchBarText, radius: distance, price: price, open_now: open_now, rating: rating, categories: categoryString)
        businessesRequest.getBusinesses { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
            case .success(let request):
                let businesses = request.businesses
                self?.matchingItems = businesses
                self?.nextSetRegionCenter = CLLocationCoordinate2D(latitude: request.region.center.latitude, longitude: request.region.center.latitude)
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    
}

extension LocationSearchTable {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if matchingItems.isEmpty || matchingItems.count == 0 {
            return 216.0
        }
        return 80.0
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if matchingItems.isEmpty || matchingItems.count == 0 {
            return 1
        }
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if matchingItems.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nothingHere", for: indexPath) as! NothingHereTableViewCell
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "result", for: indexPath) as! ResultSearchMapTableViewCell
        if indexPath.row >= matchingItems.count {
            cell.name.text = "No Business Found Please Try New Search"
            cell.distance.text = .none
            cell.address.text = .none
            cell.price.text = .none
            cell.rating.text = .none
            return cell
        }
        guard let business = matchingItems[indexPath.row] else {
            cell.name.text = "No Business Found Please Try New Search"
            cell.distance.text = .none
            cell.address.text = .none
            cell.price.text = .none
            cell.rating.text = .none
            return cell
        }
        cell.business = business
        cell.name.text = business.name
        cell.distance.text = "No Distance"
        if let businessImage = business.image_url {
            if let businessURL = URL(string: businessImage) {
                cell.businessImage.downloaded(from: businessURL)
                cell.businessImage.downloaded(from: businessURL)
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
                cell.businessImage.isUserInteractionEnabled = true
                cell.businessImage.addGestureRecognizer(tapGestureRecognizer)
            }
        }
        let busLocation = CLLocation(latitude: business.coordinates.latitude, longitude: business.coordinates.longitude)
        if let usersPos =  mapView?.userLocation {
            let userLoc = CLLocation(latitude: usersPos.coordinate.latitude, longitude: usersPos.coordinate.longitude)
            let distance = userLoc.distance(from: busLocation)
            let MkDistanceFormatter = MKDistanceFormatter()
            MkDistanceFormatter.locale = .current
            MkDistanceFormatter.unitStyle = .default
            MkDistanceFormatter.units = .default
            let distanceAwayString = MkDistanceFormatter.string(fromDistance: distance)
            cell.distance.text = distanceAwayString
        }
        let fullAddress = "\(business.location.address1 ?? "no address")"
        cell.address.text = fullAddress
        cell.price.text = business.price
        cell.rating.layer.masksToBounds = true
        cell.rating.layer.cornerRadius = 6.5
        let starAttachmnet = NSTextAttachment()
        var starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .yellow)
        if business.rating <= 1.5 {
            cell.rating.backgroundColor = UIColor(red: 242/255, green: 189/255, blue: 121/255, alpha: 1.0)
            cell.rating.textColor = .black
            starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .black)
        } else if business.rating <= 2.0 {
            cell.rating.backgroundColor = UIColor(red: 254/255, green: 192/255, blue: 17/255, alpha: 1.0)
            starCongifuration = UIImage.SymbolConfiguration(hierarchicalColor: .black)
            cell.rating.textColor = .black
        } else if business.rating <= 3.5 {
            cell.rating.backgroundColor = UIColor(red: 255/255, green: 146/255, blue: 66/255, alpha: 1.0)
        } else if business.rating <= 4.5 {
            cell.rating.backgroundColor = UIColor(red: 241/255, green: 92/255, blue: 79/255, alpha: 1.0)
        } else {
            cell.rating.backgroundColor = UIColor(red: 211/255, green: 35/255, blue: 35/255, alpha: 1.0)
        }
        cell.businessID = business.id
        cell.setUpIWantToTry()
        cell.setUpPeopleLove()
        cell.price.textColor = .systemGreen
        starAttachmnet.image = UIImage(systemName: "star.fill", withConfiguration: starCongifuration)
        let starString = NSMutableAttributedString(attachment: starAttachmnet)
        let textString = NSMutableAttributedString(string: " \(business.rating)/5")
        textString.append(starString)
        cell.rating.attributedText = textString
        return cell
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
}

extension LocationSearchTable {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if matchingItems.count == 0 || matchingItems.isEmpty {
            return
        }
        if indexPath.row >= matchingItems.count {
            return
        }
        guard let business = matchingItems[indexPath.row] else {
            return 
        }
        //use when selecting business from other tabs (favorite, nearby)
        //handleMapSearchDelegate?.dropPinZoomIn(business: business)
        var matchItems = matchingItems
        matchItems.remove(at: indexPath.row)
        NotificationCenter.default.post(name: NSNotification.Name("nearbyFromSearchTable"), object: self, userInfo: ["businesses": matchItems, "business": business])
        
        self.dismiss(animated: true, completion: nil)
        //hide mapdetail when search bar is tapped
        
    }
    
}
