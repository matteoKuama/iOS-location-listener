//
//  LocationRequest.swift
//  LocationListener
//
//  Created by Kuama on 29/04/21.
//

import Foundation
import CoreLocation

/**
 This class reads the location of the user, even if the application is in background. It shares the location with NotificationCenter.
 */
class LocationRequest: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let notificationCenter = NotificationCenter.default
    
    /**
     Calling this static variable will create the object. It is useful when using NotificationCenter.addObserver, you should use LocationRequest.shared  as the object parameter.
     */
    static let shared = LocationRequest()
    
    /**
      Call internal methods to setup and log at the completion.
     */
    override init() {
        super.init()
        setupLocationManager()
        print("Setup completed")
    }
    
    /**
     Setup the location manager object
     Set the delegate as self
     Set allows backgroundLocationUpdates to true
     */
    private func setupLocationManager(){
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if(!checkAuthorization()){
            print("Error: no permission granted")
        }
    }
    
    /**
     Start updating location. This method works only if the user granted all the permissions.
     */
    func startUpdatingLocation(){
        locationManager.startUpdatingLocation()
    }
    
    /**
     Check for authorizations from the user
     It must have the permission for reading significant changes in location and that the location services are active
     */
    private func checkAuthorization()->Bool{
        return CLLocationManager.locationServicesEnabled() && CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
    
    /**
     When the user accept the authorizations for the app, it starts to update the locations, if the user doesn't give enough permissions print an error message
     */
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = locationManager.authorizationStatus
        switch status {
        case .restricted, .denied, .notDetermined:
            print("Permissions not granted")
        default:
            manager.startUpdatingLocation()
        }
    }
    
    /**
     Every time there is a new location update, print in the log the value of the latitude and of the longitude
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationObj = locations.last{
            let latitude = locationObj.coordinate.latitude
            let longitude = locationObj.coordinate.longitude
            let location = ["latitude" : latitude, "longitude":longitude]
            notificationCenter.post(name: Notification.Name("Location"), object: self, userInfo: location)
        }
    }
    
    /**
     If the location manager fails to update the locations, stop to update the locations 
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        notificationCenter.removeObserver(self, name: Notification.Name("Location"), object: nil)
        print("Location service stopped")
    }
    
}
