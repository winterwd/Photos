
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
    
    weak public var myDelegate: DragCellCollectionViewDelegate? {
        didSet {
            self.delegate = myDelegate
        }
    }
    weak public var myDataSource: DragCellCollectionViewDataSource? {
        didSet {
            self.dataSource = myDataSource
        }
    }
    
    fileprivate var minimumPressDuration: CFTimeInterval = 1
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupSome()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSome()
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
            self.gestureBegan(longPressGesture: longPressGesture)
                break
        case .changed:
            self.gestureChange(longPressGesture: longPressGesture)
                break
        case .ended:
            self.gestureEnded(longPressGesture: longPressGesture)
                break
        default:
            break
        }
    }
    
    func gestureBegan(longPressGesture: UILongPressGestureRecognizer) {
        print("-----> gestureBegan")
    }
    
    func gestureChange(longPressGesture: UILongPressGestureRecognizer) {
        print("-----> gestureChange")
    }
    
    func gestureEnded(longPressGesture: UILongPressGestureRecognizer) {
        print("-----> gestureEnded")
    }
}
