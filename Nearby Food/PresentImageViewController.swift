//
//  PresentImageViewController.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 7/19/22.
//

import UIKit

class PresentImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBAction func dismissButtonAct(_ sender: UIButton!) {
        self.dismiss(animated: true)
    }
    var image: UIImage!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        //imageView.image = image
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imageView.image = image
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
