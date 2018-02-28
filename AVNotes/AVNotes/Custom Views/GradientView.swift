//
//  GradientView.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/26/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    var gradientLayer = CAGradientLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
    }
}
