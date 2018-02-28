//
//  AppDelegate.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AVNManager.sharedInstance.loadFiles()
        application.statusBarStyle = .lightContent
        AudioPlayerRecorder.sharedInstance.setUpRecordingSession()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        AVNManager.sharedInstance.saveFiles()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //TODO: Consider adding something here like Insomnia to keep app active in background
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AVNManager.sharedInstance.saveFiles()
    }
}
