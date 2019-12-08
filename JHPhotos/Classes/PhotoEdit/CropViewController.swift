//
//  CropViewController.swift
//  JHPhotos
//
//  Created by winter on 2017/8/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

public protocol CropViewControllerDelegate: class {
    
    /// 编辑取消回调
    ///
    /// - Parameters:
    ///   - cropViewController: cropViewController
    ///   - didCancelled: 是否取消编辑
    /// - Returns: 是否调用 cropViewController 提供的'dismissAnimated(:)'
    func cropViewController(_ cropViewController: CropViewController, didCancelled: Bool) -> Bool
    
    /// 编辑完成回调
    ///
    /// - Parameters:
    ///   - cropViewController: cropViewController
    ///   - didCropToImage: 裁剪完成后的图片
    ///   - rect: 裁剪完成后的图片
    ///   - angle: 图片旋转角度 90/-90/180/-180/270/-270
    /// - Returns: 是否调用 cropViewController 提供的'dismissAnimated(:)'
    func cropViewController(_ cropViewController: CropViewController, didCropToImage: UIImage, rect: CGRect, angle: Int) -> Bool
    
//    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage: UIImage, rect: CGRect, angle: Int)
}

public extension CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCancelled: Bool) -> Bool { return false }
    func cropViewController(_ cropViewController: CropViewController, didCropToImage: UIImage, rect: CGRect, angle: Int) -> Bool { return false }
//    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage: UIImage, rect: CGRect, angle: Int) {}
}

public final class CropViewController: UIViewController {
    
    public weak var delegate: CropViewControllerDelegate?
    
    deinit {
        print("CropViewController deinit")
    }
    
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
    var aspectRatioPickerButtonHidden = false
    var prepareForTransitionHandler: (() -> Void)?
    let transitioning: CropTransitioning = CropTransitioning()
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
        self.modalTransitionStyle = .crossDissolve
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
        if let nav = self.navigationController {
            return nav.prefersStatusBarHidden
        }
        
        // If our presenting controller has already hidden the status bar,
        // hide the status bar by default
        if let vc = self.presentingViewController {
            if vc.prefersStatusBarHidden {
                return true;
            }
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
        var delegateHandled = false
        if let d = delegate {
            delegateHandled = d.cropViewController(self, didCancelled: true)
        }
        
        if !delegateHandled {
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            }
            else {
                self.modalTransitionStyle = .crossDissolve
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func rotateButtonTapped() {
        cropView.rotateImageNinetyDegrees(animated: true)
    }
    
    func resetButtonTapped() {
        let animated = cropView.angle == 0
        cropView.resetLayoutToDefault(animated: animated)
    }
    
    func doneButtonTapped() {
        let cropFrame = cropView.imageCropFrame()
        let angle = cropView.angle
        var delegateHandled = false
        
        var resultImage: UIImage!
        if angle == 0 && cropFrame.equalTo(CGRect(origin: CGPoint.zero, size: self.image.size)) {
            resultImage = image
        }
        else {
            resultImage = image.croppedImage(frame: cropFrame, angle: angle, circularClip: false)
        }
        
        if let d = delegate {
            delegateHandled = d.cropViewController(self, didCropToImage: resultImage, rect: cropFrame, angle: angle)
        }
        
        if !delegateHandled {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Presentation Handling

extension CropViewController {
    
    public func presentAnimated(fromParentViewController viewController: UIViewController, fromView: UIView?, fromFrame: CGRect, setup: (()->Void)?) {
        presentAnimated(fromParentViewController: viewController, fromView: fromView, fromFrame: fromFrame, setup: setup, completion: nil)
    }
    
    public func presentAnimated(fromParentViewController viewController: UIViewController, fromView: UIView?, fromFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
        presentAnimated(fromParentViewController: viewController, fromImage: nil, fromView: fromView, fromFrame: fromFrame, angle: 0, toImageFrame: CGRect.zero, setup: setup, completion: completion)
    }
    
    public func presentAnimated(fromParentViewController viewController: UIViewController, fromImage image: UIImage?, fromView: UIView?, fromFrame: CGRect, angle: Int, toImageFrame toFrame: CGRect, setup: (()->Void)?, completion: (()->Void)?) {
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
            fromView?.isHidden = false
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
        if (self.navigationController != nil) || (self.modalTransitionStyle == .coverVertical) {
            return nil
        }
        cropView.set(simpleRenderMode: true)
        
        transitioning.prepareForTransitionHandler = { [weak self] in
            if let strongSelf = self, let cropView = strongSelf.cropView {
                let transition = strongSelf.transitioning
                if !transition.isDissmissing {
                    transition.fromView?.isHidden = true
                }
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
        if (self.navigationController != nil) || (self.modalTransitionStyle == .coverVertical) {
            return nil
        }
        
        transitioning.prepareForTransitionHandler = { [weak self] in
            if let strongSelf = self, let cropView = strongSelf.cropView {
                let transition = strongSelf.transitioning
                if transition.isDissmissing {
                    cropView.isHidden = true
                }
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
        
        transitioning.isDissmissing = true
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
        if cropView == nil {
            return 0
        }
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
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = self.view.bounds
        let verticalLayout = bounds.width < bounds.height
        cropView.frame = frameForCropView(verticalLayout: verticalLayout)
        cropView.moveCroppedContentToCenter(animated: false)
        
        UIView.performWithoutAnimation {
            toolbar.statusBarVisible = !self.prefersStatusBarHidden
            toolbar.frame = frameForToolBar(verticalLayout: verticalLayout)
            toolbar.setNeedsLayout()
        }
    }
    
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
