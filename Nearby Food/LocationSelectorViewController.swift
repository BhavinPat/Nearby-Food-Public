//
//  LocationSelectorViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 8/8/22.
//
import MapKit
import CoreLocationUI
import CoreLocation
import UIKit
import Contacts

class LocationSelectorViewController: UIViewController {
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var enterLocationTextField: UITextField! {
        didSet {
            
            
            let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            toolbar.barStyle = .default
            toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                UIBarButtonItem(title: "Default Location", style: .plain, target: self, action: #selector(self.defaultLocation(_:)))
            ]
            toolbar.sizeToFit()
            
            
            
            /*
            let ViewForDoneButtonOnKeyboard = UIToolbar()
            ViewForDoneButtonOnKeyboard.sizeToFit()
            let btnDoneOnKeyboard = UIBarButtonItem(title: "Default Location", style: .plain, target: self, action: #selector(self.defaultLocation(_:)))
            ViewForDoneButtonOnKeyboard.items = [btnDoneOnKeyboard]
             */
            enterLocationTextField.inputAccessoryView = toolbar
        }
    }
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let defaults = UserDefaults.standard
    //var currentPinLocation = CLLocationCoordinate2D()
    var currentMapPin: MKPointAnnotation!
    override func viewDidLoad() {
        super.viewDidLoad()
        enterLocationTextField.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        mapView.delegate = self
        setUpPin()

        let currentLocationMethod = LocalData.CurrentLocationMethodInfo.first!
        let methodOfLocation = currentLocationMethod.currentLocationMethod
        if methodOfLocation == 0 {
            currentLocationAction(UIButton())
        } else if methodOfLocation == 1 {
            defaultLocation(UIButton())
        } else if methodOfLocation == 2 {
            var coords = CLLocationCoordinate2D()
            coords = CLLocationCoordinate2D(latitude: currentLocationMethod.latitude!, longitude: currentLocationMethod.longitude!)
            mapView.setRegion(MKCoordinateRegion(center: coords, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: true)
        }
        
        
        /*
        if currentMethodOfLocation == .willisTower {
            setUpDefaultRegion()
            currentPinLocation = Defualts.locationDefaults
        } else if currentMethodOfLocation == .current {
            currentLocationAction(UIButton())
            currentPinLocation = locationManager.location?.coordinate ?? Defualts.locationDefaults
        } else if currentMethodOfLocation == .custom {
            let dict = ["MethodOfLocation": 0, "LocationCoord": Defualts.locationDefaults] as [String : Any]
            UserDefaults.standard.set(dict, forKey: "currentMethodOfLocationInfo")
        }
         */
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    @IBAction func doneButtonAction(_ sender: UIButton) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RequestNewDataNearbyVC"), object: nil, userInfo: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "makeCollectionViewCallToYelp"), object: nil, userInfo: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLocationUsedTitle"), object: nil, userInfo: nil)
        self.dismiss(animated: true)
    }

    @IBAction func defaultLocation(_ sender: UIButton!) {
        let location = Defualts.locationDefaults
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: Defualts.locationDefaults.latitude, longitude: Defualts.locationDefaults.longitude, currentLocationMethod: 1)]
        LocalData.CurrentLocationMethodInfo = dict
        if let annotation = mapView.annotations.first(where: {$0.title == "Location being used"}) {
            mapView.removeAnnotation(annotation)
            setUpPin()
        }
        enterLocationTextField.resignFirstResponder()

    }
    @IBAction func currentLocationAction(_ sender: UIButton!) {
        guard let location = locationManager.location?.coordinate else {
            let alert = UIAlertController(title: "Current Location Missing", message: "Nearby Food is unable to get your location. Go to settings to enable location.", preferredStyle: .alert)
            let OK = UIAlertAction(title: "OK", style: .cancel)
            let settings = UIAlertAction(title: "Settings", style: .default, handler: {
                _ in
                if let url = URL.init(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
            alert.addAction(settings)
            alert.addAction(OK)
            self.present(alert, animated: true)
            return
        }
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        
        let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: location.latitude, longitude: location.longitude, currentLocationMethod: 0)]
        LocalData.CurrentLocationMethodInfo = dict
        if let annotation = mapView.annotations.first(where: {$0.title == "Location being used"}) {
            mapView.removeAnnotation(annotation)
            setUpPin()
        }
        
        
        //let dict = ["MethodOfLocation": 0, "LocationCoord": location] as [String : Any]
        //UserDefaults.standard.set(dict, forKey: "currentMethodOfLocationInfo")
    }
    /*
    func setUpDefaultRegion() {
        let region = MKCoordinateRegion(center: Defualts.locationDefaults, latitudinalMeters: CLLocationDistance(1000), longitudinalMeters: CLLocationDistance(1000))
        mapView.setRegion(region, animated: false)
    }
     */
    func setUpPin() {
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
        
        
        
        
        currentMapPin = MKPointAnnotation()
        currentMapPin.coordinate = coords
        currentMapPin.title = "Location being used"
        mapView.addAnnotation(currentMapPin)
        
    }
}
extension LocationSelectorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        let geocoder = CLGeocoder()
        let postalAddress = CNMutablePostalAddress()
        guard let text = enterLocationTextField.text else {
            return
        }
        postalAddress.postalCode = text
        geocoder.geocodePostalAddress(postalAddress, completionHandler: { [self]
            geo, error in
            if let e = error as? NSError {
                let alert = UIAlertController(title: "Error", message: "\(e.domain)", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default)
                alert.addAction(ok)
                self.present(alert, animated: true)
            } else {
                let placemark = geo!.first!
                let region = MKCoordinateRegion(center: placemark.location?.coordinate ?? Defualts.locationDefaults, latitudinalMeters: 1000, longitudinalMeters: 1000)
                mapView.setRegion(region, animated: true)
                let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: placemark.location!.coordinate.latitude, longitude: placemark.location!.coordinate.longitude, currentLocationMethod: 2)]
                LocalData.CurrentLocationMethodInfo = dict
                setUpPin()
            }
        })
    }
}

extension LocationSelectorViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let methodOfLocation = LocalData.CurrentLocationMethodInfo.first!.currentLocationMethod!
        if methodOfLocation == 0 {
            currentLocationAction(UIButton())
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}

extension LocationSelectorViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil }
        /*
        let pin = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "currentLocationUsed")
        pin.isDraggable = true
        pin.tintColor = .red
        pin.animatesWhenAdded = true
        return pin
        */
        
        
        let identifier = "currentLocationUsed"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if (annotationView == nil) {
            annotationView = MKMarkerAnnotationView(annotation: annotation,reuseIdentifier: identifier)
            if let av = annotationView {
                av.tintColor = .red;
                av.animatesWhenAdded = false
                av.canShowCallout = true
                av.isDraggable = true
            } else {
                return nil
            }
        } else {
            annotationView!.annotation = annotation
         }
         return annotationView
         
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if let annotation = mapView.annotations.first(where: {$0.title == "Location being used"}) {
            let dict: [CurrentLocationInfo] = [CurrentLocationInfo(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, currentLocationMethod: 2)]
            LocalData.CurrentLocationMethodInfo = dict
        }
    }
}
