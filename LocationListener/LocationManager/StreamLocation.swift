//
//  StreamLocation.swift
//  LocationListener
//
//  Created by Kuama on 13/05/21.
//

import Foundation
import Darwin
import UIKit
import Combine
import CoreLocation

class StreamLocation: NSObject, CLLocationManagerDelegate{
    
    public var subject: PassthroughSubject<CLLocation, Never>?
    
    private let locationManager = CLLocationManager()
        
    private let minRadius = 100.0 // min radius for creating a new region
    private let identifier = "Location Stream"
    
    private var lastLocation: CLLocation? = nil
    
    override init() {
        super.init()
        self.setupLocationManager()
        subject = PassthroughSubject()
    }
    
    private func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = CLActivityType.fitness
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        if(!checkAuthorization()){
            //LocationError.noAuthorization come si fa?
        }
        locationManager.registerNotifications()
            
    }
    
    private func checkAuthorization() -> Bool{
        return CLLocationManager.locationServicesEnabled() && CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
    
    func startUpdatingLocations(){
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocations(){
        locationManager.stopUpdatingLocation()
    }
    
    func stopUpdates(){
        stopUpdatingLocations()
        removeMonitoredRegions()
        locationManager.stopMonitoringSignificantLocationChanges()
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let mLocation = locations.last {
            subject?.send(mLocation)
            if(!(UIApplication.shared.applicationState == .active)){
                self.createMonitoredRegions(location: mLocation)
            }
            if lastLocation != nil {
                print("Distance: \(mLocation.distance(from: lastLocation!))")
            }
            lastLocation = mLocation
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let circRegion = region as! CLCircularRegion
        CLLocationManager.scheduleLocalNotification(manager)(alert: "did exit region, lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)", repeats: nil, timeInterval: nil)
        print("exit from region: \(circRegion.radius), lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)")
        removeMonitoredRegions()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let circRegion = region as! CLCircularRegion
        CLLocationManager.scheduleLocalNotification(manager)(alert: "did enter region, lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)", repeats: nil, timeInterval: nil)
        print("enter in region: \(circRegion.radius), lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)")
        removeMonitoredRegions()
        locationManager.startUpdatingLocation()
    }
    
    
    func createMonitoredRegions(location: CLLocation){
        if(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)){
          
            var regions = Set<CLCircularRegion>()
            // where i am
            
//            //debug
//            let dbg = CLLocation(latitude: 37.330648, longitude: -122.02900846)
//            //
//
//            regions.insert(createRegion(location: dbg, notifyOnEntry: true, id: identifier))

            let nBearing = location.course
            let nLocation = getCheckPointsLocation(location: location, bearing: nBearing)
            let nRegion = createRegion(location: nLocation, radius: minRadius, id: "n" + identifier)
            print(nRegion.radius)
            print(nRegion.contains(CLLocationCoordinate2D(latitude: nLocation.coordinate.latitude, longitude: nLocation.coordinate.longitude)))
            regions.update(with: nRegion)
            
            let eBearing = location.course + 90
            let eLocation = getCheckPointsLocation(location: location, bearing: eBearing)
            let eRegion = createRegion(location: eLocation, radius: minRadius, id: "e" + identifier)
            regions.update(with: eRegion)

            
            let wBearing = location.course - 90
            let wLocation = getCheckPointsLocation(location: location, bearing: wBearing)
            let wRegion = createRegion(location: wLocation, radius: minRadius, id: "w" + identifier)
            regions.update(with: wRegion)

            
//            // north 150mt
//            let nLocation = getCheckPointsLocation(location: location, bearing: bearing)
//            let nRegion = createRegion(location: nLocation, id: "n" + identifier)
//            regions.update(with: nRegion)
//
//            // south 150mt
//            let sLocation = getCheckPointsLocation(location: location, bearing: 90)
//            let sRegion = createRegion(location: sLocation, id: "s" + identifier)
//            regions.update(with: sRegion)
//
//            // east 150 mt
//            let eLocation = getCheckPointsLocation(location: location, bearing: 180)
//            let eRegion = createRegion(location: eLocation, id: "e" + identifier)
//            regions.update(with: eRegion)
//
//            // west 150 mt
//            let wLocation = getCheckPointsLocation(location: location, bearing: 270)
//            let wRegion = createRegion(location: wLocation, id: "w" + identifier)
//            regions.update(with: wRegion)
            locationManager.stopUpdatingLocation()
            for region in regions {
                print("\(region.center.latitude),\(region.center.longitude)")
                locationManager.startMonitoring(for: region)
            }
            print("Monitored regions: \(regions.count) \(location.timestamp)")
        }
    }
    
    private func createRegion(location: CLLocation, radius: Double, id: String)-> CLCircularRegion{
        let region = CLCircularRegion(center: location.coordinate, radius: minRadius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    private func removeMonitoredRegions(){
        let monitoredRegions = locationManager.monitoredRegions
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    /// Calculate a new point centered 150 meters from location and with angle bearing from location.
    private func getCheckPointsLocation(location:CLLocation, bearing: Double)->CLLocation{
        // data
        let earthRadius = 6371e3 // in meters
        let distance = 150.0 // in meters
        let angularDistance = distance/earthRadius
        let startingLatitude = deg2rad(location.coordinate.latitude)
        let startingLongitude = deg2rad(location.coordinate.longitude)
        let mBearings = deg2rad(bearing)
        
        // new latitude
        var newLat = asin(sin(startingLatitude)*cos(angularDistance) +
                            cos(startingLatitude)*sin(angularDistance)*cos(mBearings))
        newLat = Double(round(rad2deg(newLat)*10e8)/10e8)
        // new longitude
        var newLon = startingLongitude + atan2(sin(mBearings)*sin(angularDistance)*cos(startingLatitude),
                                               cos(angularDistance)-sin(startingLatitude)*sin(newLat))
        newLon = Double(round(rad2deg(newLon)*10e8)/10e8)
        return CLLocation(latitude: newLat, longitude: newLon)
    }
    
    /// convert degrees to radians
    private func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }

    /// convert radians to degrees
    func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }
}
