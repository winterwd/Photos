
//
//  DragCellCollectionView.swift
//  JHPhotos
//
//  Created by winter on 2017/8/16.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public protocol DragCellCollectionViewDelegate: class {
    
    // option
    
    /// 拖动交换位置
    ///
    /// - Parameters:
    ///   - collectionView: collectionView
    ///   - sourceIndex: 拖动的cell的index
    ///   - destinationIndex: 拖动至被替换的位置index
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndex: Int, to destinationIndex: Int)
    
    /// 拖动删除某一个
    ///
    /// - Parameters:
    ///   - collectionView: collectionView
    ///   - index: 将要被删除的cell index
    func collectionView(_ collectionView: UICollectionView, deleteItemAt index: Int)
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
}

public extension DragCellCollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndex: Int, to destinationIndex: Int) {}
    
    func collectionView(_ collectionView: UICollectionView, deleteItemAt index: Int) {}
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {}
}

public protocol DragCellCollectionViewDataSource: class  {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
}

public final class DragCellCollectionView: UICollectionView {
    
    weak public var myDelegate: DragCellCollectionViewDelegate? {
        didSet {
            self.delegate = self as UICollectionViewDelegate
        }
    }
    
    weak public var myDataSource: DragCellCollectionViewDataSource? {
        didSet {
            self.dataSource = self as UICollectionViewDataSource
        }
    }
    // 当前显示的viewController
    weak fileprivate var topView: UIView?
    // 截图cell 用来移动
    fileprivate var snapMoveCell: UIView?
    // 手指所在cell的Point
    fileprivate var lastPoint: CGPoint = CGPoint.zero
    // 手指所在cell的indexPath
    fileprivate var sourceIndexPath: IndexPath?
    // 将被替换cell的index
    fileprivate var destinationIndexPath: IndexPath?
    
    fileprivate var isWillDeleted: Bool = false
    
    fileprivate lazy var deleteIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "jp_icon_delete_dny")
        return imgView
    }()
    
    
    fileprivate lazy var deletedLab: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.alpha = 0.8
        label.text = "拖动到此处删除"
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.backgroundColor = .clear
        return label
    }()
    
    fileprivate lazy var deletedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red:0.89,green:0.29,blue:0.28,alpha:1.00)
        
        view.addSubview(deleteIcon)
        view.addSubview(deletedLab)
        
        deleteIcon.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(10)
            make.size.equalTo(CGSize(width: 20, height: 20))
        })
        
        deletedLab.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(deleteIcon.snp.bottom).offset(6)
        })
        
        return view
    }()
    
    fileprivate var minimumPressDuration: CFTimeInterval = 0.5
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupSome()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSome()
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if topView == nil {
            if let topVC = SystemHelper.presentingViewController() {
                topView = topVC.view
            }
        }
    }
    
    fileprivate func setupSome() {
        self.backgroundColor = UIColor.white
        self.isScrollEnabled = false
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        addLongPressGestureRecognizer()
    }
}

// MARK: - LongPressGestureRecognizer

