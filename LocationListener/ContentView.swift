//
//  ContentView.swift
//  LocationListener
//
//  Created by Kuama on 29/04/21.
//

import SwiftUI
import CoreLocation
import Combine

struct ContentView: View {
//    let locationReader = LocationReader()
//    let locationRequest = LocationRequest()
//    @State var locationRequest = CLLocationManager.publishLocation()
//    var locationPublisher = CLLocationManager.publishLocation()

    let stream = StreamLocation()
    
        @State var cancellable: AnyCancellable? = nil
    
    var body: some View {
        let publisher = stream.subject
        VStack(content: {
            Button("Get Location", action:{
                
                stream.startUpdatingLocations()
                DispatchQueue.main.async{
                    self.cancellable = publisher?.sink{
                        s in
                        print("\(s.coordinate.latitude),\(s.coordinate.longitude)")
                    }
                }
//                locationReader.setupObserver()
//                locationRequest.startUpdatingLocation()
            }
            ).padding(.all)
//            .onReceive(publisher) {
//                s in
//                print("\(s.coordinate.latitude)-\(s.coordinate.longitude)")
//            }
            Button("Stop Location", action:{
                stream.stopUpdates()
                DispatchQueue.main.async {
                    self.cancellable?.cancel()
                }
            }).padding(.all)
//            .onReceive(locationPublisher, perform: { location in
//                print("lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude)")
//            })
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

