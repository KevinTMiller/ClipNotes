//
//  AppDelegate.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import Firebase
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool { // swiftlint:disable:this line_length
        RecordingManager.sharedInstance.loadFiles()
        application.statusBarStyle = .lightContent
        FirebaseApp.configure()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        RecordingManager.sharedInstance.saveFiles()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        switch StateManager.sharedInstance.currentState {
        case .initialize:
StateManager.sharedInstance.currentState = .prepareToRecord
        default:
            return
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //TODO: Consider adding something here like Insomnia to keep app active in background
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if StateManager.sharedInstance.needsSave {
            AudioManager.sharedInstance.emergencySave()
        }
        RecordingManager.sharedInstance.saveFiles()
    }
}
