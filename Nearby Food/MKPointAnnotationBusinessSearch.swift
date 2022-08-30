//
//  MKPointAnnotationBusinessSearch.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/2/22.
//

import UIKit
import MapKit

class MKPointAnnotationBusinessSearch: MKPointAnnotation {
    let businessDetailSearch: BusinessDetailSearch?
    let businessDetail: BusinessDetail?
    var isSearch = false
    var isMain = false
    init(business: BusinessDetailSearch)  {
        self.businessDetailSearch = business
        self.businessDetail = nil
    }
    init(business: BusinessDetail) {
        self.businessDetail = business
        self.businessDetailSearch = nil
    }
}
