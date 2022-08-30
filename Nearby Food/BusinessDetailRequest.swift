//
//  BusinessDetailRequest.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 11/13/21.
//

import Foundation
import OSLog

struct BusinessDetailRequest {
    //let URLRequest: URLRequest
    let request: URLRequest
    let resourceURL: URL
    let token = "Mp_5vsgbIxCfFE5OWHBgpKnSRPalscAI-nk1rzxMGrnnP9NvXnxF7dhUUMccrtzEGcdmNXdCAcmMbowEWDWZgpWHiom_G6HW3HMEN8ZB2qVr6N6lQ7AUfP23pq2JYnYx"
    init(id: String) {
        let resourceString = "https://api.yelp.com/v3/businesses/\(id)"
        guard let resourceURL = URL(string: resourceString) else {
            fatalError("Invalid API String")
        }
        self.resourceURL = resourceURL
        var request = URLRequest(url: self.resourceURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.request = request
    }
    func getBusiness (completion: @escaping(Result<BusinessDetail, BusinessesError>) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            guard let jsonData = data else {
                completion(.failure(.someError))
                return
            }
            do {
                let decoder = JSONDecoder()
                let businessesResponse = try decoder.decode(BusinessDetail.self, from: jsonData)
                
                completion(.success(businessesResponse))
            } catch {
                Logger().error("\(error.localizedDescription)")
                completion(.failure(.canNotprocessData))
            }
        }
        dataTask.resume()
    }
}
