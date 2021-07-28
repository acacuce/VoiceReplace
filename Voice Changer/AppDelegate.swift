//
//  AppDelegate.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RecordingViewController()
        window.makeKeyAndVisible()

        self.window = window


        // Override point for customization after application launch.
        return true
    }
}

