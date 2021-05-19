//
//  SceneDelegate.swift
//  LocationListener
//
//  Created by Kuama on 17/05/21.
//

import Foundation
import UIKit

class SceneDelegate: NSObject, UISceneDelegate{
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as! AppDelegate).scheduleAppRefresh()
    }
}
