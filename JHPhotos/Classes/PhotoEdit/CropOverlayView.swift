//
//  CropOverlayView.swift
//  JHPhotos
//
//  Created by winter on 2017/8/23.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

public final class CropOverlayView: UIView {

    /// 隐藏内部网格线
    fileprivate var gridHidden:Bool = false {
        didSet {
            setGrid(hidden: gridHidden, animated: false)
        }
    }
    
    /// 添加/移除内部水平网格线
    public var displayHorizontalGridLines = false {
        didSet{
            setDisplayHorizontalGridLines(displayHorizontalGridLines)
        }
    }
    
    /// 添加/移除内部垂直网格线
    public var displayVerticalGridLines = false {
        didSet{
            setDisplayVerticalGridLines(displayVerticalGridLines)
        }
    }
    
    fileprivate let CropOverLayerCornerWidth: CGFloat = 20.0
    
    fileprivate var verticalGridLines: [UIView] = []
    fileprivate var horizontalGridLines: [UIView] = []
    
    // top, right, bottom, left
    fileprivate var outerLineViews: [UIView] = []
    
    // vertical, horizontal
    fileprivate var topLeftLineViews: [UIView] = []
    fileprivate var topRightLineViews: [UIView] = []
    fileprivate var bottomLeftLineViews: [UIView] = []
    fileprivate var bottomRightLineViews: [UIView] = []
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.superview != nil {
            layoutLines()
        }
    }
    
    public override var frame: CGRect {
        didSet {
            layoutLines()
        }
    }
    
    /// 显示和隐藏内部网格线, 是否渐变动画
    ///
    /// - Parameters:
    ///   - hidden: 显示和隐藏内部网格线
    ///   - animated: 是否交叉渐变动画
    public func setGrid(hidden: Bool, animated: Bool) {
        if !animated {
            for line in horizontalGridLines {
                line.alpha = hidden ? 0.0 : 1.0
            }
            for line in verticalGridLines {
                line.alpha = hidden ? 0.0 : 1.0
            }
            return
        }
        
        UIView.animate(withDuration: hidden ? 0.35 : 0.2, animations: {
            for line in self.horizontalGridLines {
                line.alpha = hidden ? 0.0 : 1.0
            }
            for line in self.verticalGridLines {
                line.alpha = hidden ? 0.0 : 1.0
            }
        })
    }
}

