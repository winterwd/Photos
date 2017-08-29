//
//  CropViewController.swift
//  JHPhotos
//
//  Created by winter on 2017/8/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

public protocol CropViewControllerDelegate: class {
    func cropViewController(_ cropViewController: CropViewController, didCropToRect: CGRect, angle: Int)
    func cropViewController(_ cropviewController: CropViewController, didCropToImage: UIImage, rect: CGRect, angle: Int)
    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage: UIImage, rect: CGRect, angle: Int)
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled: Bool)
}

extension CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToRect: CGRect, angle: Int) {}
    func cropViewController(_ cropviewController: CropViewController, didCropToImage: UIImage, rect: CGRect, angle: Int) {}
    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage: UIImage, rect: CGRect, angle: Int) {}
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled: Bool) {}
}

public final class CropViewController: UIViewController {
    
    public weak var delegate: CropViewControllerDelegate?
    
    public convenience init(image originImage: UIImage) {
        self.init(image: originImage, delegate: nil)
    }
    
    public init(image originImage: UIImage, delegate:CropViewControllerDelegate?) {
        self.delegate = delegate
        self.image = originImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var image: UIImage!
    var cropView: CropView!
    var toolbar: CropToolbar!

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCropView()
        setupToolbar()
        
        self.transitioningDelegate = self
        self.view.backgroundColor = cropView.backgroundColor
    }
}

// MARK: - Button Feedback

fileprivate extension CropViewController {
    func cancelButtonTapped() {
        
    }
    
    func doneButtonTapped() {
    
    }
    
    func resetButtonTapped() {
    
    }
    
    func rotateButtonTapped() {
        
    }
}

// MARK: - Presentation Handling

extension CropViewController {
    
    public func presentAnimated(fromParentViewController viewController: UIViewController, fromView: UIView, fromFrame: CGRect, setup: (()->Void)?) {
        presentAnimated(fromParentViewController: viewController, fromView: fromView, fromFrame: fromFrame, setup: setup, completion: nil)
    }
    
    public func presentAnimated(fromParentViewController viewController: UIViewController, fromView: UIView, fromFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
        presentAnimated(fromParentViewController: viewController, fromImage: nil, fromView: fromView, fromFrame: fromFrame, angle: 0, toImageFrame: CGRect.zero, setup: setup, completion: completion)
    }
    
    public func presentAnimated(fromParentViewController viewController: UIViewController, fromImage image: UIImage?, fromView: UIView, fromFrame: CGRect, angle: Int, toImageFrame toFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
        
    }
    
    public func dismissAnimated(fromParentViewController viewController: UIViewController, toView: UIView, toFrame: CGRect, setup: (()->Void)?) {
        dismissAnimated(fromParentViewController: viewController, toView: toView, toFrame: toFrame, setup: setup, completion: nil)
    }
    
    public func dismissAnimated(fromParentViewController viewController: UIViewController, toView: UIView, toFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
        dismissAnimated(fromParentViewController: viewController, croppedImage: nil, toView: toView, toFrame: toFrame, setup: setup, completion: completion)
    }
    
    public func dismissAnimated(fromParentViewController viewController: UIViewController, croppedImage image: UIImage?, toView: UIView, toFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
        
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension CropViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
    }
}

// MARK: - CropViewDelegate

extension CropViewController: CropViewDelegate {

}

// MARK: - setup view layout

extension CropViewController {
    
    func setupCropView() {
        let boundsSize = self.view.bounds.size
        let frame = frameForCropView(verticalLayout: boundsSize.width < boundsSize.height)
        cropView = CropView(image: image)
        cropView.delegate = self
        cropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cropView.frame = frame
        self.view.addSubview(cropView)
    }
    
    func setupToolbar() {
        let boundsSize = self.view.bounds.size
        let frame = frameForCropView(verticalLayout: boundsSize.width < boundsSize.height)
        toolbar = CropToolbar(frame: frame)
        self.view.addSubview(toolbar)
        
        toolbar.doneBttonAction = { [unowned self] in
            self.doneButtonTapped()
        }
        toolbar.cancelBttonAction = { [unowned self] in
            self.cancelButtonTapped()
        }
        toolbar.resetBttonAction = { [unowned self] in
            self.resetButtonTapped()
        }
        toolbar.rotateBttonAction = { [unowned self] in
            self.rotateButtonTapped()
        }
    }
    
    func frameForCropView(verticalLayout yesOrNO: Bool) -> CGRect {
        // On an iPad, if being presented in a modal view controller by a UINavigationController,
        // at the time we need it, the size of our view will be incorrect.
        // If this is the case, derive our view size from our parent view controller instead
        var bounds = CGRect.zero
        if let parent = self.parent {
            bounds = parent.view.bounds
        }
        else {
            bounds = view.bounds
        }
        var frame = CGRect.zero
        if !yesOrNO {
            frame.origin.x = 44.0
            frame.origin.y = 0.0
            frame.size.width = bounds.width - 44.0
            frame.size.height = bounds.height
        }
        else {
            frame.origin.x = 0.0
            frame.origin.y = 0.0
            frame.size.width = bounds.width
            frame.size.height = bounds.height - 44.0
        }
        return frame
    }
    
    func frameForToolBar(verticalLayout yesOrNO: Bool) -> CGRect {
        var frame = CGRect.zero
        if !yesOrNO {
            frame.origin.x = 0.0
            frame.origin.y = 0.0
            frame.size.width = 44.0
            frame.size.height = self.view.frame.height
        }
        else {
            frame.origin.x = 0.0
            frame.origin.y = self.view.bounds.height - 44.0
            frame.size.width = self.view.bounds.width
            frame.size.height = 44.0
        }
        return frame
    }
}
