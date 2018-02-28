//
//  String+StringFromTimeInterval.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/17/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import Foundation

extension String {
    static func stringFrom(timeInterval: TimeInterval) -> String {
        let time = Int(timeInterval)
        let millisec = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3_600)
        if time < 60 {
            return String(format: "%0.2d.%0.2d", seconds, millisec)
        }
        if time < 3_600 {
            return String(format: "%0.2d:%0.2d.%0.2d", minutes, seconds, millisec)
        }
        return String(format: "%0.2d:%0.2d:%0.2d.%0.2d", hours, minutes, seconds, millisec)
    }
}
