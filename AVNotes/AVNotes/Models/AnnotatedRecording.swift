//
//  AVRecordingObject.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit

// This object contains the a path to the recording, some metadata about the recording
// and an array of annotation objects

struct AnnotatedRecording: Timestampable {
    var timeStamp: Double?
    var title: String
    let recordingPath: URL
    var annotations: [AVNAnnotation]?
    
}
