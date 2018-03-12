//
//  String+StringFromTimeInterval.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/17/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import Foundation
import UIKit

extension String {

    static func stringFrom(timeInterval: TimeInterval) -> String {
        let time = Int(timeInterval)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3_600)
        return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }

    static func stopwatchStringFrom(timeInterval: TimeInterval) -> String {
        let time = Int(timeInterval)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3_600)
        let millisec = Int(timeInterval.truncatingRemainder(dividingBy: 1) * 100)

        if hours > 0 {
            return String(format: "%0.2d:%0.2d:%0.2d.%0.2d", hours, minutes, seconds, millisec)
        } else {
            return String(format: "%0.2d:%0.2d.%0.2d", minutes, seconds, millisec)
        }
    }

    static func shortStringFrom(timeInterval: TimeInterval) -> String {
        let time = Int(timeInterval)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3_600)

        if minutes < 60 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}
