//
//  AppDelegate.swift
//  Twitter
//
//  Created by kishikawakatsumi on 3/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let config = Realm.Configuration(schemaVersion: 1)
        Realm.Configuration.defaultConfiguration = config
        
        let realm = try! Realm()
        print(realm)
        return true
    }

}

