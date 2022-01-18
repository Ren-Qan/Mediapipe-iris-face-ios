//
//  AppDelegate.swift
//  FaceMeshTest
//
//  Created by 任玉乾 on 2022/1/12.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if window == nil {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        
        let rootNavigationController = UINavigationController(rootViewController: ViewController())
        window?.rootViewController = rootNavigationController
        
        window?.makeKeyAndVisible()
        
        return true
    }
}

