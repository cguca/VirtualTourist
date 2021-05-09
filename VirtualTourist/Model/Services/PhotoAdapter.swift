//
//  PhotoAdapter.swift
//  VirtualTourist
//
//  Created by Cary Guca on 5/9/21.
//

import Foundation
import UIKit

class PhotoAdapter {
    class func adapt(photos: [Photo]) -> [FlickrPhoto]{
        let photos: [FlickrPhoto] = photos.compactMap { photoObject in
          guard
            let photoId = "" as String?,
              let farm = 0 as Int?,
              let server = "" as String?,
              let secret = "" as String?,
            let imageData = photoObject.image as Data?
          else {
            return nil
          }

            var flickrPhoto = FlickrPhoto(photoID: photoId, farm: farm, server: server, secret: secret)
            flickrPhoto.thumbnail = UIImage(data: imageData)
           return flickrPhoto
        }
        return photos
    }
}
