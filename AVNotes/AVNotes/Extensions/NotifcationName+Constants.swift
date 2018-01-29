//  Created by Kevin Miller on 1/1/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.

import Foundation

// Use to create custom notifications
extension Notification.Name {
    public static let annotationsDidUpdate = Notification.Name(rawValue: "annotationsDidUpdate")
    public static let audioPlayerDidFinish = Notification.Name(rawValue: "audioPlayerDidFinish")
    public static let currentRecordingDidChange = Notification.Name(rawValue: "currentRecordingDidChange")
    public static let playRecordDidStart = Notification.Name(rawValue: "playRecordDidStart")
    public static let playRecordDidStop = Notification.Name(rawValue: "playRecordDidStop")
}

