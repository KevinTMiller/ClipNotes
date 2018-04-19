//
//  GradientManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/25/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class GradientManager: NSObject {

    enum Constants {
        static let duration: CFTimeInterval = 7.0
        static let colorKeyPath = "colors"
        static let colorChange = "colorChange"
    }
    var currentUIColors: [UIColor] {
        return currentColor.map { UIColor(cgColor: $0) }
    }
    private var nextColor = [CGColor]()
    private var currentColor = [CGColor]()
    private var gradientLayers = [CAGradientLayer]()
    
    private lazy var managedViews = [UIView]()
    private lazy var index = UserDefaults.standard.value(forKey: "gradient") as? Int ?? 0
    private lazy var keyDictionary = ["Initial", "Vanusa", "eXpresso", "Red Sunset", "Taran Tado",
                                 "Purple Bliss"]
    private lazy var gradientDictionary: [String: [CGColor]] = [
        "Initial":       [UIColor(red:0.95, green:0.12, blue:0.15, alpha:1.0).cgColor,
                          UIColor(red:0.88, green:0.09, blue:0.56, alpha:1.0).cgColor],
        "Vanusa":       [UIColor(red: 0.85, green: 0.27, blue: 0.33, alpha: 1.0).cgColor,
                         UIColor(red: 0.54, green: 0.13, blue: 0.42, alpha: 1.0).cgColor],
        "eXpresso":     [UIColor(red: 0.68, green: 0.33, blue: 0.54, alpha: 1.0).cgColor,
                         UIColor(red: 0.24, green: 0.06, blue: 0.33, alpha: 1.0).cgColor],
        "Red Sunset":   [UIColor(red: 0.21, green: 0.36, blue: 0.49, alpha: 1.0).cgColor,
                         UIColor(red: 0.42, green: 0.36, blue: 0.48, alpha: 1.0).cgColor,
                         UIColor(red: 0.75, green: 0.42, blue: 0.52, alpha: 1.0).cgColor],
        "Taran Tado":   [UIColor(red: 0.14, green: 0.03, blue: 0.30, alpha: 1.0).cgColor,
                         UIColor(red: 0.80, green: 0.33, blue: 0.20, alpha: 1.0).cgColor],
        "Purple Bliss": [UIColor(red: 0.21, green: 0.00, blue: 0.20, alpha: 1.0).cgColor,
                         UIColor(red: 0.04, green: 0.53, blue: 0.58, alpha: 1.0).cgColor]
    ]

    // Eventually will implement user settings to select gradient
    // that's why using key here. Can refactor to accept a string
    // based on user choice

    func cycleGradient() {
        currentColor = gradientDictionary[keyDictionary[index]]!
        if index == keyDictionary.count - 1 { index = 0 } else { index += 1 }
        nextColor = gradientDictionary[keyDictionary[index]]!
        updateViewsWithGradient()
    }
    
    func redrawGradients() {
        for i in 0 ..< gradientLayers.count { //swiftlint:disable:this identifier_name
            gradientLayers[i].frame = managedViews[i].bounds
        }
    }

    // May want to add more gradient views later.
    func addManagedView(_ view: UIView) {
        guard let colors = gradientDictionary[keyDictionary.first!] else { return }
        let gradient = CAGradientLayer()
        gradient.bounds = CGRect(x: 0,
                                 y: 0,
                                 width: view.bounds.width,
                                 height: view.bounds.height)
        gradient.position = view.center
        gradient.colors = colors
        view.layer.addSublayer(gradient)
        gradientLayers.append(gradient)
        managedViews.append(view)

        if let button = view as? UIButton {
            button.bringSubview(toFront: button.imageView!)
        }
    }

    private func updateViewsWithGradient() {

        for gradient in gradientLayers {
            let animation = CABasicAnimation(keyPath: Constants.colorKeyPath)
            animation.duration = Constants.duration
            animation.fromValue = currentColor
            animation.toValue = nextColor
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            gradient.add(animation, forKey: Constants.colorChange)
        }
    }
}
