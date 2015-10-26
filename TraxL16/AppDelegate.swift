//
//  AppDelegate.swift
//  TraxL16
//
//  Created by iMac21.5 on 5/12/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

struct GPXURL {
    static let Notification = "GPXURL Radio Station"
    static let Key = "GPXURL URL Key"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication,
        openURL: NSURL,
        sourceApplication: String?,
        annotation: AnyObject) -> Bool {
        //post a notification when a gpx file arrives
        let center = NSNotificationCenter.defaultCenter()
        let notification = NSNotification(name: GPXURL.Notification,
            object: self,
            userInfo: [GPXURL.Key : openURL])
        center.postNotification(notification)
        print("URL = \(openURL)")
        return true
    }
    
}