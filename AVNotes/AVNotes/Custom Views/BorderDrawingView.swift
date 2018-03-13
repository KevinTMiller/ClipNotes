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
        static let centerLineWidth: CGFloat = 3.0
        static let cornerRadius: CGFloat = 20.0
        static let inset: CGFloat = 2.0
        static let lineWidth: CGFloat = 3.0
        static let maskInset: CGFloat = 1.0
        static let onePixel: CGFloat = 1 / UIScreen.main.scale
        static let trailingPosition: CGFloat = 0.94
    }

    var centerLine: UIBezierPath!
    var borderPath: UIBezierPath!
    var trailingLine: UIBezierPath!

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawRoundedRect()
        drawCenterLine()
        UIColor.white.setStroke()
        centerLine.lineWidth = Constants.centerLineWidth
        borderPath.lineWidth = Constants.lineWidth
        borderPath.lineJoinStyle = .round
        borderPath.stroke()
        centerLine.stroke()
    }

    func drawRoundedRect() {
    let rect = self.bounds.insetBy(dx: Constants.inset, dy: Constants.inset)
    borderPath = UIBezierPath(roundedRect: rect, cornerRadius: Constants.cornerRadius)
    }

    func drawCenterLine() {
    centerLine = UIBezierPath()
        centerLine.move(to: CGPoint(x: 2.0, y: bounds.height / 2.0))
        centerLine.addLine(to: CGPoint(x: bounds.maxX - 2.0, y: bounds.height / 2.0))
    }

    func drawTrailingLine() {
        let rect = self.bounds.insetBy(dx: Constants.inset, dy: Constants.inset)
        trailingLine = UIBezierPath()
        trailingLine.move(to: CGPoint(x: rect.maxX * Constants.trailingPosition,
                                      y: rect.minY))
        trailingLine.addLine(to: CGPoint(x: rect.maxX * Constants.trailingPosition,
                                         y: rect.maxY))
    }

    func makeViewMask() {
        let rect = self.bounds.insetBy(dx: Constants.maskInset, dy: Constants.maskInset)
        let maskPath = UIBezierPath(roundedRect: rect,
                                    cornerRadius: Constants.cornerRadius)
        let mask = CAShapeLayer()
        mask.path = maskPath.cgPath
        layer.mask = mask
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        makeViewMask()
        self.clipsToBounds = true
        layer.masksToBounds = true

    }
}
