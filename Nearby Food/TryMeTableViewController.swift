//
//  TryMeTableViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 12/15/21.
//

import UIKit
import MapKit
import Firebase
import OSLog
import FirebaseAuth
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseEmailAuthUI
import FirebaseOAuthUI

class TryMeTableViewController: UITableViewController, CLLocationManagerDelegate {
    let defaults = UserDefaults.standard
    var iWantToTry: [String] = []
    let locationManager = CLLocationManager()
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ref = Database.database().reference()
        ref.keepSynced(true)
        locationManager.startUpdatingLocation()
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.iWantToTry = []
            self.tableView.reloadData()
            if user == auth.currentUser && user != nil{
                let userRef = self.ref.child("users/" + user!.uid)
                userRef.child("iWantToTry").observeSingleEvent(of: .value, with: {
                    (snapshot) in
                    if let iWantToTryArray1 = snapshot.value as? [String] {
                        self.iWantToTry = iWantToTryArray1
                        self.tableView.reloadData()
                    }
                })
            }
        }
        navigationController?.viewControllers.first?.navigationItem.rightBarButtonItem = self.editButtonItem
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //currentCellsCompletedLoading = 0
        locationManager.stopUpdatingLocation()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.viewControllers.first?.navigationItem.titleView?.isHidden = true
        navigationController?.viewControllers.first?.navigationItem.titleView = nil
        navigationController?.viewControllers.first?.navigationItem.title = tabBarController?.tabBar.selectedItem?.title
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    override func viewDidLoad() {
        //give a recommended options to add to favorites.
        super.viewDidLoad()
        //NotificationCenter.default.addObserver(self, selector: #selector(addOnetoCompletedCell), name: NSNotification.Name(rawValue: "tryMeAddOneToCompletedCell"), object: nil)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.distanceFilter = 200
        locationManager.startUpdatingLocation()
        //super.isEditing = false
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if iWantToTry.isEmpty || iWantToTry.count == 0 {
            return 1
        }
        return iWantToTry.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if iWantToTry.isEmpty || iWantToTry.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nothingHere", for: indexPath) as! NothingHereTableViewCell
            if Auth.auth().currentUser == nil {
                cell.nothingHerelabel.text = "You need to sign in or create an account to put businesses on your Try Me list!"
                cell.nothingHereLogInCreateButton.isHidden = false
                cell.nothingHereLogInCreateButton.addTarget(self, action: #selector(goToLogInCreateAccountView), for: .touchUpInside)
            } else {
                cell.nothingHerelabel.text = " Use the Map or Nearby tab to find a place to try!"
                cell.nothingHereLogInCreateButton.isHidden = true
                cell.nothingHereLogInCreateButton.removeTarget(self, action: nil, for: .allEvents)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TryMeTableViewCell", for: indexPath) as! TryMeTableViewCell
        cell.businessID = iWantToTry[indexPath.row]
        cell.userLocation = locationManager.location
        cell.findBusiness()
        cell.isHidden = true
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if iWantToTry.isEmpty || iWantToTry.count == 0 {
            return 245.0
        }
        return 121.0
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if iWantToTry.isEmpty || iWantToTry.count == 0 {
            return false
        }
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if iWantToTry.isEmpty || iWantToTry.count == 0 {
            return
        }
        if editingStyle == .delete {
            // Delete the row from the data source
            iWantToTry.remove(at: indexPath.row)
            if let user = Auth.auth().currentUser {
                let userRef = ref.child("users/" + user.uid)
                userRef.child("iWantToTry").setValue(iWantToTry)
                defaults.set(iWantToTry, forKey: "iWantToTryLocal")
                
            }
            if iWantToTry.count == 0 || iWantToTry.isEmpty {
                tableView.reloadData()
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
            
    }
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if iWantToTry.isEmpty || iWantToTry.count == 0 {
            return
        }
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("iWantToTry").observeSingleEvent(of: .value, with: {
                (snapshot) in
                if let iWantToTryArray1 = snapshot.value as? [String] {
                    self.iWantToTry = iWantToTryArray1
                }
            })
        } 
        let cell = tableView.cellForRow(at: indexPath) as! TryMeTableViewCell?
        let business = cell?.business
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(toMapView(_:)), userInfo: ["business": business], repeats: false)
    }
    /*
    @objc func addOnetoCompletedCell() {
        let indexPath1 = IndexPath(row: currentCellsCompletedLoading, section: 0)
        let cell = tableView.cellForRow(at: indexPath1)
        cell?.isHidden = false
        currentCellsCompletedLoading += 1
        if currentCellsCompletedLoading == iWantToTry.count {
            currentCellsCompletedLoading = 0
        }
    }
     */
    @objc func toMapView(_ sender: NSNotification) {
        tabBarController?.selectedIndex = 2
        let business = sender.userInfo!["business"] as! BusinessDetail
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "travelingWithIDToMapView"), object: nil, userInfo: ["business": business])
        
    }
    fileprivate(set) var customAuthUIDelegate: FUIAuthDelegate = FUICustomAuthDelegate()
    @objc func goToLogInCreateAccountView() {
        let authUI = FUIAuth.defaultAuthUI()!
        authUI.delegate = customAuthUIDelegate
        authUI.privacyPolicyURL = URL(string: "https://www.google.com")
        authUI.tosurl = URL(string: "https://www.google.com")
        let googleAuthProvider = FUIGoogleAuth(authUI: authUI)
        let appleProvider = FUIOAuth.appleAuthProvider()
        let authProviders: [FUIAuthProvider] = [googleAuthProvider,FUIEmailAuth(), appleProvider]
        authUI.providers = authProviders
        let authViewController = authUI.authViewController()
        authViewController.modalPresentationStyle = .overFullScreen
        self.present(authViewController, animated: true, completion: nil)
    }
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }
    override func setEditing (_ editing:Bool, animated:Bool) {
        super.setEditing(editing,animated:animated)
        if(self.isEditing) {
            self.editButtonItem.title = "Done"
            //self.isEditing = false
        } else {
            self.editButtonItem.title = "Edit"
            //self.isEditing = true
        }
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
}
