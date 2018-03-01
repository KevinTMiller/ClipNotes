//
//  UIImage+ImageFromString.swift
//  AVNotes
//
//  Created by Kevin Miller on 3/1/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import AVKit
import Foundation

enum LabelSpecs {
    static let width: CGFloat = 30.0
    static let fontSize: CGFloat = 8.0
    static let height: CGFloat = 10.0
}

extension UIImage {
    class func imageFromString(string: String) -> UIImage {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: LabelSpecs.width, height: LabelSpecs.height))
        label.text = string
        label.font = UIFont.systemFont(ofSize: LabelSpecs.fontSize, weight: .light)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = false
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
}
