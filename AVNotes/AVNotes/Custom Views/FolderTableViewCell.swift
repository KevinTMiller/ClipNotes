//
//  FolderTableViewCell.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/2/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var folderTitleLabel: UILabel!
    @IBOutlet private weak var fileCountLabel: UILabel!

    func populateWith(title: String, icon: String) {
        folderTitleLabel.text = title
        fileCountLabel.text = icon
    }

    func populateSelf(folder: Folder) {
        folderTitleLabel.text = folder.userTitle
        fileCountLabel.text =
        "\((AVNManager.sharedInstance.recordingArray.filter { $0.folderID == folder.systemID }).count)"
    }
}
