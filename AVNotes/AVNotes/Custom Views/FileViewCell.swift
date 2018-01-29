//
//  FileViewCell.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/23/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class FileViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bookmarkLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