fileprivate extension CropOverlayView {
    
    func createNewLine(forGrid yesOrNO: Bool) -> UIView {
        let line = UIView(frame: CGRect.zero)
        let alpha: CGFloat = yesOrNO ? 0.6 : 1.0
        line.backgroundColor = UIColor.init(white: 1, alpha: alpha)
        self.addSubview(line)
        return line
    }
    
    func setDisplayHorizontalGridLines(_ isDisplay: Bool) {
        for line in horizontalGridLines {
            line.removeFromSuperview()
        }
        if isDisplay {
            horizontalGridLines.append(contentsOf: [createNewLine(forGrid: true), createNewLine(forGrid: true)])
        }
        else {
            horizontalGridLines.removeAll()
        }
        self.setNeedsDisplay()
    }
    
    func setDisplayVerticalGridLines(_ isDisplay: Bool) {
        for line in verticalGridLines {
            line.removeFromSuperview()
        }
        if isDisplay {
            verticalGridLines.append(contentsOf: [createNewLine(forGrid: true), createNewLine(forGrid: true)])
        }
        else {
            verticalGridLines.removeAll()
        }
        self.setNeedsDisplay()
    }
    
    func setup() {
        self.clipsToBounds = false
        
//        func createNewBorderLine() -> UIView {
//            let line = UIView(frame: CGRect.zero)
//            line.backgroundColor = UIColor.white
//            line.layer.shadowColor  = UIColor.black.cgColor
//            line.layer.shadowOffset = CGSize.zero
//            line.layer.shadowRadius = 1.5
//            line.layer.shadowOpacity = 0.8
//            self.addSubview(line)
//            return line
//        }
        
        for i in 0...3 {
            if i <= 1 {
                topLeftLineViews.append(createNewLine(forGrid: false))
                topRightLineViews.append(createNewLine(forGrid: false))
                bottomLeftLineViews.append(createNewLine(forGrid: false))
                bottomRightLineViews.append(createNewLine(forGrid: false))
            }
            outerLineViews.append(createNewLine(forGrid: false))
        }
        
        displayHorizontalGridLines = true
        displayVerticalGridLines = true
    }
    
    func layoutLines() {
        if outerLineViews.count == 0 {
            return
        }
        // 外侧四条线
        let size = self.bounds.size
        for i in 0...3 {
            let line = outerLineViews[i]
            var frame = CGRect.zero
            switch i {
            case 0: frame = CGRect(x: 0, y: -1.0, width: size.width + 2.0, height: 1.0); break // top
            case 1: frame = CGRect(x: size.width, y: 0, width: 1.0, height: size.height); break // right
            case 2: frame = CGRect(x: -1.0, y: size.height, width: size.width + 2.0, height: 1.0); break // bottom
            case 3: frame = CGRect(x: -1.0, y: 0, width: 1.0, height: size.height + 1.0); break // left
            default: break
            }
            line.frame = frame
        }
        
        // 四角
        let wh: CGFloat = 3.0
        let cornerLines = [topLeftLineViews, topRightLineViews, bottomRightLineViews, bottomLeftLineViews]
        for i in 0...3 {
            let cornerLine = cornerLines[i]
            var verticalFrame = CGRect.zero
            var horizontalFrame = CGRect.zero
            switch i {
            case 0: // top left
                verticalFrame = CGRect(x: -wh, y: -wh, width: wh, height: CropOverLayerCornerWidth + wh)
                horizontalFrame = CGRect(x: 0, y: -wh, width: CropOverLayerCornerWidth + wh, height: wh)
                break
            case 1: // top right
                verticalFrame = CGRect(x: size.width, y: -wh, width: wh, height: CropOverLayerCornerWidth + wh)
                horizontalFrame = CGRect(x: size.width - CropOverLayerCornerWidth, y: -wh, width: CropOverLayerCornerWidth, height: wh)
                break
            case 2: // bottom right
                verticalFrame = CGRect(x: size.width, y: size.height-CropOverLayerCornerWidth, width: wh, height: CropOverLayerCornerWidth + wh)
                horizontalFrame = CGRect(x: size.width - CropOverLayerCornerWidth, y: size.height, width: CropOverLayerCornerWidth, height: wh)
                break
            case 3: // bottom left
                verticalFrame = CGRect(x: -wh, y: size.height-CropOverLayerCornerWidth, width: wh, height: CropOverLayerCornerWidth)
                horizontalFrame = CGRect(x: -wh, y: size.height, width: CropOverLayerCornerWidth + wh, height: wh)
                break
            default:
                break
            }
            cornerLine[0].frame = verticalFrame
            cornerLine[1].frame = horizontalFrame
        }
        
        // 内部栅格 水平线
        let thickness = 1.0 / UIScreen.main.scale
        var numberOfLines = horizontalGridLines.count
        var padding = (size.height - thickness * CGFloat(numberOfLines)) / CGFloat(numberOfLines + 1)
        for i in 0..<numberOfLines {
            let line = horizontalGridLines[i]
            let frame = CGRect(x: 0, y: (padding + thickness) * CGFloat(i) + padding, width: size.width, height: thickness)
            line.frame = frame
        }
        // 内部栅格 水平线
        numberOfLines = verticalGridLines.count
        padding = (size.width - thickness * CGFloat(numberOfLines)) / CGFloat(numberOfLines + 1)
        for i in 0..<numberOfLines {
            let line = verticalGridLines[i]
            let frame = CGRect(x: (padding + thickness) * CGFloat(i) + padding, y: 0, width: thickness, height: size.height)
            line.frame = frame
        }
    }
}
