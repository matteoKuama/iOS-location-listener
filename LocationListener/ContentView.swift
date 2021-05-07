//
//  ContentView.swift
//  LocationListener
//
//  Created by Kuama on 29/04/21.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
//    let locationReader = LocationReader()
    let locationRequest = LocationRequest()
    
    var body: some View {
        VStack(content: {
            Button("Get Location", action:{
//                locationReader.setupObserver()
                locationRequest.startUpdatingLocation()
            }
            ).padding(.all)
            Button("Stop Location", action:{
                locationRequest.stopMonitoring()
//                locationReader.removeObserver()
            }).padding(.all)
            
        })
        
    }
    

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class LocationReader {
    
    private let notificationCenter = NotificationCenter.default
     
    func setupObserver(){
        notificationCenter.addObserver(self, selector: #selector(locationPrinter(_notification:)), name: Notification.Name("Location"), object: LocationRequest.shared)
    }
    
    @objc
    private func locationPrinter(_notification:Notification){
        if let data = _notification.userInfo as? [String:Double]{
            for (name, location) in data {
                print("\(name): \(location)")
            }
        }
    }
    
    func removeObserver(){
        notificationCenter.removeObserver(self)
    }
}

