//
//  MapViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/2/21.
//

import UIKit
import MapKit
import FirebaseAnalytics
import OSLog
protocol HandleMapSearch: AnyObject {
    func dropPinZoomIn(business: BusinessDetailSearch)
    func dropPin(business: BusinessDetailSearch)
    func dropPinZoomInWithDetail(business: BusinessDetail)
}

class MapViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var filterBlurScreen: UIVisualEffectView!
    let locationManager = CLLocationManager()
    var selectedPin: MKPlacemark?
    var resultSearchController: UISearchController!
    var region = MKCoordinateRegion()
    var startLocation = false
    var mapViewDetail: MapDetailView!
    var searchBar1: UISearchBar!
    var locationSearchTable: LocationSearchTable!
    var isThereBusiness = false
    var annotationPin: MKPointAnnotationBusinessSearch!
    weak var handleMapSearchDelegate: HandleMapSearch?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if mapViewDetail != nil && mapViewDetail.business != nil {
            mapViewDetail.isHidden = false
        }
        self.navigationController?.viewControllers.first?.navigationItem.rightBarButtonItem = nil
        self.navigationController?.viewControllers.first?.navigationItem.titleView = self.searchBar1
        self.navigationController?.viewControllers.first?.navigationItem.titleView?.isHidden = false
        self.locationManager.startUpdatingLocation()
        self.locationManager.requestLocation()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.mapViewDetail.isHidden = true
        locationManager.stopUpdatingLocation()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        setUpDefaultRegion()
        locationManager.distanceFilter = 200
        locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as? LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        resultSearchController.delegate = self
        //resultSearchController.searchResultsController = locatio
        //resultSearchController.searchBar.delegate = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        searchBar.searchTextField.clearButtonMode = .whileEditing
        //searchBar.searchTextField.addDoneButtonOnKeyboard()
        navigationController?.viewControllers.first?.navigationItem.titleView = searchBar
        searchBar1 = searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        mapView.pointOfInterestFilter = .excludingAll
        locationSearchTable.mapView = self.mapView
        locationSearchTable.handleMapSearchDelegate = self
        handleMapSearchDelegate = self
        let mapDetailView = MapDetailView()
        self.view.addSubview(mapDetailView)
        filterBlurScreen.isHidden = true
        mapDetailView.translatesAutoresizingMaskIntoConstraints = false
        mapDetailView.isHidden = false
        NSLayoutConstraint.activate([
            //mapDetailView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mapDetailView.heightAnchor.constraint(equalToConstant: 400),
            mapDetailView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            mapDetailView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            //mapDetailView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            mapDetailView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(closeFilterVC), name: NSNotification.Name(rawValue: "searchFilterBackToMap"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentMapDetailWithID(_:)), name: NSNotification.Name(rawValue: "travelingWithIDToMapView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentMapDetailWithIDSearch(_:)), name: NSNotification.Name(rawValue: "travelingWithIDToMapViewSearch"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nearbyFromSearchTable(_:)), name: NSNotification.Name(rawValue: "nearbyFromSearchTable"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareBusinessPressed(_:)), name: NSNotification.Name(rawValue: "shareBusinessButtonPressed"), object: nil)
        mapDetailView.mapDetailView.layer.masksToBounds = true
        mapDetailView.mapDetailView.layer.cornerRadius = 10
        self.mapViewDetail = mapDetailView
        self.mapViewDetail.isHidden = true
        self.mapViewDetail.layer.masksToBounds = true
    }
    @objc func presentMapDetailWithID(_ sender: NSNotification) {
        let business1 = (sender.userInfo!["business"] as! BusinessDetail)
        let id = business1.id
        checkIDs(id: id, business1: business1)
    }
    @objc func presentMapDetailWithIDSearch(_ sender: NSNotification) {
        let business1 = (sender.userInfo!["business"] as! BusinessDetailSearch)
        let id = business1.id
        checkIDs(id: id, business1: business1)
    }
    @objc func shareBusinessPressed(_ sender: NSNotification) {
        let url = sender.userInfo!["urlToBus"] as! URL
        let sharedObjects:[AnyObject] = [url as AnyObject]
        let activityViewController = UIActivityViewController(activityItems : sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = mapViewDetail
        self.present(activityViewController, animated: true)
    }
    func checkIDs(id: String, business1: BusinessDetail) {
        var strings1: [String] = []
        for mapAnnoView in mapView.annotations {
            if let mapAnnoView1 = mapAnnoView as? MKPointAnnotationBusinessSearch {
                let mapAnnoView1IDdetail = mapAnnoView1.businessDetail?.id ?? ""
                let mapAnnoView1IDsearch = mapAnnoView1.businessDetailSearch?.id ?? ""
                strings1.append(mapAnnoView1IDdetail)
                strings1.append(mapAnnoView1IDsearch)
            }
        }
        if !strings1.contains(id) {
            handleMapSearchDelegate?.dropPinZoomInWithDetail(business: business1)
        }
    }
    func setUpDefaultRegion() {
        let region = MKCoordinateRegion(center: Defualts.locationDefaults, latitudinalMeters: CLLocationDistance(1000), longitudinalMeters: CLLocationDistance(1000))
        self.region = region
        
        mapView.setRegion(region, animated: false)
    }
    func checkIDs(id: String, business1: BusinessDetailSearch) {
        var strings1: [String] = []
        for mapAnnoView in mapView.annotations {
            if let mapAnnoView1 = mapAnnoView as? MKPointAnnotationBusinessSearch {
                let mapAnnoView1IDdetail = mapAnnoView1.businessDetail?.id ?? ""
                let mapAnnoView1IDsearch = mapAnnoView1.businessDetailSearch?.id ?? ""
                strings1.append(mapAnnoView1IDdetail)
                strings1.append(mapAnnoView1IDsearch)
            }
        }
        if !strings1.contains(id) {
            handleMapSearchDelegate?.dropPinZoomIn(business: business1)
        }
    }
    @objc func getDirections(){
        //make a search request. get list. then see if list can match address and or name with each other then return point
        makeSearchrequest()
        
    }
    func makeSearchrequest() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = mapViewDetail.business.name
        request.region = mapView.region
        request.pointOfInterestFilter = .includingAll
        let search = MKLocalSearch(request: request)
        search.start { [self] responce, _ in
            guard let responce = responce else {
                return
            }
            handleMapItem(responce: responce)
        }
    }
    func handleMapItem(responce: MKLocalSearch.Response) {
        //when sure selects any pin the selectedPin gets set to that business. use the business id in the ResueIdent pin thing idk
        let placeItem = mapItemResponces(responce1: responce)
        guard let selectedPin = selectedPin else { return }
        var mapItem: MKMapItem!
        guard let placeItem = placeItem else {
            mapItem = MKMapItem(placemark: selectedPin)
            return
        }
        mapItem = placeItem
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    func mapItemResponces(responce1: MKLocalSearch.Response) -> MKMapItem? {
        for place in responce1.mapItems {
            let namePercentage = JaroSimilarity.shared.jaroWinkler(place.name ?? "", mapViewDetail.business.name)
            if namePercentage >= 0.85 {
                return place
            }
            let phonePercentage = JaroSimilarity.shared.jaroWinkler(place.phoneNumber ?? "", mapViewDetail.business.phone ?? "555555")
            if phonePercentage >= 0.85 {
                return place
            }
            let firstLine = "\(place.placemark.subThoroughfare ?? "") \(place.placemark.thoroughfare ?? "")"
            let firstLinePercentage = JaroSimilarity.shared.jaroWinkler(firstLine, mapViewDetail.business.location.address1 ?? "")
            if firstLinePercentage >= 0.85 {
                return place
            }
            let placeLongString: String = String(place.placemark.location?.coordinate.longitude ?? 0.0)
            let busLongString: String = String(mapViewDetail.business.coordinates.longitude)
            let placeLatString: String = String(place.placemark.location?.coordinate.latitude ?? 0.0)
            let busLatString: String = String(mapViewDetail.business.coordinates.latitude)
            let longPercentage = JaroSimilarity.shared.jaroWinkler(placeLongString, busLongString)
            let latPercentage = JaroSimilarity.shared.jaroWinkler(placeLatString, busLatString)
            if longPercentage >= 0.85 {
                return place
            }
            if latPercentage >= 0.85 {
                return place
            }
        }
        return nil
    }
    @objc func closeFilterVC() {
        navigationController?.viewControllers.first?.navigationItem.title = nil
        navigationController?.viewControllers.first?.navigationItem.titleView = searchBar1
        filterBlurScreen.fadeOut()
    }
    @objc func nearbyFromSearchTable(_ sender: NSNotification) {
        mapView.removeAnnotations(mapView.annotations)
        let searchItems = sender.userInfo!["businesses"] as! [BusinessDetailSearch]
        for searchItem in searchItems {
            dropPin(business: searchItem)
        }
        
        if sender.userInfo!["center"] is CLLocationCoordinate2D {
            let region = MKCoordinateRegion(center: mapView.centerCoordinate, latitudinalMeters: CLLocationDistance(1000), longitudinalMeters: CLLocationDistance(1000))
            mapView.setRegion(region, animated: true)
        }
         
        guard let businessClicked = sender.userInfo!["business"] as? BusinessDetailSearch else {
            return
        }
        
        handleMapSearchDelegate?.dropPinZoomIn(business: businessClicked)
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !startLocation {
            startLocation = true
            if let location = locations.last {
                let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: CLLocationDistance(1000), longitudinalMeters: CLLocationDistance(1000))
                self.region = region
                
                mapView.setRegion(region, animated: false)
            }
        }
        //useless
        if let location = locations.last {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: CLLocationDistance(1000), longitudinalMeters: CLLocationDistance(1000))
            self.region = region
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger().error("\(error.localizedDescription)")
    }
    func degreesToRadians(degree: Double) -> Float{
        return Float((.pi * degree)/180)
    }
    /*
    func spanOfMetersAtDegree(degree: Double, meters: Double) -> Double {
        let tanDegrees = tanf(degreesToRadians(degree: degree))
        let beta = tanDegrees * 0.99664719
        let lengthOfDegree = cos(atan(beta)) * 6378137.0
        let measureInDegreeLength = Double(lengthOfDegree)/meters
        return 1/measureInDegreeLength
    }
     */
    
    deinit {
        Logger().info("map is deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func filterButtonAction(_ sender: UIButton) {
        navigationController?.viewControllers.first?.navigationItem.titleView = nil
        navigationController?.viewControllers.first?.navigationItem.title = "Map"
        filterBlurScreen.fadeIn()
        mapViewDetail.fadeOut()
    }

    
}
extension MapViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        mapViewDetail.fadeOut()
    }
    func didDismissSearchController(_ searchController: UISearchController) {
        if isThereBusiness {
            mapViewDetail.fadeIn()
            mapView.selectAnnotation(annotationPin!, animated: true)
            mapViewDetail.setUpFavoriteButton()
        }
        mapView.removeAnnotations(mapView.annotations)
        NotificationCenter.default.post(name: NSNotification.Name("nearbyFromSearchTable"), object: self, userInfo: ["businesses": locationSearchTable.matchingItems, "center": locationSearchTable.nextSetRegionCenter ?? mapView.centerCoordinate])
        
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        mapViewDetail.fadeOut()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if isThereBusiness {
            mapViewDetail.fadeIn()
            mapView.selectAnnotation(annotationPin!, animated: true)
            mapViewDetail.setUpFavoriteButton()
        }
    }
    
}

