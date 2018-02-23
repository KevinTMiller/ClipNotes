//
//  BookmarkTableViewCell.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/16/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class BookmarkTableViewCell: LongPressTableViewCell {

    @IBOutlet weak var bookmarkTextLabel: UILabel!
    @IBOutlet weak var bookmarkTimeStamp: UILabel!
    @IBOutlet weak var bookmarkTitleLabel: UILabel!
    
    var indexPath: IndexPath!
    var longPressRecognizer: UILongPressGestureRecognizer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
