//
//  jaroSimilarity.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 11/22/21.
//

import Foundation
import UIKit

class JaroSimilarity: NSObject {
    static let shared = JaroSimilarity()
    override init() {
    }
    // Function to calculate the
    // Jaro Similarity of two strings
    func jaroDistance(_ s1: String, _ s2: String) -> Double {
        // If the strings are equal
        //if s1 == s2 {
        //    return 1.0
        //}
        
        // Length of two strings
        let len1 = s1.count,
            len2 = s2.count
        //
        if len1 == 0 || len2 == 0 {
            return 0.0
        }
        
        // Maximum distance upto which matching
        // is allowed
        let maxDist = max(len1, len2) / 2 - 1
        
        // Count of matches
        var match = 0
        
        // Hash for matches
        var hashS1: [Int] = Array(repeating: 0, count: s1.count)
        var hashS2: [Int] = Array(repeating: 0, count: s2.count)
        
        let s2Array = Array(s2)
        // Traverse through the first string
        for (i, ch1) in s1.enumerated() {
            
            // Check if there is any matches
            if max(0, i - maxDist) > min(len2 - 1, i + maxDist) {
                continue
            }
            for j in max(0, i - maxDist)...min(len2 - 1, i + maxDist) {
                
                // If there is a match
                if ch1 == s2Array[j] &&
                    hashS2[j] == 0 {
                    hashS1[i] = 1
                    hashS2[j] = 1
                    match += 1
                    break
                }
            }
        }
        
        // If there is no match
        if match == 0 {
            return 0.0
        }
        
        // Number of transpositions
        var t: Double = 0
        
        var point = 0
        
        // Count number of occurances
        // where two characters match but
        // there is a third matched character
        // in between the indices
        for (i, ch1) in s1.enumerated() {
            if hashS1[i] == 1 {
                
                // Find the next matched character
                // in second string
                while hashS2[point] == 0 {
                    point += 1
                }
                
                if ch1 != s2Array[point] {
                    t += 1
                }
                point += 1
            }
        }
        t /= 2
        
        // Return the Jaro Similarity
        return (Double(match) / Double(len1)
                    + Double(match) / Double(len2)
                    + (Double(match) - t) / Double(match))
            / 3.0
    }
    // Jaro Winkler Similarity
    func jaroWinkler(_ s1: String, _ s2: String) -> Double {
        var jaroDist = jaroDistance(s1, s2)
        
        // If the jaro Similarity is above a threshold
        if jaroDist > 0.7 {
            
            // Find the length of common prefix
            let prefixStr = s1.commonPrefix(with: s2)
            
            // Maximum of 4 characters are allowed in prefix
            let prefix = Double(min(4, prefixStr.count))
            
            // Calculate jaro winkler Similarity
            jaroDist += 0.1 * prefix * (1 - jaroDist)
        }
        return jaroDist
    }
}
