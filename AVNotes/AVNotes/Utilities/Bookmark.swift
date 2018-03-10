//
//  Bookmark.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//
import Foundation

struct Bookmark: Codable {
    var dateStamp: Date
    var noteText: String
    var title: String
    var timeStamp: Double

    init(title: String, timestamp: Double, noteText: String) {
        self.title = title
        self.timeStamp = timestamp
        self.noteText = noteText
        self.dateStamp = Date()
    }
}
