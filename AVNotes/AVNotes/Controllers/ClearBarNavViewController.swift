//
//  ClearBarNavViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/25/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class ClearBarNavViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.backgroundColor = .clear
        navigationBar.shadowImage = UIImage()
    }
}
