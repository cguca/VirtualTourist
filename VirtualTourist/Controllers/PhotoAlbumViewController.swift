//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Cary Guca on 4/28/21.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    let viewContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let sectionInsets = UIEdgeInsets(top: 60.0, left: 30.0, bottom: 60.0, right: 30.0)
    private let itemsPerRow: CGFloat = 3
    
    var pin:Pin!
    var latitude:Double!
    var longitude:Double! 
    let latitudeDelta = 1.0
    let longitudeDelta = 1.0
    var page:Int = 0
    
//    var images: [Picture] = []
    var images: [FlickrPhoto] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    fileprivate func  getLocation() {
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        let lat = CLLocationDegrees(latitude)
        let long = CLLocationDegrees(longitude)
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        DispatchQueue.main.async {
            self.mapView.region = region
            self.mapView.addAnnotation(annotation)
        }
    }
    
    
    fileprivate func getPhotos() {
//        let fetchRequest: NSFetchRequest<Picture> = Picture.fetchRequest()
//        let predicate = NSPredicate(format: "pin == %@", pin)
//        fetchRequest.predicate = predicate
//        if  let result = try? viewContext.fetch(fetchRequest) {
//            if result.count > 0 {
//                print("The pin has photos. Here's the count \(result.count)")
//            } else {
//                FlikrPhotoClient.getPhotosByLocation(latitude: latitude, longitude: longitude, completion: handleGetPhotosResponse(photos:error:))
        FlikrPhotoClient.getPhotosByLocation2(page: page, latitude: latitude, longitude: longitude, completion: handleLocationPhotosResponse(response:error:))
//            }
//        } else {
//            FlikrPhotoClient.getPhotosByLocation(latitude: latitude, longitude: longitude, completion: handleLocationPhotosResponse(photos:error:))
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        if let storedPictures = pin?.picture {
//            print("**** Count of pictures stored \(storedPictures.count)")
//            for pic in storedPictures {
//                print("**** pic with id \((pic) as! Picture).id)")
//                images.append(pic as! Picture)
//            }
//        } else {
            getPhotos()
//        }
        getLocation()
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    func handleLocationPhotosResponse(response:FlickrPhotosData?, error:Error?) {
        if let response = response {
            print("Here is the number of images \(String(describing: response.total))")
            
            handleGetPhotosResponse(photos: FlikrPhotoClient.getPhotos2(photoData: response.photo), error: error)
        } else {
            print("There is an error")
        }
    }
    
    // Utility function to convert Flickr response data to core data object
    // persist
    func handleGetPhotosResponse(photos:[FlickrPhoto], error:Error?){
        
//        for photo in photos{
//            print("Saving picture with id \(photo.id)")
//            let picture = Picture(context: viewContext)
//            picture.id = photo.id
//            picture.secret = photo.secret
//            picture.server = photo.server
//            picture.pin = pin
//            
//            try? viewContext.save()
//            images.append(picture)
//        }
        images = photos
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @IBAction func getNewCollection(_ sender: Any) {
        /*
         1. clear local data
         2. remove from core data
         3. get new page number
         3. get new photos
         5. update collection view
         */
        self.images = []
        page = page + 1
        getPhotos()
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCell", for: indexPath) as! FlickrImageCell
        
        let flickrPhoto = self.images[(indexPath as NSIndexPath).row]
        
        let image = flickrPhoto.thumbnail!
        cell.imageView.image = image
        
        if let url = flickrPhoto.flickrImageURL() {
            loadImage(url: url) { (image) -> Void in
                cell.imageView.image = image
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        images.remove(at: indexPath.item)
        self.collectionView.deleteItems(at: [indexPath])
    }
    
    func loadImage(url: URL, completionHandler handler: @escaping (_ image: UIImage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            if let imgData = try? Data(contentsOf: url), let img = UIImage(data: imgData) {
                // run the completion block
                // always in the main queue, just in case!
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(img)
                })
            }
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
  // 1
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    // 2
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow

    return CGSize(width: widthPerItem, height: widthPerItem)
  }

  // 3
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    return sectionInsets
  }

  // 4
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    return sectionInsets.left
  }

}
