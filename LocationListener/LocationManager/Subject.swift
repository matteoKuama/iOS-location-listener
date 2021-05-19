//
//  Subject.swift
//  LocationListener
//
//  Created by Kuama on 12/05/21.
//

import Foundation
import UIKit
import CoreLocation
import Combine

//ERROR
//when a location is not available send a custom error
enum LocationError: Error{
    case locationNotAvailable
    case noAuthorization
}

extension CLLocationManager{
    static func publishLocation() -> LocationPublisher{
        return .init()
    }
}

//PUBLISHER
//receive the subscribtion
//when someone subscribe -> start location updates
//when disposed -> stop location updates
//when a new location is available -> publishes new location

class LocationPublisher: Publisher {
    
    
    
    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, CLLocation == S.Input {
        let subscription = LocationStream(subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
    
    typealias Output = CLLocation
    
    typealias Failure = Never
    
    //STREAM LOCATION-OBSERVABLE OBJECT
    //expose methods to start and to stop location updates
    //when new location is available -> send to the subject
    
    //SUBSCRIPTION
    //represent the subscription object that links the subject with the observer
    class LocationStream<S: Subscriber> : NSObject, CLLocationManagerDelegate, Subscription where S.Input == Output, S.Failure == Failure{
        
        private var subscriber: S
        
        //
        //SUBSCRIPTION PROTOCOL
        func request(_ demand: Subscribers.Demand) {
            setupLocationManager()
            startUpdatingLocations()
        }
        
        func cancel() {
//            stopUpdates()
            startUpdatingLocations()
  //          stopUpdatingLocations()
        }
        //
        //
        
        private let locationManager = CLLocationManager()
            
        private let minRadius = 1.0 // min radius for creating a new region
        private let identifier = "Location Stream"
        
        init(subscriber: S) {
            self.subscriber = subscriber
            super.init()
            self.setupLocationManager()
        }
        
        private func setupLocationManager(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.allowsBackgroundLocationUpdates = true
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
            locationManager.startUpdatingLocation()
        }
        
        func stopUpdatingLocations(){
            locationManager.stopUpdatingLocation()
        }
        
        func stopUpdates(){
            stopUpdatingLocations()
            let monitoredRegions = locationManager.monitoredRegions
            if(!monitoredRegions.isEmpty){
                for region in monitoredRegions {
                    locationManager.stopMonitoring(for: region)
                }
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.last {
                
                //send the location
                _ = subscriber.receive(location)

                if(!(UIApplication.shared.applicationState == .active)){
                    self.createRegion(location: location)
                }
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            let circRegion = region as! CLCircularRegion
            CLLocationManager.scheduleLocalNotification(manager)(alert: "did exit region, lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)", repeats: nil, timeInterval: nil)
            locationManager.stopMonitoring(for: region)
            locationManager.startUpdatingLocation()
        }
        
        func createRegion(location: CLLocation){
            if(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)){
                let region = CLCircularRegion(center: location.coordinate, radius: minRadius, identifier: identifier)
                region.notifyOnExit = true
                region.notifyOnEntry = false
                
                locationManager.stopUpdatingLocation()
                locationManager.startMonitoring(for: region)
            }
        }
    }
    

}



//class LocationSubscription: Subscription {
//
//    private var subscriber: LocationSubscriber?
//    private var subject: LocationPublisher?
//
//
//    init(subscriber: LocationSubscriber) {
//        self.subscriber = subscriber
//    }
//
//    func request(_ demand: Subscribers.Demand) {
//
//    }
//
//    func cancel() {
//        subscriber = nil
//    }
//
//}




//SUBSCRIBER
//creates a request to observe the changes on the subject
//receive location updates -> print location on the console
class LocationSubscriber: Subscriber{
    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }
    
    func receive(_ input: CLLocation) -> Subscribers.Demand {
        print("location received: \(input.coordinate.latitude), \(input.coordinate.longitude)")
        return .none
    }
    
    func receive(completion: Subscribers.Completion<LocationError>) {
        print("stream completed")
    }
    
    
    typealias Input = CLLocation
    
    typealias Failure = LocationError
    
    
}
//
//
//
//
//
//
