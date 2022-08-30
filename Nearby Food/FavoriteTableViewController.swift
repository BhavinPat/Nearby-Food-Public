//
//  FavoriteTableViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/2/21.
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
class FavoriteTableViewController: UITableViewController, CLLocationManagerDelegate {
    let defaults = UserDefaults.standard
    var favorite: [String] = []
    var ref: DatabaseReference!
    let locationManager = CLLocationManager()
    var handle: AuthStateDidChangeListenerHandle?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ref = Database.database().reference()
        ref.keepSynced(true)
        locationManager.startUpdatingLocation()
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.favorite = []
            self.tableView.reloadData()
            if user == auth.currentUser && user != nil{
                let userRef = self.ref.child("users/" + user!.uid + "/favorite")
                userRef.observeSingleEvent(of: .value, with: {
                    snapshot in
                    if let favoriteArray1 = snapshot.value as? [String] {
                        self.favorite = favoriteArray1
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
        //NotificationCenter.default.addObserver(self, selector: #selector(addOnetoCompletedCell), name: NSNotification.Name(rawValue: "favoriteAddOneToCompletedCell"), object: nil)
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
        if favorite.isEmpty || favorite.count == 0 {
            return 1
        }
        return favorite.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if favorite.isEmpty || favorite.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nothingHere", for: indexPath) as! NothingHereTableViewCell
            if Auth.auth().currentUser == nil {
                cell.nothingHerelabel.text = "You need to sign in or create an account to save your favorite businesses!"
                cell.nothingHereLogInCreateButton.isHidden = false
                cell.nothingHereLogInCreateButton.addTarget(self, action: #selector(goToLogInCreateAccountView), for: .touchUpInside)
            } else {
                cell.nothingHerelabel.text = "Use the Map or Nearby tab to find you next favorite place!"
                cell.nothingHereLogInCreateButton.isHidden = true
                cell.nothingHereLogInCreateButton.removeTarget(self, action: nil, for: .allEvents)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "favoriteTableViewCell", for: indexPath) as! FavoriteTableViewCell
        cell.businessID = favorite[indexPath.row]
        cell.userLocation = locationManager.location
        cell.findBusiness()
        cell.isHidden = true
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if favorite.isEmpty || favorite.count == 0 {
            return 245.0
        }
        return 121.0
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if favorite.isEmpty || favorite.count == 0 {
            return false
        }
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if favorite.isEmpty || favorite.count == 0 {
            return
        }
        if editingStyle == .delete {
            // Delete the row from the data source
            favorite.remove(at: indexPath.row)
            if let user = Auth.auth().currentUser {
                let userRef = ref.child("users/" + user.uid)
                userRef.child("favorite").setValue(favorite)
                var communityLoved = 0
                let communityRef = ref.child("communityFavorites/")
                let cell = tableView.cellForRow(at: indexPath) as! FavoriteTableViewCell
                communityRef.child(cell.businessID).observeSingleEvent(of: .value, with: {
                    (snapshot) in
                    let intOfBus = (snapshot.value as? Int) ?? 0
                    communityLoved = intOfBus
                    communityLoved -= 1
                    if communityLoved < 0 {
                        communityLoved = 0
                    }
                    communityRef.child(cell.businessID).setValue(communityLoved)
                })
            }
            
            if favorite.count == 0 || favorite.isEmpty {
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
        if favorite.isEmpty || favorite.count == 0 {
            return
        }
        if let user = Auth.auth().currentUser {
            let userRef = ref.child("users/" + user.uid)
            userRef.child("favorite").observeSingleEvent(of: .value, with: {
                (snapshot) in
                if let favoriteArray1 = snapshot.value as? [String] {
                    self.favorite = favoriteArray1
                }
            })
        }
        
        let cell = tableView.cellForRow(at: indexPath) as! FavoriteTableViewCell?
        let business = cell?.business
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(toMapView(_:)), userInfo: ["business": business], repeats: false)
    }
    /*
    @objc func addOnetoCompletedCell() {
        let indexPath1 = IndexPath(row: currentCellsCompletedLoading, section: 0)
        let cell = tableView.cellForRow(at: indexPath1)
        cell?.isHidden = false
        currentCellsCompletedLoading += 1
        if currentCellsCompletedLoading == favorite.count {
            currentCellsCompletedLoading = 0
        }
    }'*/
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
    deinit {
        Logger().info("FavoriteTableVC deinit")
    }
}
