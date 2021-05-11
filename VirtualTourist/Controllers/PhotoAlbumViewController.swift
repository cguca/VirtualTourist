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
        collectionView.delegate = self
        collectionView.dataSource = self
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getPhotos()

        getLocation()
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
//        print("Here is the number of saved pictures \(String(describing: pin.photo?.count))")
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        if let result = try? viewContext.fetch(fetchRequest) {
            // results are pin locations
            if result.count > 0 {
                images = PhotoAdapter.adapt(photos: result)
                print("The photos are saved so no call to the API \(result.count)")
                newCollectionButton.isEnabled = true
                return
            }
        }
        
        FlikrPhotoClient.getPhotosByLocation2(page: page, latitude: latitude, longitude: longitude, completion: handleLocationPhotosResponse(response:error:))
    }
    
    
    
    func handleLocationPhotosResponse(response:FlickrPhotosData?, error:Error?) {
        if let response = response {
            page = response.page
            totalPages = response.pages
            // Instead of pass just data, pass whole data
            handleGetPhotosResponse(photos: FlikrPhotoClient.getPhotos2(photoData: response.photo), error: error)
        } else {
            print("There is an error")
        }
    }
    
    // Utility function to convert Flickr response data to core data object
    // persist
    func handleGetPhotosResponse(photos:[FlickrPhoto], error:Error?){
        if photos.count > 0 {
            images = photos
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } else {
            messageLabel.isHidden = false
        }
    }
    
    /// Mark Core Data
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
    
    /// Mark IBActions
    @IBAction func getNewCollection(_ sender: Any) {
        /*
         1. clear local data
         2. remove from core data
         3. get new page number
         3. get new photos
         5. update collection view
         */
        self.images = []
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        if let result = try? viewContext.fetch(fetchRequest) {
            result.forEach { photo in
                viewContext.delete(photo as NSManagedObject)
            }
            try? viewContext.save()
        }
        
//        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        batchDeleteRequest.resultType = .resultTypeCount
//
//        do {
//            let result = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
//            guard let objectIDs = result?.result as? [NSManagedObjectID] else { return }
//            print("The number of objects to delete are \(objectIDs.count)")
//            let changes = [NSDeletedObjectsKey: objectIDs]
//            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
//
//        } catch {
//            fatalError("Failed to execute request: \(error)")
//        }
        

        page = page + 1
        newCollectionButton.isEnabled = false
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
        cell.photoID = flickrPhoto.photoID
        
        if let url = flickrPhoto.flickrImageURL() {
            loadImage(photoID: flickrPhoto.photoID, url: url) { (image) -> Void in
//                self.saveNewImage(image: image)
                cell.imageView.image = image
            }
        }
        
        if (indexPath.row == images.count - 1 ) { //it's your last cell
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
                // run the completion block
                // always in the main queue, just in case!
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.saveNewImage(photoID: photoID, imageData: imgData)
                    handler(img)
                })
            }
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
                print("Saving image")
            }  catch {
//                print(error)
            }
        }
    }
}

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
