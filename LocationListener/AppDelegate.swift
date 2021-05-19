//
//  AppDelegate.swift
//  LocationListener
//
//  Created by Kuama on 17/05/21.
//

import Foundation
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate{
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "net.kuama.BGLocationRequest", using: nil, launchHandler: { task in
            self.handleRefreshTask(task: task as! BGAppRefreshTask)
        })
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "net.kuama.BGLocationRequest")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Not able to submit a background fetch")
        }
    }
    
    func handleRefreshTask(task: BGAppRefreshTask){
        scheduleAppRefresh()
        let locationStream = StreamLocation()
        
        task.expirationHandler = {
            locationStream.stopUpdates()
        }
        
        let location = locationStream.lastKnownLocation()
        print("last known: lat: \(String(describing: location?.coordinate.latitude)), long: \(String(describing: location?.coordinate.latitude))")
        task.setTaskCompleted(success: true)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        scheduleAppRefresh()
    }
}
