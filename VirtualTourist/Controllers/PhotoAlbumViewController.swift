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
    
    var pin:Pin!
    var latitude:Double!
    var longitude:Double! 
    let latitudeDelta = 1.0
    let longitudeDelta = 1.0
    
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
                FlikrPhotoClient.getPhotosByLocation(latitude: latitude, longitude: longitude, completion: handleLocationPhotosResponse(photos:error:))
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
    
    // Utility function to convert Flickr response data to core data object
    // persist
    func handleLocationPhotosResponse(photos:[FlickrPhoto], error:Error?){
        
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
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCell", for: indexPath) as! FlickrImageCell
        
        let flickrPhoto = self.images[(indexPath as NSIndexPath).row]
        let image = flickrPhoto.thumbnail!
        // Set the name and image
        cell.imageView.image = image
        //cell.villainImageView?.image = UIImage(named: villain.imageName)
        //cell.schemeLabel.text = "Scheme: \(villain.evilScheme)"
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        images.remove(at: indexPath.item)
        self.collectionView.deleteItems(at: [indexPath])
    }
}
