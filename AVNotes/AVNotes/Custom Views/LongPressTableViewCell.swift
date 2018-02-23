//
//  LongPressTableViewCell.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/20/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class LongPressTableViewCell: UITableViewCell {
    
    var longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    override func layoutSubviews() {
        addGestureRecognizer(longPressGestureRecognizer)
    }
}
