//
//  Photo.swift
//  VirtualTourist
//
//  Created by Cary Guca on 4/28/21.
//

import Foundation
import UIKit

// MARK: - Photo
struct FlickrPhoto  {
    var thumbnail: UIImage?
    var largeImage: UIImage?
    let photoID: String
    let farm: Int
    let server: String
    let secret: String
    
//    enum CodingKeys: String, CodingKey {
//        case thumbnail
//        case largeImage
//        case photoID
//        case farm
//        case server
//        case secret
//    }
    init (photoID: String, farm: Int, server: String, secret: String) {
      self.photoID = photoID
      self.farm = farm
      self.server = server
      self.secret = secret
    }
    
    func flickrImageURL(_ size: String = "m") -> URL? {
      return URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg")
    }
}
