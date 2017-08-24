//
//  CropToolbar.swift
//  JHPhotos
//
//  Created by winter on 2017/8/24.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

class CropToolbar: UIView {
    
    var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(CropToolbar.doneImage(), for: .normal)
        button.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        return button
    }()
    
    var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(CropToolbar.cancelImage(), for: .normal)
        return button
    }()
    
    var rotateButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .center
        button.setImage(CropToolbar.rotateImage(), for: .normal)
        button.tintColor = UIColor.white
        return button
    }()
    
    var restButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .center
        button.setImage(CropToolbar.resetImage(), for: .normal)
        button.tintColor = UIColor.white
        button.isEnabled = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

fileprivate extension CropToolbar {
    
    class func doneImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 17, height: 14), false, 0)
        let rectanglePath = UIBezierPath()
        rectanglePath.move(to: CGPoint(x: 1, y: 7))
        rectanglePath.addLine(to: CGPoint(x: 6, y: 12))
        rectanglePath.addLine(to: CGPoint(x: 16, y: 1))
        UIColor.white.setStroke()
        rectanglePath.lineWidth = 2.0
        rectanglePath.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func cancelImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 16, height: 16), false, 0.0)
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 14, y: 14))
        bezierPath.addLine(to: CGPoint(x: 1, y: 1))
        UIColor.white.setStroke()
        bezierPath.lineWidth = 2.0
        bezierPath.stroke()
        
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 1, y: 14))
        bezier2Path.addLine(to: CGPoint(x: 14, y: 1))
        UIColor.white.setStroke()
        bezier2Path.lineWidth = 2.0
        bezier2Path.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func rotateImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 18, height: 21), false, 0.0)
        
        let rectanglePath = UIBezierPath(rect: CGRect(x: 0, y: 9, width: 12, height: 12))
        UIColor.white.setFill()
        rectanglePath.fill()
        
        // 向左小三角
        let polygonPath = UIBezierPath()
        polygonPath.move(to: CGPoint(x: 5, y: 3))
        polygonPath.addLine(to: CGPoint(x: 10, y: 6))
        polygonPath.addLine(to: CGPoint(x: 10, y: 0))
        polygonPath.addLine(to: CGPoint(x: 5, y: 3))
        polygonPath.close()
        UIColor.white.setFill()
        polygonPath.fill()

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 10, y: 3))
        bezierPath.addCurve(to: CGPoint(x: 17.5, y: 11.0), controlPoint1: CGPoint(x: 15, y: 3), controlPoint2: CGPoint(x: 17.5, y: 5.91))
        UIColor.white.setStroke()
        bezierPath.lineWidth = 1.0
        bezierPath.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func resetImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 22, height: 18), false, 0.0)
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 22, y: 9))
        
        bezierPath.addCurve(to: CGPoint(x: 13, y: 18), controlPoint1: CGPoint(x: 22, y: 13.97), controlPoint2: CGPoint(x: 17.97, y: 18))
        bezierPath.addCurve(to: CGPoint(x: 13, y: 16), controlPoint1: CGPoint(x: 13, y: 17.35), controlPoint2: CGPoint(x: 13, y: 16.68))
        bezierPath.addCurve(to: CGPoint(x: 20, y: 9), controlPoint1: CGPoint(x: 16.87, y: 16), controlPoint2: CGPoint(x: 20, y: 12.87))
        bezierPath.addCurve(to: CGPoint(x: 13, y: 2), controlPoint1: CGPoint(x: 20, y: 5.13), controlPoint2: CGPoint(x: 16.87, y: 2))
        bezierPath.addCurve(to: CGPoint(x: 6.55, y: 6.27), controlPoint1: CGPoint(x: 10.1, y: 2), controlPoint2: CGPoint(x: 7.62, y: 3.76))
        bezierPath.addCurve(to: CGPoint(x: 6, y: 9), controlPoint1: CGPoint(x: 6.2, y: 7.11), controlPoint2: CGPoint(x: 6, y: 8.03))
        
        bezierPath.addLine(to: CGPoint(x: 4, y: 9))
        
        bezierPath.addCurve(to: CGPoint(x: 4.65, y: 5.63), controlPoint1: CGPoint(x: 4, y: 7.81), controlPoint2: CGPoint(x: 4.23, y: 6.67))
        bezierPath.addCurve(to: CGPoint(x: 7.65, y: 1.76), controlPoint1: CGPoint(x: 5.28, y: 4.08), controlPoint2: CGPoint(x: 6.32, y: 2.74))
        bezierPath.addCurve(to: CGPoint(x: 13, y: 0), controlPoint1: CGPoint(x: 9.15, y: 0.65), controlPoint2: CGPoint(x: 11, y: 0))
        bezierPath.addCurve(to: CGPoint(x: 22, y: 9), controlPoint1: CGPoint(x: 17.97, y: 0), controlPoint2: CGPoint(x: 22, y: 4.03))

        bezierPath.close()
        UIColor.white.setFill()
        bezierPath.fill()
        
        // 向下小三角
        let polygonPath = UIBezierPath()
        polygonPath.move(to: CGPoint(x: 5, y: 15))
        polygonPath.addLine(to: CGPoint(x: 10, y: 9))
        polygonPath.addLine(to: CGPoint(x: 0, y: 9))
        polygonPath.addLine(to: CGPoint(x: 5, y: 15))
        polygonPath.close()
        UIColor.white.setFill()
        polygonPath.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
