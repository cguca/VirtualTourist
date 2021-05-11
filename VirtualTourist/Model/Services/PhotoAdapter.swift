//
//  PhotoAdapter.swift
//  VirtualTourist
//
//  Created by Cary Guca on 5/9/21.
//

import Foundation
import UIKit

class PhotoAdapter {
    /*
     Converts from core data model to FlickrPhoto DTO
     */
    class func adapt(photos: [Photo]) -> [FlickrPhoto]{
        let photos: [FlickrPhoto] = photos.compactMap { photoObject in
          guard
            let photoId = photoObject.photoID as String?,
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
    
    /*
     Converts from collection Flickr response photo objects to FlickrPhoto DTO
     */
    class func adapt(photoData: [FlickrPhotoData]) -> [FlickrPhoto] {
     let photos: [FlickrPhoto] = photoData.compactMap { photoObject in
       guard
           let photoID = photoObject.id as String?,
           let farm = photoObject.farm as Int?,
           let server = photoObject.server as String?,
           let secret = photoObject.secret as String?
       else {
         return nil
       }

        let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)

        return flickrPhoto
     }
     return photos
   }
}
