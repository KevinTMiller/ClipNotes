//
//  FolderTableViewCell.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/2/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var folderTitleLabel: UILabel!
    @IBOutlet weak var fileCountLabel: UILabel!
    
    func populateSelf(folder: Folder) {
        self.folderTitleLabel.text = folder.userTitle
        fileCountLabel.text =
        "\((AVNManager.sharedInstance.recordingArray.filter {$0.folderID == folder.systemID}).count)"
    }
}
