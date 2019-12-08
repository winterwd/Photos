//
//  TapDetectingView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/23.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

protocol TapDetectingViewDelegate: class {
    func view(_ view: UIView, singleTapDetected touch: UITouch)
    func view(_ view: UIView, doubleTapDetected touch: UITouch)
//    @objc optional func view(_ view: UIView, tripleTapDetected touch: UITouch)
}

extension TapDetectingViewDelegate {
    func view(_ view: UIView, singleTapDetected touch: UITouch) {}
    func view(_ view: UIView, doubleTapDetected touch: UITouch) {}
}

class TapDetectingView: UIView {

    weak var tapDelegate: TapDetectingViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        switch touch.tapCount {
        case 1:
            tapDelegate?.view(self, singleTapDetected: touch)
            break
        case 2:
            tapDelegate?.view(self, doubleTapDetected: touch)
            break
//        case 3:
//            tapDelegate?.view!(self, tripleTapDetected: touch)
//            break
        default:
            break
        }
    }
}
