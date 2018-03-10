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

enum MediaType: Int, Codable {
    case audio
    case video
}

struct AnnotatedRecording: Codable {
    var annotations: [Bookmark]?
    let date: Date
    var duration: Double
    var fileName: String
    var folderID: String
    var mediaType: MediaType
    var userTitle: String

    init(duration: Double, userTitle: String, fileName: String, mediaType: MediaType) {
        self.duration = duration
        self.userTitle = userTitle
        self.fileName = fileName
        self.mediaType = mediaType
        self.annotations = []
        self.date = Date()
        self.folderID = ""
    }
}
