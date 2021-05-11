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
        case getLocationImages(String, String, Int)
        var stringValue: String {
            switch self {
            case .getLocationImages(let latitude, let longitude, let page):
                return Endpoints.base + "?method=flickr.photos.search&api_key=de0960031f25d3a721ba56739a2f7a5c&lat=\(latitude)&lon=\(longitude)&page=\(page)&per_page=100&format=json&nojsoncallback=1"
            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    /*
    Method to call search API
     */
    class func searchForPhotosByLocation(page: Int, latitude: Double, longitude: Double, completion: @escaping (FlickrPhotosData?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getLocationImages(String(format: "%.4f",latitude), String(format: "%.4f", longitude), page).url, response: FlickrPhotoSearchResults.self) { (response, error)
        in
            if let response = response {
                let photoData = response.photos
                completion(photoData, nil)
            } else {
                print("Error searching photos by location: \(error!.localizedDescription)")
                completion(nil, error)
            }
        }
    }

    /*
     Utility method to manage GET requests
     */
    private class func taskForGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?)->Void){
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

