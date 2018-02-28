//
//  BookmarkTableViewCell.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/16/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class BookmarkTableViewCell: UITableViewCell {

    @IBOutlet private weak var bookmarkTextLabel: UILabel!
    @IBOutlet private weak var bookmarkTimeStamp: UILabel!
    @IBOutlet private weak var bookmarkTitleLabel: UILabel!

    var indexPath: IndexPath!
    var longPressRecognizer: UILongPressGestureRecognizer!

    func populateFromBookmark(_ bookmark: AVNAnnotation, index: IndexPath) {
        bookmarkTextLabel.text = bookmark.noteText
        bookmarkTitleLabel.text = bookmark.title
        bookmarkTimeStamp.text = String.stringFrom(timeInterval: bookmark.timeStamp)
        indexPath = index
    }
}
