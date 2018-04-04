//
//  SkipViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 4/4/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

enum SkipVCMode {
    case forward
    case reverse
}

class SkipViewController: UIViewController {

    var mode: SkipVCMode = .reverse

    @IBOutlet private weak var forwardStack: UIStackView!
    @IBOutlet private weak var replayStack: UIStackView!

    @IBAction func thirtyBackDidTouch(_ sender: Any) {
    }

    @IBAction func tenBackDidTouch(_ sender: UIButton) {
    }

    @IBAction func fiveBackDidTouch(_ sender: UIButton) {
    }

    @IBAction func thirtyForwardDidTouch(_ sender: UIButton) {
    }

    @IBAction func tenForwardDidTouch(_ sender: UIButton) {
    }

    @IBAction func fiveForwardDidTouch(_ sender: UIButton) {
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        switch mode {
        case .forward:
            forwardStack.isHidden = false
            replayStack.isHidden = true
        case .reverse:
            forwardStack.isHidden = true
            replayStack.isHidden = false
        }
    }


}
