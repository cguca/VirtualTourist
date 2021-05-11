//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Cary Guca on 4/27/21.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    let viewContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var mapView: MKMapView!
            
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? viewContext.fetch(fetchRequest){
            populateMap(locations: result)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UserDefaults.standard.bool(forKey: "locationsaved")  {
            let latitude = UserDefaults.standard.double(forKey: "latitude")
            let longitude = UserDefaults.standard.double(forKey: "longitude")
            let latitudeDelta = UserDefaults.standard.double(forKey: "latitudeDelta")
            let longitudeDelta = UserDefaults.standard.double(forKey: "longitudeDelta")
            
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(CLLocationDegrees(latitude), CLLocationDegrees(longitude))
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: location, span: span)
            
            DispatchQueue.main.async {
                self.mapView.region = region
            }
        }
    }
        
    /*
     Populated the map with saved pins
     */
    func populateMap(locations:[Pin]) {
        var annotations = [MKPointAnnotation]()
        for location in locations {
            let lat = CLLocationDegrees(Double(location.latitude!)!)
            let long = CLLocationDegrees(Double(location.longitude!)!)
          
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        
        DispatchQueue.main.async {
            self.mapView.addAnnotations(annotations)
        }
    }
    
    // Mark - Core Data funtions
    func savePin(longitude: Double, latitude: Double) {
        let pin = Pin(context: viewContext)
        
        pin.longitude = String(longitude)
        pin.latitude = String(latitude)
        
        do {
            try viewContext.save()
        }  catch {
            print("An error occured while saving the pin location: \(error.localizedDescription)")
        }
    }
    
    // Mark - IBActions
    @IBAction func didTouchLong(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self.mapView)
        let pinCoordinate =  self.mapView.convert(location, toCoordinateFrom: self.mapView)
        let pin = MKPointAnnotation()
        pin.coordinate = pinCoordinate
        savePin(longitude: pinCoordinate.longitude, latitude: pinCoordinate.latitude)
        DispatchQueue.main.async {
            self.mapView.addAnnotation(pin)
        }
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    /*
     Determine the pin that was selected and navigate to photo album controller
     */
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        let storyboard = UIStoryboard (name: "Main", bundle: nil)
        let photoAlbumVC = storyboard.instantiateViewController(withIdentifier: "PhotoAlbumViewController")as! PhotoAlbumViewController
    
        let latitude = view.annotation?.coordinate.latitude
        let longitude = view.annotation?.coordinate.longitude
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
    
        let latitudePredicate = NSPredicate(format: "latitude == %@", String(latitude!))
        let longitudePredicate = NSPredicate(format: "longitude == %@", String(longitude!))
        
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latitudePredicate, longitudePredicate])
                
        fetchRequest.predicate = andPredicate
        
        if let result = try? viewContext.fetch(fetchRequest){
            photoAlbumVC.pin = result.first
        } else {
            print("I cannot find the pin")
        }
       
        self.navigationController?.pushViewController(photoAlbumVC, animated: true)
    }
    
    /*
     Save the map location whenever the user changes it.
     */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region = mapView.region
        let center = region.center
        let latitude = center.latitude
        let longitude = center.longitude

        let span = region.span
        let latitudeDelta = span.latitudeDelta
        let longitudeDelta = span.longitudeDelta

        UserDefaults.standard.set(latitude, forKey: "latitude")
        UserDefaults.standard.set(longitude, forKey: "longitude")
        UserDefaults.standard.set(latitudeDelta, forKey: "latitudeDelta")
        UserDefaults.standard.set(longitudeDelta, forKey: "longitudeDelta")
        UserDefaults.standard.set(longitudeDelta, forKey: "locationsaved")
    }
}
