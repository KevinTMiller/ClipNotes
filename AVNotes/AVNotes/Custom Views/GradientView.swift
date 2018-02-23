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
    private var keyDictionary = ["Vanusa", "eXpresso", "Red Sunset", "Taran Tado",
                                "Purple Bliss"]
    
    private var gradientDictionary = [
        "Vanusa" :    [UIColor(red:0.85, green:0.27, blue:0.33, alpha:1.0).cgColor,
                       UIColor(red:0.54, green:0.13, blue:0.42, alpha:1.0).cgColor],
        "eXpresso" :   [UIColor(red:0.68, green:0.33, blue:0.54, alpha:1.0).cgColor,
                        UIColor(red:0.24, green:0.06, blue:0.33, alpha:1.0).cgColor],
        "Red Sunset" : [UIColor(red:0.21, green:0.36, blue:0.49, alpha:1.0).cgColor,
                        UIColor(red:0.42, green:0.36, blue:0.48, alpha:1.0).cgColor,
                        UIColor(red:0.75, green:0.42, blue:0.52, alpha:1.0).cgColor],
        "Taran Tado" : [UIColor(red:0.14, green:0.03, blue:0.30, alpha:1.0).cgColor,
                        UIColor(red:0.80, green:0.33, blue:0.20, alpha:1.0).cgColor],
        "Purple Bliss" : [UIColor(red:0.21, green:0.00, blue:0.20, alpha:1.0).cgColor,
                          UIColor(red:0.04, green:0.53, blue:0.58, alpha:1.0).cgColor],
    ]
}

