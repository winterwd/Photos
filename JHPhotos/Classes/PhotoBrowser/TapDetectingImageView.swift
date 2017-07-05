//
//  TapDetectingImageView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/23.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

@objc protocol TapDetectingImageViewDelegate {
    @objc optional func imageView(_ imageView: UIImageView, singleTapDetected touchPoint: CGPoint)
    @objc optional func imageView(_ imageView: UIImageView, doubleTapDetected touchPoint: CGPoint)
//    @objc optional func imageView(_ imageView: UIImageView, tripleTapDetected touchPoint: CGPoint)
}

class TapDetectingImageView: UIImageView {
    
    weak var tapDelegate: TapDetectingImageViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        self.addGestureRecognizer()
    }
    
    override init(image: UIImage?) {
        super.init(image: image)
        isUserInteractionEnabled = true
        self.addGestureRecognizer()
    }
    
    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        isUserInteractionEnabled = true
        self.addGestureRecognizer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addGestureRecognizer() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapDetected(gesture:)))
        self.addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapDetected(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        // 双击时，单击失效
        singleTap.require(toFail: doubleTap)
        
//        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(tripleTapDetected(gesture:)))
//        tripleTap.numberOfTapsRequired = 3
//        self.addGestureRecognizer(tripleTap)
    }
    
    @objc private func singleTapDetected(gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: self)
        tapDelegate?.imageView!(self, singleTapDetected: touchPoint)
    }
    
    @objc private func doubleTapDetected(gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: self)
        tapDelegate?.imageView!(self, doubleTapDetected: touchPoint)
    }
    
//    @objc private func tripleTapDetected(gesture: UITapGestureRecognizer) {
//        let touchPoint = gesture.location(in: self)
//        tapDelegate?.imageView!(self, tripleTapDetected: touchPoint)
//    }
}
