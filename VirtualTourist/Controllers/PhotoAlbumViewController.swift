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
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    private let sectionInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
    private let itemsPerRow: CGFloat = 3
    
    var pin:Pin!
    var latitude:Double!
    var longitude:Double!
    let latitudeDelta = 1.0
    let longitudeDelta = 1.0
    var page:Int = 0
    var totalPages:Int = 0
    
    var images: [FlickrPhoto] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.isHidden = true
        newCollectionButton.isEnabled = false
        
        latitude = CLLocationDegrees(pin.latitude!)
        longitude = CLLocationDegrees(pin.longitude!)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        loadAndDisplayPhotoAlbum()
        setLocationOnMap()
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    private func  setLocationOnMap() {
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
    
    
    private func loadAndDisplayPhotoAlbum() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        if let result = try? viewContext.fetch(fetchRequest) {
            if result.count > 0 {
                images = PhotoAdapter.adapt(photos: result)
                newCollectionButton.isEnabled = true
                return
            }
        }
        FlikrPhotoClient.searchForPhotosByLocation(page: page, latitude: latitude, longitude: longitude, completion: handleSearchPhotosResponse(response:error:))
    }
    
    
    // Mark - Handlers
    func handleSearchPhotosResponse(response:FlickrPhotosData?, error:Error?) {
        if let response = response {
            page = response.page
            totalPages = response.pages
            handleGetPhotosResponse(photos: PhotoAdapter.adapt(photoData: response.photo), error: error)
        } else {
            print("There is an error getting the flickr location handler \(String(describing: error?.localizedDescription))")
        }
    }
    

    func handleGetPhotosResponse(photos:[FlickrPhoto], error:Error?){
        if photos.count > 0 {
            images = photos
        } else {
            messageLabel.isHidden = false
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    // Mark Core Data
    func deletePhoto(photoID: String) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "photoID == %@", photoID)
        fetchRequest.predicate = predicate
        if let result = try? viewContext.fetch(fetchRequest) {
            result.forEach { photo in
                viewContext.delete(photo)
            }
            try? viewContext.save()
        }
    }
    
    func saveNewImage(photoID: String, imageData: Data?) {
        if let imgData = imageData {
            let photo = Photo(context: viewContext)
            photo.image = imgData
            photo.pin = pin
            photo.photoID = photoID
            do {
                try viewContext.save()
            }  catch {
                print("There was an error while saving the image to core data: \(error.localizedDescription)")
            }
        }
    }
    
    //Mark - IBActions
    @IBAction func getNewCollection(_ sender: Any) {
        self.images = []
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        if let result = try? viewContext.fetch(fetchRequest) {
            result.forEach { photo in
                viewContext.delete(photo as NSManagedObject)
            }
            try? viewContext.save()
        }
 
        page = page + 1
        newCollectionButton.isEnabled = false
        loadAndDisplayPhotoAlbum()
    }
}

// Mark - UICollectionViewDelegate and UICollectionViewDataSource
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCell", for: indexPath) as! FlickrImageCell
        
        let flickrPhoto = self.images[(indexPath as NSIndexPath).row]
        cell.photoID = flickrPhoto.photoID
        if let image = flickrPhoto.thumbnail {
            cell.imageView.image = image
        } else {
            cell.imageView.image = UIImage(named: "placeholder")
            if let url = flickrPhoto.flickrImageURL() {
                loadImage(photoID: flickrPhoto.photoID, url: url) { (image) -> Void in
                    cell.imageView.image = image
                }
            }
        }
        
        // All images downloaded, enable button
        if (indexPath.row == images.count - 1 ) {
            newCollectionButton.isEnabled = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let flickrPhoto = self.images[(indexPath as NSIndexPath).row]
        self.deletePhoto(photoID: flickrPhoto.photoID)
        images.remove(at: indexPath.item)
        self.collectionView.deleteItems(at: [indexPath])
    }
    
    func loadImage(photoID: String, url: URL, completionHandler handler: @escaping (_ image: UIImage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            if let imgData = try? Data(contentsOf: url), let img = UIImage(data: imgData) {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.saveNewImage(photoID: photoID, imageData: imgData)
                    handler(img)
                })
            }
        }
    }
}


// Mark - UICollectionViewDelegateFlowLayout
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {

  func collectionView( _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow

    return CGSize(width: widthPerItem, height: widthPerItem)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }

  func collectionView(
    _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}
