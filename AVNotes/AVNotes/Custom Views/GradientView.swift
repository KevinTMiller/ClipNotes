//
//  GradientView.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/26/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class GradientView: UIView {
    

    override func layoutSubviews() {
         super.layoutSubviews()
        setGradient()
    }
    
    func setGradient() {
        gradientLayer.bounds = self.bounds
        gradientLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        gradientLayer.colors = gradientDictionary[keyDictionary[index]]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(gradientLayer)
    }
    
    func changeGradient() {

        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 5.0
        animation.toValue = gradientDictionary[keyDictionary[index]]
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        gradientLayer.add(animation, forKey: nil)
        if index == keyDictionary.count - 1 {index = 0} else {index += 1}
        UserDefaults.standard.set(index, forKey: "gradient")
    }
    
    private var index = UserDefaults.standard.value(forKey: "gradient") as? Int ?? 0
    private var gradientLayer = CAGradientLayer()
    private var keyDictionary = ["Vanusa", "eXpresso", "Pure Lust", "Red Sunset", "Taran Tado",
                                 "Shift", "Crystal Clear", "Forest", "Purple Bliss", "Lawrencium"]
    
    private var gradientDictionary = [
        "Vanusa" :    [UIColor(red:0.85, green:0.27, blue:0.33, alpha:1.0).cgColor,
                       UIColor(red:0.54, green:0.13, blue:0.42, alpha:1.0).cgColor],
        "eXpresso" :   [UIColor(red:0.68, green:0.33, blue:0.54, alpha:1.0).cgColor,
                        UIColor(red:0.24, green:0.06, blue:0.33, alpha:1.0).cgColor],
        "Pure Lust" :  [UIColor(red:0.20, green:0.20, blue:0.20, alpha:1.0).cgColor,
                        UIColor(red:0.87, green:0.09, blue:0.09, alpha:1.0).cgColor],
        "Red Sunset" : [UIColor(red:0.21, green:0.36, blue:0.49, alpha:1.0).cgColor,
                        UIColor(red:0.42, green:0.36, blue:0.48, alpha:1.0).cgColor,
                        UIColor(red:0.75, green:0.42, blue:0.52, alpha:1.0).cgColor],
        "Taran Tado" : [UIColor(red:0.14, green:0.03, blue:0.30, alpha:1.0).cgColor,
                        UIColor(red:0.80, green:0.33, blue:0.20, alpha:1.0).cgColor],
        "Shift" : [UIColor(red:0.00, green:0.00, blue:0.00, alpha:1.0).cgColor,
                   UIColor(red:0.90, green:0.00, blue:0.55, alpha:1.0).cgColor,
                   UIColor(red:1.00, green:0.03, blue:0.04, alpha:1.0).cgColor],
        "Crystal Clear" : [UIColor(red:0.08, green:0.60, blue:0.34, alpha:1.0).cgColor,
                           UIColor(red:0.08, green:0.34, blue:0.60, alpha:1.0).cgColor],
        "Forest" : [UIColor(red:0.35, green:0.25, blue:0.22, alpha:1.0).cgColor,
                    UIColor(red:0.17, green:0.47, blue:0.27, alpha:1.0).cgColor],
        "Purple Bliss" : [UIColor(red:0.21, green:0.00, blue:0.20, alpha:1.0).cgColor,
                          UIColor(red:0.04, green:0.53, blue:0.58, alpha:1.0).cgColor],
        "Lawrencium" : [UIColor(red:0.06, green:0.05, blue:0.16, alpha:1.0).cgColor,
                        UIColor(red:0.19, green:0.17, blue:0.39, alpha:1.0).cgColor,
                        UIColor(red:0.14, green:0.14, blue:0.24, alpha:1.0).cgColor]
    ]
}

