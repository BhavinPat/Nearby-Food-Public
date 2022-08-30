//
//  CategoriesRequest.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 12/14/21.
//

import Foundation
import OSLog

struct CategoriesRequest {
    //let URLRequest: URLRequest
    let request: URLRequest
    let resourceURL: URL
    let token = Key().apiKey ?? "XXXXXXXXXXXXXXXXX"
    init() {
        let resourceString = "https://api.yelp.com/v3/categories?local=\(Locale.current.regionCode ?? "")"
        guard let resourceURL = URL(string: resourceString) else {
            fatalError("Invalid API String")
        }
        self.resourceURL = resourceURL
        var request = URLRequest(url: self.resourceURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.request = request
    }
    func getCategories (completion: @escaping(Result<[CategoryDetails], BusinessesError>) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            guard let jsonData = data else {
                completion(.failure(.someError))
                return
            }
            do {
                let decoder = JSONDecoder()
                let categoryResponse = try decoder.decode(CategoriesResults.self, from: jsonData)
                let categoryDetails = categoryResponse.categories
                completion(.success(categoryDetails))
            } catch {
                Logger().error("\(error.localizedDescription)")
                completion(.failure(.canNotprocessData))
            }
        }
        dataTask.resume()
    }
}
