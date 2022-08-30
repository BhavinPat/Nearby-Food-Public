//
//  SearchRequest.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 10/31/21.
//

import Foundation
import OSLog
import AVFoundation

struct SearchRequest {
    //let URLRequest: URLRequest
    let request: URLRequest
    let resourceURL: URL
    let token = Key().apiKey ?? "XXXXXXXXXXXXXXXXX"
    init(longitude: String, latitude: String, term: String, radius: Int, price: String, open_now: Bool, rating: String, categories: String) {
        //no search term for ratings
    
        let newTerm = term.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        let resourceString = "https://api.yelp.com/v3/businesses/search?longitude=\(longitude)&latitude=\(latitude)&term=\(newTerm)&categories=\(categories)&radius=\(radius)&price=\(price)&open_now=\(open_now)&limit=50"
        
        var resourceURL = URL(string: resourceString)
        if resourceURL == nil {
            let resourceString = "https://api.yelp.com/v3/businesses/search?longitude=\(longitude)&latitude=\(latitude)&categories=\(categories)&radius=\(radius)&price=\(price)&open_now=\(open_now)&limit=50"
            resourceURL = URL(string: resourceString) ?? Defualts.defailtSearchRequestURL
        }
        
        self.resourceURL = resourceURL!
        var request = URLRequest(url: self.resourceURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.request = request
    }
    init(longitude: String, latitude: String) {
        let resourceString = "https://api.yelp.com/v3/businesses/search?longitude=\(longitude)&latitude=\(latitude)&categories=food,restaurants"
        let resourceURL = URL(string: resourceString) ?? Defualts.defailtSearchRequestURL
        self.resourceURL = resourceURL
        var request = URLRequest(url: self.resourceURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.request = request
    }
    init(longitude: String, latitude: String, open: Bool) {
        let resourceString = "https://api.yelp.com/v3/businesses/search?longitude=\(longitude)&latitude=\(latitude)&open_now=\(open)&limit=50&categories=food,restaurants"
        let resourceURL = URL(string: resourceString) ?? Defualts.defailtSearchRequestURL
        self.resourceURL = resourceURL
        var request = URLRequest(url: self.resourceURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.request = request
    }
    init(longitude: String, latitude: String, category: String) {
        let resourceString = "https://api.yelp.com/v3/businesses/search?longitude=\(longitude)&latitude=\(latitude)&categories=\(category)&limit=6"
        let resourceURL = URL(string: resourceString) ?? Defualts.defailtSearchRequestURL
        self.resourceURL = resourceURL
        var request = URLRequest(url: self.resourceURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.request = request
    }
    init(longitude: String, latitude: String, isHome: Bool) {
        let resourceString = "https://api.yelp.com/v3/businesses/search?longitude=\(longitude)&latitude=\(latitude)&limit=50&categories=food,restaurants"
        //let resourceString = "https://api.yelp.com/v3/businesses/search?longitude=\(longitude)&latitude=\(latitude)"

        let resourceURL = URL(string: resourceString) ?? Defualts.defailtSearchRequestURL
        self.resourceURL = resourceURL
        var request = URLRequest(url: self.resourceURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.request = request
    }
    func getBusinesses (completion: @escaping(Result<BusinessDetailSearchRequest, BusinessesError>) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            guard let jsonData = data else {
                completion(.failure(.someError))
                return
            }
            do {
                let decoder = JSONDecoder()
                let businessesResponse = try decoder.decode(BusinessDetailSearchRequest.self, from: jsonData)
                //let businessDetails = businessesResponse.businesses
                //let businessRegion = businessesResponse.region
                completion(.success(businessesResponse))
            } catch {
                Logger().error("\(error.localizedDescription)")
                completion(.failure(.canNotprocessData))
            }
        }
        dataTask.resume()
    }
}
