//
//  HomeViewController.swift
//  Nearby Food
//
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/2/21.
//

import UIKit
import MapKit
import FirebaseAnalytics
import OSLog
import FirebaseAuth

class HomeViewController: UIViewController {
    @IBOutlet weak var randomCollectioView: UICollectionView!
    @IBOutlet weak var highRatingCollectioView: UICollectionView!
    @IBOutlet weak var openRightNowCollectioView: UICollectionView!
    @IBOutlet weak var randomLabel: UILabel!
    @IBOutlet weak var highRatingLabel: UILabel!
    @IBOutlet weak var openLabel: UILabel!
    var usedDefaultLocation = false
    var handle: AuthStateDidChangeListenerHandle?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation()
        //navigationController?.viewControllers.first?.navigationItem.rightBarButtonItem = nil
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.viewControllers.first?.navigationItem.titleView?.isHidden = true
        navigationController?.viewControllers.first?.navigationItem.titleView = nil
        navigationController?.viewControllers.first?.navigationItem.title = tabBarController?.tabBar.selectedItem?.title
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        StoreReviewHelper.checkAndAskForReview()
        StoreManager.shared.Begin()
        AllCategoryAvailable.shared.Begin()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.distanceFilter = 200
        locationManager.startUpdatingLocation()
        randomCollectioView.dataSource = self
        randomCollectioView.delegate = self
        highRatingCollectioView.dataSource = self
        highRatingCollectioView.delegate = self
        openRightNowCollectioView.dataSource = self
        openRightNowCollectioView.delegate = self
        handle = Auth.auth().addStateDidChangeListener { [self] auth, user in
            if locationManager.authorizationStatus == .restricted || locationManager.authorizationStatus == .notDetermined || locationManager.authorizationStatus == .denied {
                usedDefaultLocation = true
            }
            makeCollectionViewCallToYelp()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(makeCollectionViewCallToYelp), name: NSNotification.Name(rawValue: "makeCollectionViewCallToYelp"), object: nil)
    }
    
    deinit {
        Logger().info("HomeViewController did deinit")
    }
    
    var randomBusinesses: [BusinessDetailSearch] = []
    var highestRatedBusinesses: [BusinessDetailSearch] = []
    var openRightNowBusinesses: [BusinessDetailSearch] = []
    let defaults = UserDefaults.standard
    let locationManager = CLLocationManager()
    @objc func makeCollectionViewCallToYelp() {
        if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
            if LocalData.CurrentLocationMethodInfo.isEmpty {
                let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: 0, longitude: 0, currentLocationMethod: 0)]
                LocalData.CurrentLocationMethodInfo = dict
            }
        } else {
            if LocalData.CurrentLocationMethodInfo.isEmpty {
                let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: Defualts.locationDefaults.latitude, longitude: Defualts.locationDefaults.longitude, currentLocationMethod: 1)]
                LocalData.CurrentLocationMethodInfo = dict
            }
        }
        randomBusinesses.removeAll()
        highestRatedBusinesses.removeAll()
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
        let businessesRequest = SearchRequest(longitude: String(coords.longitude), latitude: String(coords.latitude), isHome: true)
        businessesRequest.getBusinesses { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
            case .success(let request):
                let businesses = request.businesses
                //do choosing
                self?.doRandomChoosing(businesses: businesses)
                self?.doHighestRatedChoosing(businesses: businesses)
            }
        }
        
        let openBusinessesRequest = SearchRequest(longitude: String(coords.longitude), latitude: String(coords.latitude), open: true)
        openBusinessesRequest.getBusinesses { [weak self] result in
            switch result {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
            case .success(let request):
                //do choosing
                let businesses = request.businesses
                self?.doOpenNowChoosing(businesses: businesses)
            }
        }
        
    }
    func doRandomChoosing(businesses: [BusinessDetailSearch]) {
        randomBusinesses.removeAll()
        var businesses1 = businesses
        for _ in 0..<businesses.count {
            if businesses1.isEmpty {
                return
            }
            let randomInt = Int.random(in: 0..<businesses1.count)
            randomBusinesses.append(businesses1[randomInt])
            businesses1.remove(at: randomInt)
        }
        DispatchQueue.main.async { [self] in
            randomCollectioView.reloadData()
        }
    }
    func doOpenNowChoosing(businesses: [BusinessDetailSearch]) {
        openRightNowBusinesses.removeAll()
        openRightNowBusinesses = businesses
        DispatchQueue.main.async { [self] in
            openRightNowCollectioView.reloadData()
        }
    }
    func doHighestRatedChoosing(businesses: [BusinessDetailSearch]) {
        //need algoritm that finds highest rated
        highestRatedBusinesses.removeAll()
        guard businesses.count > 1 else {
            highestRatedBusinesses = businesses
            DispatchQueue.main.async { [self] in
                highRatingCollectioView.reloadData()
            }
            return
        }
        //var sortedArray = businesses
        /*
        for var index in 1..<sortedArray.count {
            let temp = sortedArray[index]
            while index > 0, temp.rating > sortedArray[index - 1].rating {
                sortedArray[index].rating = sortedArray[index - 1].rating
                index -= 1
            }
            sortedArray[index] = temp
        }
         */
        //highestRatedBusinesses = sortedArray
        
        
        
        let sortedObjects = businesses.sorted { (lhs, rhs) in
            if lhs.rating == rhs.rating { // <1>
                return lhs.review_count > rhs.review_count
            }
            
            return lhs.rating > rhs.rating // <2>
        }
        highestRatedBusinesses = sortedObjects
        
        DispatchQueue.main.async { [self] in
            highRatingCollectioView.reloadData()
        }
    }
}
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            //random
            if randomBusinesses.isEmpty || randomBusinesses.count == 0 {
                return 1
            }
            return randomBusinesses.count
        } else if collectionView.tag == 1 {
            //highest Rating
            if highestRatedBusinesses.isEmpty || highestRatedBusinesses.count == 0 {
                return 1
            }
            return highestRatedBusinesses.count
        } else if collectionView.tag == 2 {
            //highest Rating
            if openRightNowBusinesses.isEmpty || openRightNowBusinesses.count == 0 {
                return 1
            }
            return openRightNowBusinesses.count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 0 {
            if indexPath.row >= randomBusinesses.count {
                let cell = randomCollectioView.dequeueReusableCell(withReuseIdentifier: "nothingHere", for: indexPath) as! NothingHereCollectionViewCell
                return cell
            }
            let cell = randomCollectioView.dequeueReusableCell(withReuseIdentifier: "randomCollectionViewCell", for: indexPath) as! HomeCollectionViewCell
            cell.layer.masksToBounds = true
            cell.layer.cornerRadius = 6.5
            let business = randomBusinesses[indexPath.row]
            cell.business = business
            cell.businessID = business.id
            cell.setUpView()
            cell.businessTitle.text = business.name
            if let url = business.image_url {
                cell.businessImage.downloaded(from: url)
            }
            return cell
        } else if collectionView.tag == 1 {
            if indexPath.row >= highestRatedBusinesses.count {
                let cell = highRatingCollectioView.dequeueReusableCell(withReuseIdentifier: "nothingHere", for: indexPath) as! NothingHereCollectionViewCell
                return cell
            }
            let cell = highRatingCollectioView.dequeueReusableCell(withReuseIdentifier: "highStarCollectionViewCell", for: indexPath) as! HomeCollectionViewCell
            cell.layer.masksToBounds = true
            cell.layer.cornerRadius = 6.5
            let business = highestRatedBusinesses[indexPath.row]
            cell.business = business
            cell.businessID = business.id
            cell.setUpView()
            cell.businessTitle.text = business.name
            if let url = business.image_url {
                cell.businessImage.downloaded(from: url)
            }
            return cell
        } else if collectionView.tag == 2 {
            if indexPath.row >= openRightNowBusinesses.count {
                let cell = openRightNowCollectioView.dequeueReusableCell(withReuseIdentifier: "nothingHere", for: indexPath) as! NothingHereCollectionViewCell
                return cell
            }
            
            
            let cell = openRightNowCollectioView.dequeueReusableCell(withReuseIdentifier: "openRightNowCollectionViewCell", for: indexPath) as! HomeCollectionViewCell
            cell.layer.masksToBounds = true
            cell.layer.cornerRadius = 6.5
            let business = openRightNowBusinesses[indexPath.row]
            cell.business = business
            cell.businessID = business.id
            cell.setUpView()
            cell.businessTitle.text = business.name
            if let url = business.image_url {
                cell.businessImage.downloaded(from: url)
            }
            return cell
        } else {
           return UICollectionViewCell()
        }
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? HomeCollectionViewCell? else {
            return
        }
        guard let business = cell?.business else {
            return
        }
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(toMapView(_:)), userInfo: ["business": business], repeats: false)
    }
    @objc func toMapView(_ sender: NSNotification) {
        tabBarController?.selectedIndex = 2
        let business = sender.userInfo!["business"] as! BusinessDetailSearch
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "travelingWithIDToMapViewSearch"), object: nil, userInfo: ["business": business])
        
    }
    
    
}
extension HomeViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if locationManager.authorizationStatus == .restricted || locationManager.authorizationStatus == .notDetermined || locationManager.authorizationStatus == .denied {
        } else {
            makeCollectionViewCallToYelp()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if randomBusinesses.isEmpty || defaults.bool(forKey: "updateBusinessesWhenMoving") || usedDefaultLocation {
            makeCollectionViewCallToYelp()
            usedDefaultLocation = false
            Logger().info("did update location")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger().error("\(error.localizedDescription)")
    }
}