extension MapViewController: HandleMapSearch {
    func dropPin(business: BusinessDetailSearch) {
        navigationController?.viewControllers.first?.navigationController?.navigationItem.searchController?.searchBar.resignFirstResponder()
        //let pinPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: business.coordinates.latitude, longitude: business.coordinates.longitude))
        //selectedPin = pinPlacemark
        // clear existing pins
        //mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotationBusinessSearch(business: business)
        let coordinates = CLLocationCoordinate2D(latitude: Double(business.coordinates.latitude), longitude: Double(business.coordinates.longitude))
        annotation.coordinate = coordinates
        annotation.title = business.name
        annotation.isSearch = true
        if let city = business.location.city,
           let state = business.location.state {
            annotation.subtitle = "\(city), \(state)"
        }
        
        //annotationPin = annotation
        mapView.addAnnotation(annotation)
    }
    
    func dropPinZoomIn(business: BusinessDetailSearch) {
        //use this method when user wants to view business from another tab view
        // cache the pin
        navigationController?.viewControllers.first?.navigationController?.navigationItem.searchController?.searchBar.resignFirstResponder()
        //let pinPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: business.coordinates.latitude, longitude: business.coordinates.longitude))
        //selectedPin = pinPlacemark
        // clear existing pins
        //mapView.removeAnnotations(mapView.annotations)
        isThereBusiness = false
        let annotation = MKPointAnnotationBusinessSearch(business: business)
        let coordinates = CLLocationCoordinate2D(latitude: Double(business.coordinates.latitude), longitude: Double(business.coordinates.longitude))
        annotation.coordinate = coordinates
        //annotation.setValue("pin", forKey: "pin")
        annotation.title = business.name
        annotation.isMain = true
        if let city = business.location.city,
           let state = business.location.state {
            annotation.subtitle = "\(city), \(state)"
        }
        annotation.isSearch = true
        self.mapViewDetail.fadeIn()
        self.mapViewDetail.businessSearch = business
        self.mapViewDetail.findBusiness()
        //annotationPin = annotation
        mapView.addAnnotation(annotation)
        isThereBusiness = true
        var region = MKCoordinateRegion(center: coordinates, latitudinalMeters: CLLocationDistance(250), longitudinalMeters: CLLocationDistance(250))
        let newLong = coordinates.latitude - 0.0005
        region.center.latitude = newLong
        mapView.setRegion(region, animated: true)
        
        
    }
    func dropPinZoomInWithDetail(business: BusinessDetail) {
        //use this method when user wants to view business from another tab view
        // cache the pin
        navigationController?.viewControllers.first?.navigationController?.navigationItem.searchController?.searchBar.resignFirstResponder()
        //let pinPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: business.coordinates.latitude, longitude: business.coordinates.longitude))
        //selectedPin = pinPlacemark
        // clear existing pins
        //mapView.removeAnnotations(mapView.annotations)
        isThereBusiness = false
        let annotation = MKPointAnnotationBusinessSearch(business: business)
        let coordinates = CLLocationCoordinate2D(latitude: Double(business.coordinates.latitude), longitude: Double(business.coordinates.longitude))
        annotation.coordinate = coordinates
        //annotation.setValue("pin", forKey: "pin")
        annotation.title = business.name
        if let city = business.location.city,
           let state = business.location.state {
            annotation.subtitle = "\(city), \(state)"
        }
        annotation.isMain = true
        annotation.isSearch = false
        self.mapViewDetail.fadeIn()
        self.mapViewDetail.business = business
        self.mapViewDetail.usersLocation = nil
        if let userLocation = mapView.userLocation.location {
            self.mapViewDetail.usersLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        }
        self.mapViewDetail.setUpBusiness()
        //annotationPin = annotation
        mapView.addAnnotation(annotation)
        isThereBusiness = true
        var region = MKCoordinateRegion(center: coordinates, latitudinalMeters: CLLocationDistance(250), longitudinalMeters: CLLocationDistance(250))
        let newLong = coordinates.latitude - 0.0005
        region.center.latitude = newLong
        mapView.setRegion(region, animated: true)
        
        
    }
    
}
//handle search delege isnt being called? why? well search isnt completed no results
extension MapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            if view.reuseIdentifier == "pin" {
                if let annotation = (view.annotation as? MKPointAnnotationBusinessSearch)  {
                    if annotation.isMain {
                        self.mapView.selectAnnotation(annotation, animated: true)
                    }
                }
            }
        }
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let identifier = view.reuseIdentifier
        if identifier == "pin" {
            annotationPin = (view.annotation as! MKPointAnnotationBusinessSearch)
            let long: CLLocationDegrees = (view.annotation?.coordinate.longitude)!
            let lat: CLLocationDegrees = (view.annotation?.coordinate.latitude)!
            let pinPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
            selectedPin = pinPlacemark
            if annotationPin.isSearch {
                //business search
                mapViewDetail.businessSearch = annotationPin.businessDetailSearch
                mapViewDetail.findBusiness()
            } else {
                mapViewDetail.business = annotationPin.businessDetail
                self.mapViewDetail.usersLocation = nil
                if let userLocation = mapView.userLocation.location {
                    self.mapViewDetail.usersLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
                }
                mapViewDetail.setUpBusiness()
            }
            if mapViewDetail.isHidden {
                self.mapViewDetail.fadeIn()
            } else {
                DispatchQueue.main.async {
                    self.mapViewDetail.layer.removeAllAnimations()
                    self.mapViewDetail.isHidden = false
                    self.mapViewDetail.alpha = 1.0
                }
            }
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        //pinView?.tintColor = 
        pinView?.markerTintColor = .orange
        //pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        pinView?.isHidden = false
        pinView?.animatesWhenAdded = true
        //pinView?.animatesDrop = true
        let smallSquare = CGSize(width: 40, height: 40)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(systemName: "location.north.line.fill"), for: .normal)
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        pinView?.leftCalloutAccessoryView?.sizeThatFits(smallSquare)
        if isThereBusiness {
            self.mapViewDetail.fadeIn()
        }
        
        return pinView
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        let identifier = view.reuseIdentifier ?? ""
        if identifier == "pin" {
            self.mapViewDetail.fadeOut()
        }
    }
}



