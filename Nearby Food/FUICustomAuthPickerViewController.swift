//
//  FUICustomAuthPickerViewController.swift
//  Nearby Food
//
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 8/12/22.
//

import UIKit
import FirebaseAuthUI

class FUICustomAuthPickerViewController: FUIAuthPickerViewController  {
    @IBOutlet weak var skipButton: UIButton!
    @IBAction func skipButtonPressed(_ sender: UIButton!) {
        self.onBack()
    }
    @IBOutlet weak var nearbyFoodAppLogoImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        nearbyFoodAppLogoImageView.layer.masksToBounds = true
        nearbyFoodAppLogoImageView.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
