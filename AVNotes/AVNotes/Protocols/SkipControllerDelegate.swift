//
//  SkipControllerDelegate.swift
//  AVNotes
//
//  Created by Kevin Miller on 4/4/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import Foundation

protocol SkipControllerDelegate: AnyObject {
    func changeSkipValue(_ value: Double, mode: SkipVCMode)
}
