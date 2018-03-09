//
//  String+TxtFromBookmarks.swift
//  AVNotes
//
//  Created by Kevin Miller on 3/9/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import Foundation

extension String {
    static func formatBookmarksForExport(recording: AnnotatedRecording) -> URL? {
        guard let bookmarks = recording.annotations else { return nil }

        let filename = "\(recording.userTitle).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let prettyDate = dateFormatter.string(from: recording.date)
        var string = "\(recording.userTitle) - created \(prettyDate)\n\n"
        for bookmark in bookmarks {
            let timeString = String.stringFrom(timeInterval: bookmark.timeStamp)
            let tempString = "\(bookmark.title) - \(timeString)\n\(bookmark.noteText)\n\n"
            string += tempString
        }
        do {
            try string.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print(error)
            return nil
        }
    }
}
