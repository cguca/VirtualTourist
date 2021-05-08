//
//  FlikrPhotoClient.swift
//  VirtualTourist
//
//  Created by Cary Guca on 4/28/21.
//

import Foundation
import UIKit

class FlikrPhotoClient {
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest/"

//        https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=de0960031f25d3a721ba56739a2f7a5c&lat=29.9537&lon=-90.0777&page=1&format=json&nojsoncallback=1
        case getLocationImages(String, String)
        
        var stringValue: String {
            switch self {
            case .getLocationImages(let latitude, let longitude ):
                return Endpoints.base + "?method=flickr.photos.search&api_key=de0960031f25d3a721ba56739a2f7a5c&lat=\(latitude)&lon=\(longitude)&page=0&per_page=20&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getPhotosByLocation(latitude: Double, longitude: Double, completion: @escaping ([FlickrPhoto], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getLocationImages(String(format: "%.4f",latitude), String(format: "%.4f", longitude)).url, response: FlickrPhotoSearchResults.self) { (response, error)
        in
            if let response = response {
                let flickrPhotoData = response.photos.photo
                let flickrPhotos = self.getPhotos(photoData: flickrPhotoData)
                completion(flickrPhotos, nil)
            } else {
                print(error!)
                completion([], error)
            }
        }
    }

     class func getPhotos(photoData: [FlickrPhotoData]) -> [FlickrPhoto] {
      let photos: [FlickrPhoto] = photoData.compactMap { photoObject in
        guard
            let photoID = photoObject.id as String?,
            let farm = photoObject.farm as Int?,
            let server = photoObject.server as String?,
            let secret = photoObject.secret as String?
        else {
          return nil
        }

        var flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)

        guard
          let url = flickrPhoto.flickrImageURL(),
          let imageData = try? Data(contentsOf: url as URL)
        else {
          return nil
        }

        if let image = UIImage(data: imageData) {
          flickrPhoto.thumbnail = image
          return flickrPhoto
        } else {
          return nil
        }
      }
      return photos
    }
    
    private class func taskForGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?)->Void){
        print(url.absoluteURL)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
}

