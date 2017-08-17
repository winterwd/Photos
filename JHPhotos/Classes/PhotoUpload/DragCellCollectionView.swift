
//
//  DragCellCollectionView.swift
//  JHPhotos
//
//  Created by winter on 2017/8/16.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public protocol DragCellCollectionViewDelegate: UICollectionViewDelegate {
//    func dragCellCollectionView(collectionView: DragCellCollectionView, newDataArrayAfterMove newData:[Any])
    
}

public protocol DragCellCollectionViewDataSource: UICollectionViewDataSource {
//    func dragCellCollectionView(collectionView: DragCellCollectionView, newDataArrayAfterMove newData:[Any])
    
}

public final class DragCellCollectionView: UICollectionView {
    
    weak public var myDelegate: DragCellCollectionViewDelegate?
    weak public var myDataSource: DragCellCollectionViewDataSource?
    
    fileprivate var minimumPressDuration: CFTimeInterval = 1
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.addLongPressGestureRecognizer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addLongPressGestureRecognizer()
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
            self.gestureBegan(longPressGesture: longPressGesture)
                break
        case .changed:
            self.gestureChange(longPressGesture: longPressGesture)
                break
        case .cancelled:
            self.gestureCancelled(longPressGesture: longPressGesture)
                break
        default:
            break
        }
    }
    
    func gestureBegan(longPressGesture: UILongPressGestureRecognizer) {
        
    }
    
    func gestureChange(longPressGesture: UILongPressGestureRecognizer) {
        
    }
    
    func gestureCancelled(longPressGesture: UILongPressGestureRecognizer) {
        
    }
}
