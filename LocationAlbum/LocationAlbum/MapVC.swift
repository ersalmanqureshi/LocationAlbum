//
//  MapVC.swift
//  LocationAlbum
//
//  Created by Salman Qureshi on 3/16/18.
//  Copyright © 2018 Salman Qureshi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext!
    
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
    }
    
    @IBAction func showUser() {
        let region = MKCoordinateRegionMakeWithDistance(
            mapView.userLocation.coordinate, 1000, 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    func updateLocations() {
        mapView.removeAnnotations(locations)
        
        let entity = Location.entity()
        
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity
        
        do {
            locations = try managedObjectContext.fetch(fetchRequest)
            mapView.addAnnotations(locations)
        } catch {
            fatalCoreDataError(error)
        }
        
    }
    
    @IBAction func showLocations() {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MapVC: MKMapViewDelegate {
    
}
