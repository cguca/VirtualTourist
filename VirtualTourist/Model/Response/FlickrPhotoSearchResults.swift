//
//  FlickrPhotoSearchResponse.swift
//  VirtualTourist
//
//  Created by Cary Guca on 5/8/21.
//

import Foundation

struct FlickrPhotoSearchResults: Codable {
    let photos: FlickrPhotosData
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case photos
        case stat
    }
}
