//
//  CircularProgressView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/23.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import QuartzCore

class CircularProgressLayer: CALayer {
    
    // MARK: - property
    
    fileprivate var trackTintColor: UIColor = UIColor.white.withAlphaComponent(0.3)
    fileprivate var progressTintColor: UIColor = .white
    fileprivate var innerTintColor: UIColor?
    
    fileprivate var thicknessRatio: CGFloat = 0.15
    fileprivate var progress: CGFloat = 0.0
    
    fileprivate var roundedCorners: Bool = false
    fileprivate var clockwiseProgress: Bool = true
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == "progress" {
            return true
        }
        else {
            return super.needsDisplay(forKey: key)
        }
    }
    
    override func draw(in ctx: CGContext) {
        let rect = self.bounds
        let centerPoint = CGPoint(x: rect.width / 2.0, y: rect.height / 2.0)
        let radius = min(rect.height, rect.width) / 2.0
        
        let progress = min(self.progress, CGFloat(1.0 - Float.ulpOfOne))
        var radians: CGFloat = 0
        
        let clockwise = clockwiseProgress
        if clockwise {
            radians = progress * 2.0 * CGFloat.pi - CGFloat.pi * 0.5
        }
        else {
            radians = CGFloat.pi * 3 * 0.5 - progress * 2.0 * CGFloat.pi
        }
        
        ctx.setFillColor(trackTintColor.cgColor)
        let trackPath = CGMutablePath()
        trackPath.move(to: centerPoint)
        trackPath.addArc(center: centerPoint, radius: radius, startAngle: CGFloat.pi * 2, endAngle: 0, clockwise: true)
        trackPath.closeSubpath()
        ctx.addPath(trackPath)
        ctx.fillPath()

        if progress > 0.0 {
            ctx.setFillColor(progressTintColor.cgColor)
            let progressPath = CGMutablePath()
            progressPath.move(to: centerPoint)
            progressPath.addArc(center: centerPoint, radius: radius, startAngle: CGFloat.pi * 3 * 0.5, endAngle: radians, clockwise: !clockwise)
            progressPath.closeSubpath()
            ctx.addPath(progressPath)
            ctx.fillPath()
        }
        
        if progress > 0.0 && self.roundedCorners {
            let pathWidth = radius * self.thicknessRatio
            let xOffset = radius * (1.0 + (1.0 - (self.thicknessRatio / 2.0)) * CGFloat(cosf(Float(radians))))
            let yOffset = radius * (1.0 + (1.0 - (self.thicknessRatio / 2.0)) * CGFloat(sinf(Float(radians))))
            let endPoint = CGPoint(x: xOffset, y: yOffset)
            
            let startEllipseRect = CGRect(x: centerPoint.x - pathWidth / 2.0,
                                          y: 0.0,
                                          width: pathWidth,
                                          height: pathWidth)
            ctx.addEllipse(in: startEllipseRect)
            ctx.fillPath()
            
            let endEllipseRect = CGRect(x: endPoint.x - pathWidth / 2.0,
                                        y: endPoint.y - pathWidth / 2.0,
                                        width: pathWidth,
                                        height: pathWidth)
            ctx.addEllipse(in: endEllipseRect)
            ctx.fillPath()
        }

        ctx.setBlendMode(.clear)
        let innerRadius: CGFloat = radius * (1.0 - thicknessRatio)
        
        let clearRect = CGRect(x: centerPoint.x - innerRadius,
                               y: centerPoint.y - innerRadius,
                               width: innerRadius * 2.0,
                               height: innerRadius * 2.0)
        ctx.addEllipse(in: clearRect)
        ctx.fillPath()

        if let innerTintCgColor = innerTintColor?.cgColor {
            ctx.setBlendMode(.normal)
            ctx.setFillColor(innerTintCgColor)
            ctx.addEllipse(in: clearRect)
            ctx.fillPath()
        }
    }
}

class CircularProgressView: UIView, CAAnimationDelegate {
    
    // MARK: - self life
    
    fileprivate var indeterminateDuration: CGFloat = 2.0
    fileprivate var indeterminate: Bool = false
    fileprivate var circularProgressLayer: CircularProgressLayer!
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        circularProgressLayer = CircularProgressLayer.init(layer: self.layer)
        circularProgressLayer.frame = self.layer.bounds
        self.layer.addSublayer(circularProgressLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        let windowContentScale = UIApplication.shared.keyWindow?.screen.scale
        circularProgressLayer.contentsScale = windowContentScale!
        circularProgressLayer.setNeedsDisplay()
    }
    
    // MARK: - Progress
    
    func setProgress(_ progress: CGFloat) {
        self.setProgress(progress, animated: false, initialDelay: 0.0)
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool) {
        self.setProgress(progress, animated: animated, initialDelay: 0.0)
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool, initialDelay: CFTimeInterval) {
        let pinnedProgress = min(max(progress, 0), 1)
        let duration = abs(circularProgressLayer.progress - pinnedProgress)
        self.setProgress(progress, animated: animated, initialDelay: 0.0, withDuration: CFTimeInterval(duration))
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool, initialDelay: CFTimeInterval, withDuration duration: CFTimeInterval) {
        self.layer.removeAnimation(forKey: "indeterminateAnimation")
        circularProgressLayer.removeAnimation(forKey: "progress")
        
        let pinnedProgress = min(max(progress, 0), 1)
        if animated {
            let ani = CABasicAnimation(keyPath: "progress")
            ani.duration = duration
            ani.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            ani.fillMode = CAMediaTimingFillMode.forwards
            ani.fromValue = NSNumber(value: Float(circularProgressLayer.progress))
            ani.toValue = NSNumber(value: Float(pinnedProgress))
            ani.beginTime = CACurrentMediaTime() + initialDelay
            ani.delegate = self
            circularProgressLayer.add(ani, forKey: "progress")
        }
        else {
            circularProgressLayer.progress = progress
            circularProgressLayer.setNeedsDisplay()
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        let pinnedProgressNumber = anim.value(forKey: "toValue") as! CGFloat
        circularProgressLayer.progress = pinnedProgressNumber
    }
}
