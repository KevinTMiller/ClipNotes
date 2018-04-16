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

enum SkipValue {
    static let thirty: Double = 30
    static let ten: Double = 10 // swiftlint:disable:this identifier_name
    static let five: Double = 5
}

class SkipViewController: UIViewController {

    var mode: SkipVCMode = .reverse
    weak var delegate: SkipControllerDelegate?
    lazy var generator = UISelectionFeedbackGenerator()
    lazy var confirmGenerator = UINotificationFeedbackGenerator()

    

    @IBAction func touchUpInside(_ sender: HapticButton) {
        confirmGenerator.notificationOccurred(.success)
    }

    @IBOutlet private weak var forwardStack: UIStackView!
    @IBOutlet private weak var replayStack: UIStackView!

    @IBAction func thirtyBackDidTouch(_ sender: HapticButton) {
        delegate?.changeSkipValue(SkipValue.thirty, mode: .reverse)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tenBackDidTouch(_ sender: HapticButton) {
        delegate?.changeSkipValue(SkipValue.ten, mode: .reverse)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func fiveBackDidTouch(_ sender: HapticButton) {
        delegate?.changeSkipValue(SkipValue.five, mode: .reverse)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func thirtyForwardDidTouch(_ sender: HapticButton) {
        delegate?.changeSkipValue(SkipValue.thirty, mode: .forward)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tenForwardDidTouch(_ sender: HapticButton) {
        delegate?.changeSkipValue(SkipValue.ten, mode: .forward)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func fiveForwardDidTouch(_ sender: HapticButton) {
        delegate?.changeSkipValue(SkipValue.five, mode: .forward)
        dismiss(animated: true, completion: nil)
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
