//
//  BorderDrawingView.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/31/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class BorderDrawingView: UIView {
    
    var path: UIBezierPath!
    var centerLine: UIBezierPath!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        drawRoundedRect()
        drawCenterLine()
        UIColor.white.setStroke()
        centerLine.lineWidth = 2.0
        path.lineWidth = 2.0
        path.lineJoinStyle = .round
        path.stroke()
        centerLine.stroke()
        
    }
    
    func drawRoundedRect() {
    
    let rect = self.bounds.insetBy(dx: 3, dy: 3)
    path = UIBezierPath.init(roundedRect: rect, cornerRadius: 20.0)

    }
    
    func drawCenterLine() {
    centerLine = UIBezierPath()
        centerLine.move(to: CGPoint(x: 2.0, y: bounds.height / 2))
        centerLine.addLine(to: CGPoint(x: bounds.maxX - 2.0 , y: bounds.height / 2))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.clipsToBounds = false
        layer.masksToBounds = false
        
    }
}
