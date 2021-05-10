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
        
//    var dataController:DataController!
//    let dataController = DataController(modelName: "VirtualTourist")
    let saveMapLocationQueue = DispatchQueue(label: "maplocation", qos: .userInitiated)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
//        if let result = try? dataController.viewContext.fetch(fetchRequest){
        if let result = try? viewContext.fetch(fetchRequest){
            // results are pin locations
            handleLocations(locations: result)
        }
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        if UserDefaults.standard.bool(forKey: "locationsaved")  {
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
        
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
        
    @IBAction func didTouchLong(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self.mapView)
        let pinCoordinate =  self.mapView.convert(location, toCoordinateFrom: self.mapView)
        let pin = MKPointAnnotation()
        pin.coordinate = pinCoordinate
        addPin(longitude: pinCoordinate.longitude, latitude: pinCoordinate.latitude)
        DispatchQueue.main.async {
            self.mapView.addAnnotation(pin)
        }
    }
    
    func addPin(longitude: Double, latitude: Double) {
//        let pin = Pin(context: dataController.viewContext)
        let pin = Pin(context: viewContext)
        pin.longitude = String(format: "%.4f", longitude)
        pin.latitude = String(format: "%.4f", latitude)
//        print("When adding pin latitude:\(String(describing: pin.latitude)) longitude\(String(describing: pin.longitude))")
//        try? dataController.viewContext.save()
        do {
            try viewContext.save()
        }  catch {
            print(error)
        }
    }
    
    func handleLocations(locations:[Pin]) {
        
        var annotations = [MKPointAnnotation]()
        for location in locations {
            let lat = CLLocationDegrees(Double(location.latitude!)!)
            let long = CLLocationDegrees(Double(location.longitude!)!)
          
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let annotation = MKPointAnnotation()
//            print("Retreiving pin latitude:\(lat) longitude\(long)")
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        
        DispatchQueue.main.async {
            self.mapView.addAnnotations(annotations)
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Navigation

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // If this is a NotesListViewController, we'll configure its `Notebook`
//        if let vc = segue.destination as? PhotoAlbumViewController {
//            //vc.latitude = 0
//            //vc.longitude = 0
//        }
//    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
//        performSegue(withIdentifier: "photoAlbum", sender: nil)
                
        let storyboard = UIStoryboard (name: "Main", bundle: nil)
        let photoAlbumVC = storyboard.instantiateViewController(withIdentifier: "PhotoAlbumViewController")as! PhotoAlbumViewController
    
        let latitude = view.annotation?.coordinate.latitude
        let longitude = view.annotation?.coordinate.longitude
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let latitudePredicate = NSPredicate(format: "latitude == %@", String(format: "%.4f", latitude!))
        let longitudePredicate = NSPredicate(format: "longitude == %@", String(format: "%.4f", longitude!))
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latitudePredicate, longitudePredicate])
        
//        let predicate = NSPredicate(format:"latitude == 42.09950565499281 AND longitude == -88.26213018226036")

        
        fetchRequest.predicate = andPredicate
//        fetchRequest.predicate = predicate
        
        if let result = try? viewContext.fetch(fetchRequest){
//            print("Lat: \(String(describing: latitude)) Lon: \(String(describing: longitude))")
//            print("Here is the pin \(result)")
            photoAlbumVC.pin = result.first
        } else {
            print("I cannot find the pin")
        }
        // Communicate the match
        photoAlbumVC.latitude = view.annotation?.coordinate.latitude
        photoAlbumVC.longitude = view.annotation?.coordinate.longitude
        self.navigationController?.pushViewController(photoAlbumVC, animated: true)
    }
    

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("regionDidChangeAnimated")
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
        
        print(latitude, longitude, latitudeDelta, longitudeDelta)
    }
    

}
