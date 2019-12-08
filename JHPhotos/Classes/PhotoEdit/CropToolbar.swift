//
//  CropToolbar.swift
//  JHPhotos
//
//  Created by winter on 2017/8/24.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

fileprivate func delayFunc(seconds: TimeInterval, action: @escaping () -> Void) {
    let delayTime = DispatchTime.now() + seconds
    DispatchQueue.main.asyncAfter(deadline: delayTime, execute: action)
}

class CropToolbar: UIView {
    
    var cancelBttonAction: (() -> Void)?
    var rotateBttonAction: (() -> Void)?
    var resetBttonAction: (() -> Void)?
    var doneBttonAction: (() -> Void)?
    
    var statusBarVisible = false
    
    var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(CropToolbarImage.cancelImage(), for: .normal)
        button.tag = 1000
        return button
    }()
    
    var rotateButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .center
        button.setImage(CropToolbarImage.rotateImage(), for: .normal)
        button.tintColor = UIColor.white
        button.tag = 1001
        return button
    }()
    
    var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .center
        button.setImage(CropToolbarImage.resetImage(), for: .normal)
        button.tintColor = UIColor.white
        button.isEnabled = false
        button.tag = 1002
        return button
    }()
    
    var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(CropToolbarImage.doneImage(), for: .normal)
        button.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        button.isEnabled = false
        button.tag = 1003
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        addSubview(cancelButton)
        addSubview(rotateButton)
        addSubview(resetButton)
        addSubview(doneButton)
        
        cancelButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        rotateButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
    }
    
    @objc private func buttonAction(_ sender: UIButton) {
        sender.isEnabled = false
        switch sender.tag {
        case 1000:  cancelBttonAction?();  break
        case 1001:
            rotateBttonAction?()
            delayFunc(seconds: 0.4) {
                sender.isEnabled = true
            }
            break
        case 1002:  resetBttonAction?();  break
        case 1003:  doneBttonAction?();  break
        default:
            break
        }
    }
    
    func resetButtonEnabled() -> Bool {
        return resetButton.isEnabled
    }
    
    func set(resetButtonEnabled enabled: Bool) {
        resetButton.isEnabled = enabled
        doneButton.isEnabled = enabled
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // 宽度大于高度，就是竖屏
        let boundsSize = self.bounds.size
        let verticalLayout = boundsSize.width > boundsSize.height
        
        if verticalLayout {
            // 竖屏
            let height: CGFloat = 44.0
            let width: CGFloat = boundsSize.width / 4.0
            var frame = CGRect(x: 0, y: 0, width: width, height: height)
            cancelButton.frame = frame
            
            frame.origin.x = width
            rotateButton.frame = frame
            
            frame.origin.x = 2 * width
            resetButton.frame = frame
            
            frame.origin.x = boundsSize.width - width
            doneButton.frame = frame
        }
        else {
            // 横屏
            let offsetY: CGFloat = statusBarVisible ? 20.0 : 0.0
            let width: CGFloat = 44.0
            let height: CGFloat = (boundsSize.height - offsetY) / 4.0
            var frame = CGRect(x: 0, y: offsetY, width: width, height: height)
            cancelButton.frame = frame
            
            frame.origin.y = height + offsetY
            rotateButton.frame = frame
            
            frame.origin.y = 2 * height + offsetY
            resetButton.frame = frame
            
            frame.origin.y = boundsSize.height - height
            doneButton.frame = frame
        }
    }
}

fileprivate struct CropToolbarImage {
    
    static func doneImage() -> UIImage? {
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
    
    static func cancelImage() -> UIImage? {
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
    
    static func rotateImage() -> UIImage? {
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
    
    static func resetImage() -> UIImage? {
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
