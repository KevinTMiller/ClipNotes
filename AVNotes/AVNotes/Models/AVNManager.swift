//
//  AVNManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit

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
        NotificationCenter.default.post(name: .annotationsDidUpdate, object: nil)
    }
    
    private func loadFiles() {
        // TODO: method to load files from disk
    }

}

