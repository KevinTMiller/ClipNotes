//
// DeepPressGuestureRecognizer.swift
//  AVNotes
//
//  Created by Kevin Miller on 4/4/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import Foundation
import UIKit

class DeepPressGestureRecognizer: UIGestureRecognizer {

    let threshold: CGFloat

    var vibrateOnDeepPress = true
    private var deepPressed = false

    required init(target: Any?, action: Selector?, threshold: CGFloat) {
        self.threshold = threshold
        super.init(target: target, action: action)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        handleTouch(touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        handleTouch(touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = deepPressed ? .recognized : .failed
        deepPressed = false
    }

    private func handleTouch(_ touch: UITouch) {
        if !deepPressed && (touch.force / touch.maximumPossibleForce) >= threshold {
            if vibrateOnDeepPress {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            }
            deepPressed = true
        }
    }
}
