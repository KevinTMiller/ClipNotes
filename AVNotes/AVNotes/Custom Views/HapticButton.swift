//
//  HapticButton.swift
//  AVNotes
//
//  Created by Kevin Miller on 4/10/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class HapticButton: UIButton {

    weak var generator = UISelectionFeedbackGenerator()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("touches began")
        backgroundColor = .lightGray
        generator?.selectionChanged()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        print("touches moved")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        backgroundColor = .white
        print("touches ended")
    }
}
