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
    
    var timer: Timer?
    
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
                placemarks = nil
                captureLastGeocodingError = nil
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
            
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func stopUpdatingLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            
            if let timer = timer {
                timer.invalidate()
            }
        }
    }
    
    @objc func didTimeOut() {
        print("== Time out")
        
        if location == nil {
            stopUpdatingLocationManager()
            
            captureLastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            
            updateUI()
            configureGetButton()
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
            //messageLabel.text = ""
            
            if let placemark = placemarks {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if captureLastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                 addressLabel.text = "No Address Found"
            }
            
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
    
    func string(from placemark: CLPlacemark) -> String {
       
        var line1 = ""
        
        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }
        
        if let s = placemark.thoroughfare {
            line1 += s }
        
        var line2 = ""
        if let s = placemark.locality {
            line2 += s + " "
        }
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        if let s = placemark.postalCode {
            line2 += s }
        
        return line1 + "\n" + line2
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
    
    /*
     • finds a location with the desired accuracy,
     • finds a location that is not as accurate as you’d like and you don’t get any more accurate readings,
     • doesn’t find a location at all, or
     • takes too long finding a location.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations description \(locations)")
        let newLocation = locations.last!
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            captureLastLocationError = nil
            location = newLocation
            updateUI()
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                print("done!")
                stopUpdatingLocationManager()
                configureGetButton()
                
                if distance < 0 {
                    performingReverseGeocoding = false
                }
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
        } else if distance < 1 {
            
            let timeStmp = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            if timeStmp > 10 {
                stopUpdatingLocationManager()
                updateUI()
                configureGetButton()
            }
            
        }
    }
}
