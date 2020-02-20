//
//  AppDelegate.swift
//  SmartBedClient
//
//  Created by Eugene L. on 2/2/20.
//  Copyright © 2020 ARandomDeveloper. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        let d = UserDefaults.standard
        if d.bool(forKey: "firstlaunch") == false {
            d.set(true, forKey: "firstlaunch")
            d.set("192.168.0.1", forKey: "mqttHost")
            d.set("yourtopic", forKey: "mqttTopic")
            d.set(1883, forKey: "mqttPort")
        }
        
        return true
    }
    
    private func application(_ application: UIApplication, didReceive notification: UNNotification) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

