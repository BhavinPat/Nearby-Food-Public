//
//  NearbyTableViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/2/21.
//

import UIKit
import MapKit
import OSLog
import Firebase
import FirebaseAuth

class NearbyTableViewController: UITableViewController, CLLocationManagerDelegate {

    weak var handleMapSearchDelegate: HandleMapSearch?
    var categories: [[BusinessDetailSearch]] = []
    let locationManager = CLLocationManager()
    var defaults = UserDefaults.standard
    var dataRecieved = 0
    var usedDefaultLocation = false
    var categoriesAliases: [String] = []
    var handle: AuthStateDidChangeListenerHandle?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //tableView.reloadData()
        updateFavorite()
        locationManager.startUpdatingLocation()
        //navigationController?.viewControllers.first?.navigationItem.rightBarButtonItem = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.viewControllers.first?.navigationItem.leftBarButtonItems?.removeAll{$0.title == "Filter"}
        locationManager.stopUpdatingLocation()
    }
    func configureRefreshControl () {
        // Add the refresh control to your UIScrollView object.
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        makeNewRequest()
        //tableView.reloadData()
    }
    @objc func filterButtonAction() {
        let didBuyCustomNearby = defaults.bool(forKey: "didBuyCustomNearbyIAP")
        if didBuyCustomNearby {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "nearbyCategory") as! NearbyCategoryViewController
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "store") as! StoreViewController
            vc.modalPresentationStyle = .fullScreen
            vc.howIsComing = HowIsComingToStore.nearbyFromFilterPressed
            self.present(vc, animated: true, completion: nil)
        }
    }
    @objc func makeNewRequestWithResetCategories() {
        makeNewRequest()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.viewControllers.first?.navigationItem.titleView?.isHidden = true
        navigationController?.viewControllers.first?.navigationItem.titleView = nil
        navigationController?.viewControllers.first?.navigationItem.title = tabBarController?.tabBar.selectedItem?.title
        
        let filterButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterButtonAction))
        filterButton.image = UIImage(systemName: "slider.horizontal.3")
        navigationController?.viewControllers.first?.navigationItem.leftBarButtonItems?.append(filterButton)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        handle = Auth.auth().addStateDidChangeListener { [self] auth, user in
            if locationManager.authorizationStatus == .restricted || locationManager.authorizationStatus == .notDetermined || locationManager.authorizationStatus == .denied {
                usedDefaultLocation = true
            }
            makeNewRequest()
        }
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = 200
        tableView.sectionHeaderTopPadding = 0
        configureRefreshControl()
        NotificationCenter.default.addObserver(self, selector: #selector(makeNewRequestWithResetCategories), name: NSNotification.Name(rawValue: "RequestNewDataNearbyVC"), object: nil)
    }
    func updateFavorite() {
        if categories.count == 0 {
            return
        }
        for section1 in 0..<categories.count - 1 {
            let amount = categories[section1].count
            for row1 in 0..<amount {
                let indexPath1 = IndexPath(row: row1, section: section1)
                guard let cell = tableView.cellForRow(at: indexPath1) as? NearbyTableViewCell else {
                    return
                }
                cell.setUpFavoriteLabel()
            }
        }
    }
    func makeNewRequest()  {
        dataRecieved = 0
        categories.removeAll()
        self.tableView.reloadData()
        if let checkmarkedCategories = defaults.array(forKey: "nearbyCategoriesSelected") as? [String] {
            categoriesAliases = checkmarkedCategories
        } else {
            let defaultCategories = ["coffee","desserts","newamerican","chinese","italian","mexican"]
            let defaultCategoriesTitles = ["Coffee & Tea","Desserts","American (New)","Chinese","Italian","Mexican"]
            defaults.set(defaultCategories, forKey: "nearbyCategoriesSelected")
            defaults.set(defaultCategoriesTitles, forKey: "nearbyCategoriesSelectedTitle")
            categoriesAliases = defaultCategories
        }
        
        
        
        var coords = CLLocationCoordinate2D()
        let currentLocationMethod = LocalData.CurrentLocationMethodInfo.first!
        let methodOfLocation = currentLocationMethod.currentLocationMethod
        if methodOfLocation == 0 {
            coords.latitude = locationManager.location?.coordinate.latitude ?? Defualts.locationDefaults.latitude
            coords.longitude = locationManager.location?.coordinate.longitude ?? Defualts.locationDefaults.longitude
        } else if methodOfLocation == 1 {
            coords = Defualts.locationDefaults
        } else if methodOfLocation == 2 {
            coords = CLLocationCoordinate2D(latitude: currentLocationMethod.latitude!, longitude: currentLocationMethod.longitude!)
        }
        
        
        
        let longitude = coords.longitude
        let latitude = coords.latitude
        for _ in categoriesAliases {
            categories.append([])
        }
        for x in 0..<categoriesAliases.count {
            let businessesRequest1 = SearchRequest(longitude: "\(longitude)", latitude: "\(latitude)", category: categoriesAliases[x])
            businessesRequest1.getBusinesses { [weak self] result in
                switch result {
                case .failure(let error):
                    Logger().error("\(error.localizedDescription)")
                case .success(let request):
                    let businesses = request.businesses
                    self?.categories[x] = businesses
                    //self?.reloadTableView()
                    DispatchQueue.main.async {
                        self?.reloadTableView()
                    }
                }
            }
        }
    }
    func reloadTableView() {
        dataRecieved += 1
        if dataRecieved == categoriesAliases.count {
            tableView.reloadData()
            dataRecieved = 0
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
            }

        }
    }
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return categoriesAliases.count
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if categories[indexPath.section].count == 0 || categories[indexPath.section].isEmpty {
            return 216.0
        }
        return 80.0
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < (categories.count) {
            if categories[section].count == 0 {
                return 1
            }
            return categories[section].count
        }
        return 1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let checkmarkedCategories = defaults.array(forKey: "nearbyCategoriesSelectedTitle") as? [String?] else {
            return ""
        }
        if section >= checkmarkedCategories.count {
            return ""
        }
        guard let category = checkmarkedCategories[section] else {
            return ""
        }
        return category
    }    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var matchingItems: [BusinessDetailSearch?] = []
        matchingItems = categories[indexPath.section]
        if matchingItems.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nothingHere", for: indexPath) as! NothingHereTableViewCell
            return cell
        }
        guard let business = matchingItems[indexPath.row] else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nothingHere", for: indexPath) as! NothingHereTableViewCell
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyTableViewCell", for: indexPath) as! NearbyTableViewCell
        if indexPath.row >= matchingItems.count {
            cell.name.text = "No Business Found Please Try New Search"
            cell.distance.text = .none
            cell.address.text = .none
            cell.price.text = .none
            cell.rating.text = .none
            return cell
        }
        cell.business = business
        cell.name.text = business.name
        cell.distance.text = .none
        cell.businessImage.image = UIImage(systemName: "photo.fill")
        if let businessImage = business.image_url {
            if let businessURL = URL(string: businessImage) {
                cell.businessImage.downloaded(from: businessURL)
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
                cell.businessImage.isUserInteractionEnabled = true
                cell.businessImage.addGestureRecognizer(tapGestureRecognizer)
            }
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
        
        cell.setUpIWantToTry()
        cell.setUpFavoriteLabel()
        cell.userLocation = locationManager.location
        cell.setUpDistance()
        cell.price.textColor = .systemGreen
        starAttachmnet.image = UIImage(systemName: "star.fill", withConfiguration: starCongifuration)
        let starString = NSMutableAttributedString(attachment: starAttachmnet)
        let textString = NSMutableAttributedString(string: " \(business.rating)/5")
        textString.append(starString)
        cell.rating.attributedText = textString
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        if categories[indexPath.section].isEmpty || categories[indexPath.section].count == 0 {
            return
        }
        */
        guard let cell = tableView.cellForRow(at: indexPath) as? NearbyTableViewCell? else {
            return
        }
        let business = cell?.business
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(toMapView(_:)), userInfo: ["business": business], repeats: false)
    }
    @objc func toMapView(_ sender: NSNotification) {
        tabBarController?.selectedIndex = 2
        let business = sender.userInfo!["business"] as! BusinessDetailSearch
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "travelingWithIDToMapViewSearch"), object: nil, userInfo: ["business": business])
        
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
    deinit {
        Logger().info("NearbyTableView did deinit")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if categories.isEmpty || defaults.bool(forKey: "updateBusinessesWhenMoving") || usedDefaultLocation {
            makeNewRequest()
            usedDefaultLocation = false
            Logger().info("did update location")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}
