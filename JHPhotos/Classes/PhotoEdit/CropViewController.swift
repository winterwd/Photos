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
    var toolbarSnapshotView: UIView?
    var aspectRatioPickerButtonHidden = false
    var prepareForTransitionHandler: (() -> Void)?
    let transitioning: CropTransitioning = {
        return CropTransitioning()
    }()
    var customAspectRatio = CGSize.zero
    
    var inTransition = false
    var initialLayout = false
    var navigationBarHidden = false
    var toolbarHidden = false

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCropView()
        setupToolbar()
        
        self.transitioningDelegate = self
        self.view.backgroundColor = cropView.backgroundColor
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if animated {
            inTransition = true
            self.setNeedsStatusBarAppearanceUpdate()
        }
        if let nav = self.navigationController {
            navigationBarHidden = nav.isNavigationBarHidden
            toolbarHidden = nav.isToolbarHidden
            nav.setNavigationBarHidden(true, animated: animated)
            nav.setToolbarHidden(true, animated: animated)
            self.modalTransitionStyle = .coverVertical
        }
        else {
            cropView.setBackgroundImageView(hidden: true, animated: false)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inTransition = false
        cropView.set(simpleRenderMode: false)
        if animated && UIApplication.shared.isStatusBarHidden == false {
            UIView.animate(withDuration: 0.3, animations: { 
                self.setNeedsStatusBarAppearanceUpdate()
            })
            
            if cropView.gridOverlayHidden {
                cropView.set(gridOverlayHidden: false, animated: true)
            }
            
            if self.navigationController == nil {
                cropView.setBackgroundImageView(hidden: false, animated: true)
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inTransition = true
        UIView.animate(withDuration: 0.5, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
        
        if let nav = self.navigationController {
            nav.setToolbarHidden(toolbarHidden, animated: animated)
            nav.setNavigationBarHidden(navigationBarHidden, animated: animated)
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        inTransition = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            if self.navigationController == nil {
                return .default
            }
            else {
                return .lightContent
            }
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        // If we belong to a UINavigationController, defer to its own status bar style
        if self.navigationController != nil {
            return self.navigationController.prefersStatusBarHidden
        }
        
        // If our presenting controller has already hidden the status bar,
        // hide the status bar by default
        if self.presentingViewController.prefersStatusBarHidden {
            return true;
        }
        
        var hidden = true
        // Not currently in a presentation animation (Where removing the status bar would break the layout)
        hidden = hidden && !(self.inTransition)
        // Not currently waiting to the added to a super view
        hidden = hidden && !(self.view.superview == nil);
        return hidden;

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
        if image != nil {
            transitioning.image = image
        }
        else {
            transitioning.image = self.image
        }
        transitioning.fromFrame = fromFrame
        transitioning.fromView = fromView
        prepareForTransitionHandler = setup
        
        if self.angle() != 0 || !toFrame.isEmpty {
            set(angle: angle)
            set(imageCropFrame: toFrame)
        }
        
        viewController.present(self, animated: true) { [unowned self] in
            completion?()
            self.cropView.set(croppingViewsHidden: false, animated: true)
            if !fromFrame.isEmpty {
                self.cropView.set(gridOverlayHidden: false, animated: true)
            }
        }
    }
    
    public func dismissAnimated(fromParentViewController viewController: UIViewController, toView: UIView, toFrame: CGRect, setup: (()->Void)?) {
        dismissAnimated(fromParentViewController: viewController, toView: toView, toFrame: toFrame, setup: setup, completion: nil)
    }
    
    public func dismissAnimated(fromParentViewController viewController: UIViewController, toView: UIView, toFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
        dismissAnimated(fromParentViewController: viewController, croppedImage: nil, toView: toView, toFrame: toFrame, setup: setup, completion: completion)
    }
    
    public func dismissAnimated(fromParentViewController viewController: UIViewController, croppedImage image: UIImage?, toView: UIView, toFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
        // If a cropped image was supplied, use that, and only zoom out from the crop box
        if let image = image {
            transitioning.image = image
            transitioning.fromFrame = cropView.convert(cropView.cropBoxFrame, to: self.view)
        }
        else { // else use the main image, and zoom out from its entirety
            transitioning.image = self.image
            transitioning.fromFrame = cropView.convert(cropView.imageViewFrame(), to: self.view)
        }
        
        transitioning.toView = toView
        transitioning.toFrame = toFrame
        prepareForTransitionHandler = setup
        viewController.dismiss(animated: true, completion: completion)
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension CropViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if (self.navigationController != nil) || self.modalTransitionStyle == .coverVertical {
            return nil
        }
        cropView.set(simpleRenderMode: true)
        
        transitioning.prepareForTransitionHandler = { [weak self] in
            if let strongSelf = self, let cropView = strongSelf.cropView {
                let transition = strongSelf.transitioning
                transition.toFrame = cropView.convert(cropView.cropBoxFrame, to: strongSelf.view)
                if transition.fromView != nil || !transition.fromFrame.isEmpty {
                    cropView.set(croppingViewsHidden: true)
                }
                strongSelf.prepareForTransitionHandler?()
                strongSelf.prepareForTransitionHandler = nil
            }
        }
        
        transitioning.isDissmissing = false
        return transitioning
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if (self.navigationController != nil) || self.modalTransitionStyle == .coverVertical {
            return nil
        }
        
        transitioning.prepareForTransitionHandler = { [weak self] in
            if let strongSelf = self, let cropView = strongSelf.cropView {
                let transition = strongSelf.transitioning
                transition.toFrame = cropView.convert(cropView.cropBoxFrame, to: strongSelf.view)
                if transition.toView != nil || !transition.toFrame.isEmpty {
                    cropView.set(croppingViewsHidden: true)
                }
                else {
                    cropView.set(simpleRenderMode: true)
                }
                strongSelf.prepareForTransitionHandler?()
                strongSelf.prepareForTransitionHandler = nil
            }
        }
        
        transitioning.isDissmissing = false
        return transitioning
    }
}

// MARK: - CropViewDelegate

extension CropViewController: CropViewDelegate {
    public func cropViewDidBecomeResettable(cropView: CropView) {
        toolbar.set(resetButtonEnabled: true)
    }
    
    public func cropViewDidBecomeNonResettable(cropView: CropView) {
        toolbar.set(resetButtonEnabled: false)
    }
}

// MARK: - Property

extension CropViewController {
    func set(angle: Int) {
        cropView.set(angle: angle)
    }
    
    func angle() -> Int {
        return cropView.angle
    }
    
    func set(imageCropFrame frame: CGRect) {
        cropView.set(imageCropFrame: frame)
    }
    
    func imageCropFrame() -> CGRect {
        return cropView.imageCropFrame()
    }
    
    func resetAspectRatioEnabled() -> Bool {
        return cropView.resetAspectRatioEnabled
    }
    
    func set(resetAspectRatioEnabled yesOrNO: Bool) {
        cropView.resetAspectRatioEnabled = yesOrNO
        aspectRatioPickerButtonHidden = !yesOrNO
    }
    
    func set(customAspectRatio ration: CGSize) {
        customAspectRatio = ration
        cropView.set(aspectRatio: ration)
    }
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

// MARK: - UIViewControllerContextTransitioning

class CropTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    var isDissmissing = false
    var image: UIImage?
    
    var fromView: UIView?
    var toView: UIView?
    
    var fromFrame = CGRect.zero
    var toFrame = CGRect.zero
    
    var prepareForTransitionHandler: (() -> Void)?
    
    func reset() {
        self.image = nil
        self.toView = nil
        self.fromView = nil
        self.fromFrame = CGRect.zero
        self.toFrame = CGRect.zero
        self.prepareForTransitionHandler = nil
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.45
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Get the master view where the animation takes place
        let containerView = transitionContext.containerView
        
        // Get the origin/destination view controllers
        if let fromViewController = transitionContext.viewController(forKey: .from), let toViewController = transitionContext.viewController(forKey: .to) {
            
            // Work out which one is the crop view controller
            let cropViewController = self.isDissmissing ? fromViewController : toViewController
            let previousController = self.isDissmissing ? toViewController : fromViewController
            
            // Just in case, match up the frame sizes
            cropViewController.view.frame = containerView.bounds
            if self.isDissmissing {
                containerView.insertSubview(previousController.view, belowSubview: cropViewController.view)
            }
            else {
                containerView.addSubview(cropViewController.view)
            }
            
            // Perform any last UI updates now so we can potentially factor them into our calculations, but after
            // the container views have been set up
            self.prepareForTransitionHandler?()
            
            // If origin/destination views were supplied, use them to supplant the
            // frames
            if !self.isDissmissing && self.fromView != nil {
                if let fromView = self.fromView, let superview = self.fromView?.superview {
                    self.fromFrame = superview.convert(fromView.frame, to: containerView)
                }
            }
            else if self.isDissmissing && self.toView != nil {
                if let toView = self.toView, let superview = self.toView?.superview {
                    self.toFrame = superview.convert(toView.frame, to: containerView)
                }
            }
            
            var imageView: UIImageView?
            if (self.isDissmissing && !self.toFrame.isEmpty) || (!self.isDissmissing && !self.fromFrame.isEmpty) {
                let view = UIImageView(image: self.image)
                view.frame = self.fromFrame
                containerView.addSubview(view)
                imageView = view
            }
            
            cropViewController.view.alpha = self.isDissmissing ? 1.0 : 0.0
            if let view = imageView {
                UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.7, options: .layoutSubviews, animations: { 
                    view.frame = self.toFrame
                }, completion: { (_) in
                    UIView.animate(withDuration: 0.1, animations: { 
                        view.alpha = 0.0
                    }, completion: { (_) in
                        view.removeFromSuperview()
                    })
                })
            }
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { 
                cropViewController.view.alpha = self.isDissmissing ? 0.0 : 1.0
            }, completion: { (_) in
                self.reset()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
