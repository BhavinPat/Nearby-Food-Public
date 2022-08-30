//
//  CarouselItem.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 2/3/22.
//

import Foundation
import UIKit

@IBDesignable
class CarouselItem: UIView {
    static let CAROUSEL_ITEM_NIB = "CarouselItem"
    
    @IBOutlet var Content: UIView!
    @IBOutlet var image: UIImageView!
    @IBOutlet var background: UIView!
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initWithNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initWithNib()
    }
    
    convenience init(withImageName: String) {
        self.init()
        image.image = UIImage(named: withImageName)
        image.layer.cornerRadius = 6.5
        image.layer.masksToBounds = true
    }
    
    fileprivate func initWithNib() {
        
        Bundle.main.loadNibNamed(CarouselItem.CAROUSEL_ITEM_NIB, owner: self, options: nil)
        Content.frame = bounds
        Content.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(Content)
    }
}
