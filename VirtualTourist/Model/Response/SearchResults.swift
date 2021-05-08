//
//  SearchResults.swift
//  VirtualTourist
//
//  Created by Cary Guca on 4/28/21.
//

import Foundation

// MARK: - Welcome
struct SearchResults: Codable {
    let photos: Photos
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case photos
        case stat
    }
}
