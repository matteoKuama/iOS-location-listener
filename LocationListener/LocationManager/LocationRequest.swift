//
//  LocationRequest.swift
//  LocationListener
//
//  Created by Kuama on 29/04/21.
//

import Foundation
import UIKit
import CoreLocation

/**
 This class reads the location of the user, even if the application is in background. It shares the location with NotificationCenter.
 */
class LocationRequest: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let notificationCenter = NotificationCenter.default
    private let identifier = "My Region"
    
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
        if(!checkAuthorization()){
            print("Error: no permission granted")
        }
//        locationManager.registerNotifications()
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
            print("Permissions granted")
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
            
            print("lat: \(latitude), lon: \(longitude)")
            
            if(!(UIApplication.shared.applicationState == .active)){
                self.createRegion(location: locationObj)
            }
            notificationCenter.post(name: Notification.Name("Location"), object: self, userInfo: location)
        }
        else{
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
            print("Restarting updating locations")
        }
    }
    
    /**
     If the location manager fails to update the locations, stop to update the locations 
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        stopMonitoring()
        print("Location service stopped \(error)")
    }
    
    func stopMonitoring(){
        let location2D = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        let circRegion = CLCircularRegion(center: location2D, radius: 1.0, identifier: identifier)
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoring(for: circRegion)
        notificationCenter.removeObserver(self, name: Notification.Name("Location"), object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("did enter region")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("did exit region")
        let circRegion = region as!CLCircularRegion
        
        CLLocationManager.scheduleLocalNotification(manager)(alert: "did exit region, lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)", repeats: nil, timeInterval: nil)
        let location = ["latitude" : circRegion.center.latitude, "longitude": circRegion.center.longitude]
        print("\(TimeInterval(Date().timeIntervalSinceNow)) lat: \(circRegion.center.latitude), long: \(circRegion.center.latitude)")
        notificationCenter.post(name: Notification.Name("Location"), object: self, userInfo: location)
        manager.stopMonitoring(for: region)
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Error in monitoring for region: \(error.localizedDescription)")
    }
    
    private func createRegion(location: CLLocation?){
        if location != nil {
            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                let coordinate = CLLocationCoordinate2DMake((location?.coordinate.latitude)!, (location?.coordinate.longitude)!)
                let regionRadius = 1.0
                let coords = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
                let region = CLCircularRegion(center: coords, radius: regionRadius, identifier: identifier)
                region.notifyOnEntry = false
                region.notifyOnExit = true
                print("Region created with \(regionRadius) radius, centered in lat:\(coords.latitude), lon:\(coords.longitude)")
                print("\(locationManager.monitoredRegions.count)")
                locationManager.stopUpdatingLocation()
                locationManager.startMonitoring(for: region)
            }
        }
    }
    
    func createPlaceHolder(){
        createRegion(location: locationManager.location)
    }
    
}
extension CLLocationManager: UNUserNotificationCenterDelegate {
    
    func registerNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge,.sound]) { (granted:Bool, error:Error?) in
            if error != nil { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }
        
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound])
    }
    
    func scheduleLocalNotification(alert:String, repeats: Bool?, timeInterval: Double?) {
        let content = UNMutableNotificationContent()
        let requestIdentifier = UUID.init().uuidString
        
        content.badge = 0
        content.title = "Location Update"
        content.body = alert
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: timeInterval ?? 1.0, repeats: repeats ?? false)
        if(trigger.repeats){
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error:Error?) in
            print("Notification Register Success")
        }
    }
    
    func removeLocalNotifications(){
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests(completionHandler: {
            _ in
            notificationCenter.removeAllPendingNotificationRequests()
        })
    }
    
}
