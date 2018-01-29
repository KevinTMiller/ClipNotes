//
//  AVNManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import Disk

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
    
    func loadFiles() {
        do {
            try recordingArray = Disk.retrieve("recordings.json", from: .documents, as: [AnnotatedRecording].self)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func saveFiles() {
       
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try Disk.save(self.recordingArray, to: .documents, as: "recordings.json")
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}

