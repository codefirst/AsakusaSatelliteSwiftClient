//
//  AppDelegate.swift
//  AsakusaSatelliteSwiftClientExample
//
//  Created by BAN Jun on 2015/03/01.
//  Copyright (c) 2015年 codefirst. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let handler = (window?.rootViewController as? UINavigationController)?.topViewController as? URLHandler else { return false }
        return handler.open(url: url, options: options)
    }
}


protocol URLHandler {
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
}
