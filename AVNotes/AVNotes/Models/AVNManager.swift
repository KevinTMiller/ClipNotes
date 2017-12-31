//
//  AVNManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import Foundation

class AVNManager: NSObject {
    
    
    static let sharedInstance = AVNManager()

    // Public Vars
    var currentRecording: AnnotatedRecording?
    var recordingArray = [AnnotatedRecording]() {
        didSet {
            notifyUpdate()
        }
    }
    
    private func notifyUpdate() {
        NotificationCenter.default.post(name: .tableViewNeedsUpdate, object: nil)
    }

}
extension Notification.Name {
    public static let tableViewNeedsUpdate = Notification.Name(rawValue: "tableViewNeedsUpdate")
}
