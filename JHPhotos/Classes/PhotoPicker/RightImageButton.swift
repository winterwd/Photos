//
//  RightImageButton.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

class RightImageButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let space: CGFloat = 4
        let selfW = self.bounds.width
        let selfH = self.bounds.height
        
        if let imageV = self.imageView {
            var imageF = imageV.frame
            let imageW: CGFloat = imageF.width
            if let label = self.titleLabel {
                label.center = CGPoint(x: selfW / 2.0 - imageW / 2.0 - space, y: selfH / 2.0)
                imageF.origin.x = label.frame.maxX + space
                imageV.frame = imageF
                imageV.center = CGPoint(x: imageV.center.x, y: selfH / 2.0)
            }
        }
    }
}