fileprivate extension DragCellCollectionView {
    func addLongPressGestureRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(longPressGesture:)))
        longPress.minimumPressDuration = minimumPressDuration;
        self.addGestureRecognizer(longPress);
    }
    
    @objc
    func longPressAction(longPressGesture: UILongPressGestureRecognizer) {
        switch longPressGesture.state {
        case .began:
            self.gestureBegan(longPressGesture)
                break
        case .changed:
            self.gestureChange(longPressGesture)
                break
        case .ended:
            self.gestureEnded(longPressGesture)
                break
        default:
            break
        }
    }
    
    func gestureBegan(_ gesture: UILongPressGestureRecognizer) {
        updateDeleteView(false)
        let point = gesture.location(ofTouch: 0, in: gesture.view)
        guard let indexPath = self.indexPathForItem(at: point) else {
            return
        }
        self.sourceIndexPath = indexPath
        if let topView = topView, let cell = self.cellForItem(at: indexPath) {
            lastPoint = self.convert(point, to: topView)
            
            if let moveCell = cell.snapshotView(afterScreenUpdates: false) {
                cell.isHidden = true
                
                let frame = self.convert(cell.frame, to: topView)
                moveCell.frame = frame
                topView.addSubview(moveCell)
                self.snapMoveCell = moveCell
                
                topView.addSubview(self.deletedView)
                self.deletedView.frame = CGRect(x: 0, y: topView.bounds.height, width: topView.bounds.width, height: 60.0 + kBottomSpace)
                let deleteFrame = CGRect(x: 0, y: topView.bounds.height - (60.0 + kBottomSpace), width: topView.bounds.width, height: 60.0 + kBottomSpace)
                
                let amp: CGFloat = 5
                let ampFrame = CGRect(x: frame.origin.x - amp/2.0, y: frame.origin.y - amp/2.0, width: frame.size.width + amp, height: frame.size.height + amp)
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.snapMoveCell?.alpha = 0.7
                    self.snapMoveCell?.frame = ampFrame
                    self.deletedView.frame = deleteFrame
                })
            }
        }
    }
    
    func gestureChange(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(ofTouch: 0, in: topView)
        let transX = point.x - lastPoint.x
        let transY = point.y - lastPoint.y
        if let view = snapMoveCell {
            let center = view.center
            view.center = center.applying(CGAffineTransform(translationX: transX, y: transY))
            lastPoint = point
            
            exchangeCell()
        }
    }
    
    func gestureEnded(_ gesture: UILongPressGestureRecognizer) {
        if let indexPath = self.sourceIndexPath {
            if isWillDeleted {
                // 删除操作
                if let d = self.myDelegate {
                    d.collectionView(self, deleteItemAt: indexPath.item)
                }
                self.snapMoveCell?.removeFromSuperview()
                self.deletedView.removeFromSuperview()
                return
            }
            
            if let topView = topView {
                if let cell = self.cellForItem(at: indexPath) {
                    let frame = self.convert(cell.frame, to: topView)
                    let deleteFrame = CGRect(x: 0, y: topView.bounds.height, width: topView.bounds.width, height: 60.0)
                    UIView.animate(withDuration: 0.25, animations: {
                        self.snapMoveCell?.frame = frame
                        self.deletedView.frame = deleteFrame
                    }, completion: { (suc) in
                        cell.isHidden = false
                        self.snapMoveCell?.removeFromSuperview()
                        self.deletedView.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    func exchangeCell() {
        
        if let view = snapMoveCell {
            do {
                let height = view.frame.size.height
                let center = view.center
                let originLeftTop = view.frame.origin
                let originLeftBottom = CGPoint(x: originLeftTop.x, y: originLeftTop.y + height)
                let originRightTop = CGPoint(x: originLeftTop.x + height, y: originLeftTop.y)
                let originRightBottom = CGPoint(x: originLeftTop.x + height, y: originLeftTop.y + height)
                
                let containDelete = deletedView.frame.contains(center) || deletedView.frame.contains(originLeftTop) || deletedView.frame.contains(originLeftBottom) || deletedView.frame.contains(originRightTop) || deletedView.frame.contains(originRightBottom)
                updateDeleteView(containDelete)
                if containDelete {
                    return
                }
            }
            
            for cell in self.visibleCells {
                guard sourceIndexPath != self.indexPath(for: cell) else {
                    continue
                }
                // 计算碰撞
                let center = self.convert(cell.center, to: topView)
                let spacX = abs(view.center.x - center.x)
                let spacY = abs(view.center.y - center.y)
                // 当前截图view 与可见cell 的中心距离 是否重合
                let containCell = spacX <= view.bounds.width/2.0 && spacY <= view.bounds.height/2.0
                if containCell {
                    // 交换
                    // print("碰撞了-------")
                    if let source = sourceIndexPath, let destination = self.indexPath(for: cell) {
                        self.myDelegate?.collectionView(self, moveItemAt: source.item, to: destination.item)
                        self.moveItem(at: source, to: destination)
                        sourceIndexPath = destination
                        return
                    }
                }
            }
        }
    }
    
    func updateDeleteView(_ contain: Bool)  {
        isWillDeleted = contain
        deletedLab.text = "拖动到此处删除"
        deletedView.backgroundColor = UIColor(red:0.89,green:0.29,blue:0.28,alpha:1.00)
        if contain {
            deletedLab.text = "松手即可删除"
            deletedView.backgroundColor = UIColor(red:0.80,green:0.26,blue:0.26,alpha:1.00)
        }
    }
}

extension DragCellCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let d = self.myDataSource {
            return d.collectionView(collectionView, numberOfItemsInSection: section)
        }
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.myDataSource?.collectionView(collectionView, cellForItemAt:indexPath)
        return cell!
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let d = self.myDelegate {
            return d.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }
}
