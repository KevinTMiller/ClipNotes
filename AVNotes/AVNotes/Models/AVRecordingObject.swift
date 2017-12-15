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

struct AVRecordingObject {

    let recordingPath: URL
    
    // TODO: Change value type from Any to something else
    // when you know what the metadata is going to be
    var metaData: Dictionary< String , Any>
    var annotations: [AVAnnotation]?
    
}
