//
//  FirstViewController.swift
//  LocationAlbum
//
//  Created by Salman Qureshi on 3/5/18.
//  Copyright © 2018 Salman Qureshi. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationVC: UIViewController {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var getLocationButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    var location: CLLocation?
    
    var updatingLocation = false
    
    var captureLastLocationError: Error?
    
    var captureLastGeocodingError: Error?
    var performingReverseGeocoding = false
    let geocoder = CLGeocoder()
    var placemarks: CLPlacemark?
    
    //MARK: View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        configureGetButton()
    }
    
    @IBAction func getLocation() {
        
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .restricted, .denied:
            showLocationServicesDeniedAlert()
            return
        case .authorizedAlways, .authorizedWhenInUse:
            
            if updatingLocation {
                stopUpdatingLocationManager()
            } else {
                location = nil
                captureLastLocationError = nil
                startLocationManager()
            }
            
            updateUI()
            configureGetButton()
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdatingLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func configureGetButton() {
        if updatingLocation {
            getLocationButton.setTitle("Stop", for: .normal)
        } else {
            getLocationButton.setTitle("Get Location", for: .normal)
        }
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",
                                      message:
            "Please enable location services for this app in Settings.",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default,
                                     handler: nil)
        present(alert, animated: true, completion: nil)
        alert.addAction(okAction)
    }
    
    func updateUI() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            addressLabel.text = ""
            messageLabel.text = ""
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            
            let statusMessage: String
            
            if let error = captureLastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            }else {
                statusMessage = "Tap, 'Get Location' to Start"
            }
            
            messageLabel.text = statusMessage
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension CurrentLocationVC: CLLocationManagerDelegate {
    /*
     Some of the possible Core Location errors:
     • CLError.locationUnknown - The location is currently unknown, but Core Location will keep trying.
     • CLError.denied - The user declined the app to use location services.
     • CLError.network - There was a network-related error.
     
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        captureLastLocationError = error
        
        stopUpdatingLocationManager()
        updateUI()
        configureGetButton()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations description \(locations)")
        let newLocation = locations.last!
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            captureLastLocationError = nil
            location = newLocation
            updateUI()
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                print("done!")
                stopUpdatingLocationManager()
                configureGetButton()
            }
            
            if !performingReverseGeocoding {
                print("===Geocode")
                performingReverseGeocoding = true
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: { (placemark, error) in
                    print("Place \(placemark), error \(error)")
                    
                    self.captureLastGeocodingError = error
                    
                    if error == nil, let p = placemark, !p.isEmpty {
                        self.placemarks = p.last!
                    } else {
                        self.placemarks = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateUI()
                })
            }
        }
    }
}
