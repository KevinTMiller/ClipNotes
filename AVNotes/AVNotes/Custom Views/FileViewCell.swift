//
//  FileViewCell.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/23/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class FileViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var bookmarkLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func populateSelfFrom(recording: AnnotatedRecording) {
        self.titleLabel.text = recording.userTitle
        self.durationLabel.text = String.stringFrom(timeInterval: recording.duration)
        self.bookmarkLabel.text = "\(recording.annotations?.count ?? 0) Bookmarks"
        self.dateLabel.text = DateFormatter.localizedString(from: recording.date,
                                                            dateStyle: .short,
                                                            timeStyle: .none)
    }
}
