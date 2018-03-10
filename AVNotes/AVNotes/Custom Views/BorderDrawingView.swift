//
//  BorderDrawingView.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/31/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class BorderDrawingView: UIView {

    enum Constants {
        static let cornerRadius: CGFloat = 20.0
        static let inset: CGFloat = 3.0
        static let lineWidth: CGFloat = 2.0
    }

    var centerLine: UIBezierPath!
    var path: UIBezierPath!

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawRoundedRect()
        drawCenterLine()
        UIColor.white.setStroke()
        centerLine.lineWidth = Constants.lineWidth
        path.lineWidth = Constants.lineWidth
        path.lineJoinStyle = .round
        path.stroke()
        centerLine.stroke()
    }

    func drawRoundedRect() {
    let rect = self.bounds.insetBy(dx: Constants.inset, dy: Constants.inset)
    path = UIBezierPath(roundedRect: rect, cornerRadius: Constants.cornerRadius)
    }

    func drawCenterLine() {
    centerLine = UIBezierPath()
        centerLine.move(to: CGPoint(x: 2.0, y: bounds.height / 2.0))
        centerLine.addLine(to: CGPoint(x: bounds.maxX - 2.0, y: bounds.height / 2.0))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.clipsToBounds = false
        layer.masksToBounds = false
    }
}
