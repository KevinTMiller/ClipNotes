//
//  CurvedTransparencyView.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/31/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class CurvedTransparencyView: UIView {
    
    var path: UIBezierPath!
    
    override func draw(_ rect: CGRect) {
        createCurve()
        UIColor.white.setFill()
        path.fill()
    }
    
    func createCurve() {
        path = UIBezierPath()
        let controlPoint2 = CGPoint(x: bounds.maxX / 3, y: bounds.maxY / 2)
        let controlPoint1 = CGPoint(x: bounds.maxX * 0.25, y: bounds.maxY * 0.75)
        path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY / 2 ))
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
        path.addCurve(to: CGPoint(x: bounds.minX, y: bounds.maxY / 2 ), controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        path.close()

    }
    

}
