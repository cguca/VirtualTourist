//
//  FlickrPhotosData.swift
//  VirtualTourist
//
//  Created by Cary Guca on 5/8/21.
//

import Foundation

struct FlickrPhotosData: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FlickrPhotoData]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perpage
        case total
        case photo
    }
}
