//
//  CropView.swift
//  JHPhotos
//
//  Created by winter on 2017/8/24.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

fileprivate let CropViewPadding: CGFloat = 14.0
fileprivate let CropTimerDuration: TimeInterval = 0.8
fileprivate let CropViewMinimunBoxSize: CGFloat = 42.0

enum CropViewOverlayEdge {
    case none
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

public protocol CropViewDelegate: class {
    func cropViewDidBecomeResettable(cropView: CropView)
    func cropViewDidBecomeNonResettable(cropView: CropView)
}

public extension CropViewDelegate {
    func cropViewDidBecomeResettable(cropView: CropView) {}
    func cropViewDidBecomeNonResettable(cropView: CropView) {}
}

public class CropView: UIView {
    public weak var delegate: CropViewDelegate?
    
    var angle = 0
    var restoreAngle = 0
    var tappedEdge = CropViewOverlayEdge.none
    var aspectRatio = CGSize.zero
    var simpleRenderMode = false
    var cropBoxFrame: CGRect = CGRect.zero
    var cropOriginFrame = CGRect.zero
    var panOriginPoint = CGPoint.zero
    var originalCropBoxSize = CGSize.zero
    var originalContentOffset = CGPoint.zero
    
    var gridOverlayHidden = false
    
    var editing = false
    var cropBoxLastEditedSize = CGSize.zero
    var cropBoxLastEditedAngle = 0
    var cropBoxLastEditedZoomScale: CGFloat = 0.0
    var cropBoxLastEditedMinZoomScale: CGFloat = 0.0
    var rotateAnimationInProgress = false
    var disableForgroundMatching = false
    
    // Pre-screen-rotation state information
    var rotationContentOffset = CGPoint.zero
    var rotationContentSize = CGSize.zero
    var rotationBoundSize = CGSize.zero
    
    var croppingViewsHidden = false
    var canBeReset = false
    var resetTimer: Timer?
    
    /// 点击重置按钮时，纵横比是否也会被重置
    public var resetAspectRatioEnabled = true
    
    var restoreImageCropFrame = CGRect.zero
    
    var image: UIImage?
    var backgroundImageView: UIImageView!
    var backgroundContainerView: UIView!
    var foregroundImageView: UIImageView!
    let foregroundContainerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    let scrollView: CropScrollView = {
        let scrollView = CropScrollView()
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    let overlayView: UIView! = {
        let view = UIView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isHidden = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor(white: 0.12, alpha: 0.35)
        return view
    }()
    let gridOverlayView: CropOverlayView = {
        let view = CropOverlayView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        view.isUserInteractionEnabled = false
        return view
    }()
    var gridPanGestureRecognizer: UIPanGestureRecognizer!
    
    let translucencyEffect: UIBlurEffect = {
        let effect = UIBlurEffect(style: .dark)
        return effect
    }()
    let translucencyView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.isHidden = false
        view.isUserInteractionEnabled = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    init(image originImage: UIImage) {
        super.init(frame: CGRect.zero)
        self.image = originImage
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        if image == nil {
            fatalError("init(_ image:) has been implemented")
        }
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        scrollView.frame = self.bounds
        scrollView.delegate = self
        self.addSubview(scrollView)
        scrollView.touchesBegan = { [weak self] in self?.startEditing() }
        scrollView.touchedEnd = { [weak self] in self?.startResetTimer() }
        
        backgroundImageView = UIImageView(image: image)
        backgroundImageView.layer.minificationFilter = CALayerContentsFilter.linear
        
        backgroundContainerView = UIView(frame: backgroundImageView.frame)
        backgroundContainerView.addSubview(backgroundImageView)
        scrollView.addSubview(backgroundContainerView)
        
        overlayView.frame = self.bounds
        self.addSubview(overlayView)
        
        translucencyView.frame = self.bounds
        translucencyView.effect = translucencyEffect
        self.addSubview(translucencyView)
        
        self.addSubview(foregroundContainerView)
        foregroundImageView = UIImageView(image: image)
        foregroundImageView.layer.minificationFilter = CALayerContentsFilter.linear
        foregroundContainerView.addSubview(foregroundImageView)
        
        self.addSubview(gridOverlayView)
        
        gridPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gridPanGestureRecognized(_:)))
        gridPanGestureRecognizer.delegate = self
        scrollView.panGestureRecognizer.require(toFail: gridPanGestureRecognizer)
        self.addGestureRecognizer(gridPanGestureRecognizer)
    }
}

// MARK: - layout

extension CropView {
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if self.superview == nil {
            return
        }
        // Perform the initial layout of the image
        layoutInitialImage()
        
        if restoreAngle != 0 {
            set(angle: restoreAngle)
            restoreAngle = 0
        }
        
        if !restoreImageCropFrame.isEmpty {
            set(imageCropFrame: restoreImageCropFrame)
            restoreImageCropFrame = CGRect.zero
        }
        
        checkForCanReset()
    }
    
    func layoutInitialImage() {
        let imageSize = self.imageSize()
        scrollView.contentSize = imageSize
        
        let bounds = self.contentBounds()
        let boundsSize = bounds.size
        
        var scale: CGFloat = 0.0
        scale = min(boundsSize.width/imageSize.width, boundsSize.height/imageSize.height)
        let scaledImageSize = CGSize(width: floor(scale * imageSize.width), height: floor(scale * imageSize.height))
        
        var cropBoxSize = CGSize.zero
        let hasAspectRatio = self.hasAspectRatio()
        if hasAspectRatio {
            let rationScale = aspectRatio.width / aspectRatio.height
            let fullSizeRation = CGSize(width: boundsSize.width * rationScale, height: boundsSize.height * rationScale)
            let fitScale = min(boundsSize.width/fullSizeRation.width, boundsSize.height/fullSizeRation.height)
            cropBoxSize = CGSize(width: fullSizeRation.width * fitScale, height: fullSizeRation.height * fitScale)
            scale = max(cropBoxSize.width/imageSize.width, cropBoxSize.height/imageSize.height)
        }
        // Whether aspect ratio, or original, the final image size we'll base the rest of the calculations off
        let scaledSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))
        
        scrollView.minimumZoomScale = scale
        scrollView.maximumZoomScale = 15.0
        
        var frame = CGRect.zero
        frame.size = hasAspectRatio ? cropBoxSize : scaledSize
        frame.origin.x = bounds.minX + floor((bounds.width - frame.width) * 0.5)
        frame.origin.y = bounds.minY + floor((bounds.height - frame.height) * 0.5)
        self.set(cropBoxFrame: frame)
        
        // set the fully zoomed out state initially
        scrollView.zoomScale = scrollView.minimumZoomScale
        scrollView.contentSize = scaledSize
        
        // If we ended up with a smaller crop box than the content, offset it in the middle
        if (frame.width < scaledSize.width - CGFloat.ulpOfOne) || (frame.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor((scrollView.frame.width - scaledSize.width) * 0.5)
            offset.y = -floor((scrollView.frame.height - scaledSize.height) * 0.5)
            scrollView.contentOffset = offset
        }
        
        // save the current state for use with 90-degree rotations
        cropBoxLastEditedAngle = 0
        captureStateForImageRotation()
        
        // save the size for checking if we're in a resettable state
        originalCropBoxSize = resetAspectRatioEnabled ? scaledImageSize : cropBoxSize
        originalContentOffset = scrollView.contentOffset
        
        checkForCanReset()
        matchForegroundToBackground()
    }
    
    func updateCropBoxFrame(GesturePoint point: CGPoint) {
        var frame = cropBoxFrame
        let originFrame = cropOriginFrame
        let contentFrame = self.contentBounds()
        
        let newPoint = CGPoint(x: max(contentFrame.minX, point.x), y: max(contentFrame.minY, point.y))
        
        // The delta between where we first tapped, and where our finger is now
        let xDelta = (newPoint.x - panOriginPoint.x)
        let yDelta = (newPoint.y - panOriginPoint.y)
        
        // Current aspect ratio of the crop box in case we need to clamp it
        // let aspectRatio = originFrame.width / originFrame.height
        
        // Depending on which corner we drag from, set the appropriate min flag to
        // ensure we can properly clamp the XY value of the box if it overruns the minimum size
        // (Otherwise the image itself will slide with the drag gesture)
        var clampMinFromTop: Bool = false
        var clampMinFromLeft: Bool = false
        
        switch self.tappedEdge {
        case .left:
            frame.origin.x = originFrame.minX + xDelta
            frame.size.width = originFrame.width - xDelta
            clampMinFromLeft = true
            break;
        case .right:
            frame.size.width = originFrame.width + xDelta
            break;
        case .bottom:
            frame.size.height = originFrame.height + yDelta
            break;
        case .top:
            frame.origin.y = originFrame.minY + yDelta
            frame.size.height = originFrame.height - yDelta
            clampMinFromTop = true
            break;
        case .topLeft:
            frame.origin.x = originFrame.minX + xDelta
            frame.size.width = originFrame.width - xDelta
            frame.origin.y = originFrame.minY + yDelta
            frame.size.height = originFrame.height - yDelta
            
            clampMinFromLeft = true
            clampMinFromTop = true
            break;
        case .topRight:
            frame.origin.y = originFrame.minY + yDelta
            frame.size.height = originFrame.height - yDelta
            frame.size.width = originFrame.width + xDelta
            clampMinFromTop = true
            break;
        case .bottomLeft:
            frame.size.height = originFrame.height + yDelta
            frame.origin.x = originFrame.minX + xDelta
            frame.size.width = originFrame.width - xDelta
            clampMinFromLeft = true
            break;
        case .bottomRight:
            frame.size.height = originFrame.height + yDelta
            frame.size.width = originFrame.width + xDelta
            break;
        default: break;
        }
        
        // The absolute max/min size the box may be in the bounds of the crop view
        let minSize = CGSize(width: CropViewMinimunBoxSize, height: CropViewMinimunBoxSize)
        let maxSize = CGSize(width: contentFrame.width, height: contentFrame.height)
        
        // Clamp the minimum size
        frame.size.width = max(frame.width, minSize.width)
        frame.size.height = max(frame.height, minSize.height)
        
        // Clamp the maximum size
        frame.size.width = min(frame.width, maxSize.width)
        frame.size.height = min(frame.height, maxSize.height)
        
        // Clamp the X position of the box to the interior of the cropping bounds
        frame.origin.x = max(frame.minX, contentFrame.minX)
        frame.origin.x = min(frame.minX, contentFrame.maxX - minSize.width)
        
        // Clamp the Y postion of the box to the interior of the cropping bounds
        frame.origin.y = max(frame.minY, contentFrame.minY)
        frame.origin.y = min(frame.minY, contentFrame.maxY - minSize.height)
        
        // Once the box is completely shrunk, clamp its ability to move
        if clampMinFromLeft && frame.width <= minSize.width + CGFloat.ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if clampMinFromTop && frame.height <= minSize.height + CGFloat.ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }
        
        set(cropBoxFrame: frame)
        checkForCanReset()
    }
    
    func resetLayoutToDefault(animated: Bool) {
        // If resetting the crop view includes resetting the aspect ratio,
        // reset it to zero here. But set the ivar directly since there's no point
        // in performing the relayout calculations right before a reset.
        let hasAspectRatio = self.hasAspectRatio()
        if hasAspectRatio && resetAspectRatioEnabled {
            aspectRatio = CGSize.zero
        }
        
        if !animated || angle != 0 {
            // Reset all of the rotation transforms
            angle = 0
            
            // Set the scroll to 1.0f to reset the transform scale
            scrollView.zoomScale = 1.0
            
            // Reset everything
            var imageRect = CGRect.zero
            if let image = self.image {
                imageRect = CGRect(origin: CGPoint.zero, size: image.size)
            }
            
            backgroundImageView.frame = imageRect
            backgroundImageView.transform = CGAffineTransform.identity
            backgroundContainerView.frame = imageRect
            backgroundContainerView.transform = CGAffineTransform.identity
            foregroundImageView.frame = imageRect
            foregroundImageView.transform = CGAffineTransform.identity
            
            // Reset the layout
            layoutInitialImage()
            
            // Enable / Disable the reset button
            checkForCanReset()
            return;
        }
        
        // If we were in the middle of a reset timer, cancel it as we'll
        // manually perform a restoration animation here
        if self.resetTimer != nil {
            cancelResetTimer()
            set(editing: false, animated: false)
        }
        set(simpleRenderMode: true)
        
        delayFunc(seconds: 0.01) { 
            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 1.0,
                           options: .beginFromCurrentState,
                           animations: {
                            self.layoutInitialImage()
            }) { (_) in
                self.set(simpleRenderMode: false, animated: true)
            }
        }
    }
    
    func prepareforRotation() {
        self.rotationContentOffset = self.scrollView.contentOffset;
        self.rotationContentSize   = self.scrollView.contentSize;
        self.rotationBoundSize     = self.scrollView.bounds.size;
    }
    
    /// 屏幕旋转 适配
    func performRelayoutForRotation() {
        //TODO: Todo performRelayoutForRotation
    }
    
    func updateTo(imageCropFrame: CGRect) {
        // Convert the image crop frame's size from image space to the screen space
        let minSizeScale = scrollView.minimumZoomScale
        let scaledOffset = CGPoint(x: imageCropFrame.minX * minSizeScale, y: imageCropFrame.minY * minSizeScale)
        let scaledCropSize = CGSize(width: imageCropFrame.width * minSizeScale, height: imageCropFrame.height * minSizeScale)
        
        // Work out the scale necessary to upscale the crop size to fit the content bounds of the crop bound
        let bounds = contentBounds()
        let scale = min(bounds.width/scaledCropSize.width, bounds.height/scaledCropSize.height)
        
        // Zoom into the scroll view to the appropriate size
        scrollView.zoomScale = scrollView.minimumZoomScale * scale
        
        // Work out the size and offset of the upscaed crop box
        let frame = CGRect(x: 0, y: 0, width: scaledCropSize.width * scale, height: scaledCropSize.height * scale)
        
        // zoom the crop box
        var _cropBoxFrame = CGRect.zero
        _cropBoxFrame.origin.x = (self.bounds.width - frame.width) * 0.5
        _cropBoxFrame.origin.y = (self.bounds.height - frame.height) * 0.5
        set(cropBoxFrame: _cropBoxFrame)
        
        scrollView.contentOffset = CGPoint(x: scaledOffset.x * scale - scrollView.contentInset.left, y: scaledOffset.y * scale - scrollView.contentInset.top)
    }
    
    func matchForegroundToBackground() {
        if disableForgroundMatching {
            return
        }
        // We can't simply match the frames since if the images are rotated, the frame property becomes unusable
        if let sView = backgroundContainerView.superview {
            let frame = sView.convert(backgroundContainerView.frame, to: foregroundContainerView)
            print("foregroundImageView = \(frame)\nbackgroundViewFrame = \(backgroundContainerView.frame)\n")
            foregroundImageView.frame = frame
        }
    }
}

// MARK: - Accessors

extension CropView {
    func set(cropBoxFrame frame: CGRect) {
        if self.cropBoxFrame.equalTo(frame) {
            return
        }
        // Upon init, sometimes the box size is still 0, which can result in CALayer issues
        if frame.width < CGFloat.ulpOfOne || frame.height < CGFloat.ulpOfOne {
            return
        }
        var newCropBoxFrame = frame
        let contentFrame = self.contentBounds()
        let xOrigin: CGFloat = (contentFrame.minX)
        let xDelta: CGFloat = frame.minX - xOrigin
        newCropBoxFrame.origin.x = floor(max(frame.minX, xOrigin))
        if xDelta < -CGFloat.ulpOfOne {
            newCropBoxFrame.size.width += xDelta
        }
        
        let yOrigin: CGFloat = (contentFrame.minY)
        let yDelta: CGFloat = frame.minY - xOrigin
        newCropBoxFrame.origin.y = floor(max(frame.minY, yOrigin))
        if xDelta < -CGFloat.ulpOfOne {
            newCropBoxFrame.size.height += yDelta
        }
        
        var maxWidth = contentFrame.width + contentFrame.minX - newCropBoxFrame.minX
        maxWidth = floor(min(maxWidth, frame.width))
        
        var maxHeight = contentFrame.width + contentFrame.minX - newCropBoxFrame.minX
        maxHeight = floor(min(maxHeight, frame.height))
        
        newCropBoxFrame.size.width = max(newCropBoxFrame.width, CropViewMinimunBoxSize)
        newCropBoxFrame.size.height = max(newCropBoxFrame.height, CropViewMinimunBoxSize)
        cropBoxFrame = newCropBoxFrame
        
        foregroundContainerView.frame = cropBoxFrame
        gridOverlayView.frame = cropBoxFrame
        
        scrollView.contentInset = UIEdgeInsets(top: cropBoxFrame.minY, left: cropBoxFrame.minX, bottom: self.bounds.maxY - cropBoxFrame.maxY, right: self.bounds.maxX - cropBoxFrame.maxX)
        
        // if necessary, work out the new minimum size of the scroll view so it fills the crop box
        let imageSize = backgroundContainerView.bounds.size
        let scale = max(cropBoxFrame.size.height/imageSize.height, cropBoxFrame.size.width/imageSize.width)
        self.scrollView.minimumZoomScale = scale
        
        // make sure content isn't smaller than the crop box
        var size = self.scrollView.contentSize
        size.width = floor(size.width)
        size.height = floor(size.height)
        self.scrollView.contentSize = size
        
        // IMPORTANT: Force the scroll view to update its content after changing the zoom scale
        self.scrollView.zoomScale = self.scrollView.zoomScale
        
        // re-align the background content to match
        matchForegroundToBackground()
    }
    
    func set(editing: Bool) {
        set(editing: editing, animated: false)
    }
    
    func set(aspectRatio: CGSize) {
        set(aspectRatio: aspectRatio, animated: false)
    }
    
    func set(gridOverlayHidden yesOrNO: Bool) {
        set(gridOverlayHidden: yesOrNO, animated: false)
    }
    
    func set(gridOverlayHidden yesOrNO: Bool, animated: Bool) {
        gridOverlayHidden = yesOrNO
        
        if animated {
            gridOverlayView.alpha = yesOrNO ? 1.0 : 0.0
            UIView.animate(withDuration: 0.4, animations: {
                self.gridOverlayView.alpha = yesOrNO ? 0.0 : 1.0
            })
        }
        else {
            gridOverlayView.alpha = yesOrNO ? 0.0 : 1.0
        }
    }
    
    func setBackgroundImageView(hidden: Bool, animated: Bool) {
        if !animated {
            backgroundImageView.isHidden = hidden
            return
        }
        let beforeAlpha: CGFloat = hidden ? 1.0 : 0.0
        let toAlpha: CGFloat = hidden ? 0.0 : 1.0
        backgroundImageView.isHidden = false
        backgroundImageView.alpha = beforeAlpha
        UIView.animate(withDuration: 0.5, animations: { 
            self.backgroundImageView.alpha = toAlpha
        }) { (_) in
            if hidden {
                self.backgroundImageView.isHidden = true
            }
        }
    }
    
    func set(imageCropFrame frame: CGRect) {
        if self.superview == nil {
            restoreImageCropFrame = frame
            return
        }
        updateTo(imageCropFrame: frame)
    }
    
    func set(croppingViewsHidden yesOrNO: Bool) {
        set(gridOverlayHidden: yesOrNO, animated: false)
    }
    
    func set(croppingViewsHidden yesOrNO: Bool, animated: Bool) {
        if self.croppingViewsHidden == yesOrNO {
            return
        }
        self.croppingViewsHidden = yesOrNO;
        let alpha: CGFloat = yesOrNO ? 0.0 : 1.0
        if !animated {
            backgroundImageView.alpha = alpha;
            foregroundContainerView.alpha = alpha;
            gridOverlayView.alpha = alpha;

            toggleTranslucencyView(visible: !yesOrNO)
            return;
        }
        
        foregroundContainerView.alpha = alpha;
        backgroundImageView.alpha = alpha;
        UIView.animate(withDuration: 0.4) { 
            self.toggleTranslucencyView(visible: !yesOrNO)
            self.gridOverlayView.alpha = alpha;
        }
    }
    
    func set(canBeReset yesOrNO: Bool) {
        if yesOrNO == self.canBeReset {
            return
        }
        self.canBeReset = yesOrNO
        
        if yesOrNO {
            delegate?.cropViewDidBecomeResettable(cropView: self)
        }
        else {
            delegate?.cropViewDidBecomeNonResettable(cropView: self)
        }
    }
    
    func set(angle: Int) {
        // The initial layout would not have been performed yet.
        // Save the value and it will be applied when it has
        var newAngle = angle
        if (angle % 90) != 0 {
            newAngle = 0
        }
        
        if self.superview == nil {
            self.restoreAngle = newAngle
            return
        }
        
        while (labs(self.angle) != labs(newAngle)) {
            rotateImageNinetyDegrees(animated: false)
        }
    }
    
    func cropBoxAspectRatioIsPortrait() -> Bool {
        let frame = self.cropBoxFrame
        return frame.width < frame.height
    }
    
    func imageViewFrame() -> CGRect {
        var frame = CGRect.zero
        frame.origin.x = -scrollView.contentOffset.x
        frame.origin.y = -scrollView.contentOffset.y
        frame.size = scrollView.contentSize
        return frame
    }
    
    func imageCropFrame() -> CGRect {
        let imageSize = self.imageSize()
        let contentSize = scrollView.contentSize
        let _cropBoxFrame = self.cropBoxFrame
        let contentOffset = scrollView.contentOffset
        let edgeInsets = scrollView.contentInset
        
        var frame = CGRect.zero
        frame.origin.x = floor((contentOffset.x + edgeInsets.left) * (imageSize.width/contentSize.width))
        frame.origin.x = max(0, frame.minX)
        
        frame.origin.y = floor((contentOffset.y + edgeInsets.top) * (imageSize.height/contentSize.height))
        frame.origin.y = max(0, frame.minY)
        
        frame.size.width = (_cropBoxFrame.width * (imageSize.width/contentSize.width))
        frame.size.width = min(imageSize.width, frame.width)
        
        frame.size.height = floor(_cropBoxFrame.height * (imageSize.height/contentSize.height))
        frame.size.height = min(imageSize.height, frame.height)
        return frame
    }
    
    func rotateImageNinetyDegrees(animated: Bool) {
        rotateImageNinetyDegrees(animated: animated, clockwise: false)
    }
}

// MARK: - Editing

extension CropView {
    func startEditing() {
        set(editing: true, animated: true)
    }
    
    func set(editing: Bool, animated: Bool) {
        if editing == self.editing {
            return
        }
        self.editing = editing
        
        gridOverlayView.setGrid(hidden: !editing && gridOverlayHidden, animated: animated)
        if !editing {
            moveCroppedContentToCenter(animated: animated)
            captureStateForImageRotation()
            cropBoxLastEditedAngle = self.angle
        }
        
        if !animated {
            toggleTranslucencyView(visible: !editing)
            return
        }
        
        let duration = editing ? 0.05 : 0.35
        UIView.animate(withDuration: duration) {
            self.toggleTranslucencyView(visible: !editing)
        }
    }
    
    func set(simpleRenderMode yesOrNo: Bool) {
        set(simpleRenderMode: yesOrNo, animated: false)
    }
    
    func set(simpleRenderMode yesOrNo: Bool, animated: Bool) {
        if yesOrNo == self.simpleRenderMode {
            return
        }
        self.simpleRenderMode = yesOrNo
        self.set(editing: false)
        if !animated {
            toggleTranslucencyView(visible: !yesOrNo)
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.toggleTranslucencyView(visible: !yesOrNo)
        }
    }
    
    func set(aspectRatio: CGSize, animated: Bool) {
         self.aspectRatio = aspectRatio
        
        if self.superview == nil {
            return
        }
        
        // Passing in an empty size will revert back to the image aspect ratio
        let boundsFrame = contentBounds()
        var _cropBoxFrame = self.cropBoxFrame
        var offset = scrollView.contentOffset
        
        var cropBoxIsPortrait = false
        if Int(aspectRatio.width) == 1 && Int(aspectRatio.height) == 1 {
            if let image = self.image {
                let size = image.size
                cropBoxIsPortrait = size.width > size.height
            }
        }
        else {
            cropBoxIsPortrait = aspectRatio.width < aspectRatio.height
        }
        
        var zoomOut = false
        if cropBoxIsPortrait {
            let newWidth = floor(cropBoxFrame.height * (aspectRatio.width/aspectRatio.height))
            let delta = _cropBoxFrame.width - newWidth
            _cropBoxFrame.size.width = newWidth
            offset.x += (delta * 0.5)
            if delta < CGFloat.ulpOfOne {
                _cropBoxFrame.origin.x = boundsFrame.minX
            }
            let boundsWidth = boundsFrame.width
            if newWidth > boundsWidth {
                let scale = boundsWidth / newWidth
                _cropBoxFrame.size.width = boundsWidth
                _cropBoxFrame.size.height *= scale
                zoomOut = true
            }
        }
        else {
            let newHeight = floor(_cropBoxFrame.width * (aspectRatio.height/aspectRatio.width))
            let delta = _cropBoxFrame.height - newHeight
            _cropBoxFrame.size.height = newHeight
            offset.y += (delta * 0.5)
            if delta < CGFloat.ulpOfOne {
                _cropBoxFrame.origin.x = boundsFrame.minY
            }
            let boundHeight = boundsFrame.height
            if newHeight > boundHeight {
                let scale = boundHeight / newHeight
                _cropBoxFrame.size.width *= scale
                _cropBoxFrame.size.height = boundHeight
                zoomOut = true
            }
        }
        
        cropBoxLastEditedSize = _cropBoxFrame.size
        cropBoxLastEditedAngle = self.angle
        
        let translateBlock: () -> Void = {
            self.scrollView.contentOffset = offset
            self.set(cropBoxFrame: _cropBoxFrame)
            if zoomOut {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }
            self.moveCroppedContentToCenter(animated: false)
            self.checkForCanReset()
        }
        
        if !animated {
            translateBlock()
            return
        }
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.7,
                       options: .beginFromCurrentState,
                       animations: translateBlock,
                       completion: nil)
    }
    
    func moveCroppedContentToCenter(animated: Bool) {
        let contentRect = contentBounds()
        let frame = self.cropBoxFrame
        
        // Ensure we only proceed after the crop frame has been setup for the first time
        if frame.width < CGFloat.ulpOfOne || frame.height < CGFloat.ulpOfOne {
            return
        }
        
        // The scale we need to scale up the crop box to fit full screen
        let scale = min(contentRect.width/frame.width, contentRect.height/frame.height)
        let foucsPoint = CGPoint(x: frame.midX, y: frame.midY)
        let midPoint = CGPoint(x: contentRect.midX, y: contentRect.midY)
        
        let width: CGFloat = (frame.width * scale)
        let height: CGFloat = (frame.height * scale)
        var cropFrame = CGRect.zero
        cropFrame.size.width = width
        cropFrame.size.height = height
        cropFrame.origin.x = contentRect.minX + ((contentRect.width - width) * 0.5)
        cropFrame.origin.y = contentRect.minY + ((contentRect.height - height) * 0.5)
        
        // Work out the point on the scroll content that the focusPoint is aiming at
        let contentTargetPoint = CGPoint(x: (foucsPoint.x + scrollView.contentOffset.x) * scale, y: (foucsPoint.y + scrollView.contentOffset.y) * scale)
        
        // Work out where the crop box is focusing, so we can re-align to center that point
        var offsetX = -midPoint.x + contentTargetPoint.x
        var offsetY = -midPoint.y + contentTargetPoint.y
        
        // clamp the content so it doesn't create any seams around the grid
        offsetX = max(offsetX, -cropFrame.minX)
        offsetY = max(offsetY, -cropFrame.minY)
        
        let offset = CGPoint(x: offsetX, y: offsetY)
        
        let translateBlock: () -> Void = {[weak self] in
            if let strongSelf = self {
                // Setting these scroll view properties will trigger
                // the foreground matching method via their delegates,
                // multiple times inside the same animation block, resulting
                // in glitchy animations.
                //
                // Disable matching for now, and explicitly update at the end.
                strongSelf.disableForgroundMatching = true
                do {
                    // Slight hack. This method needs to be called during `[UIViewController viewDidLayoutSubviews]`
                    // in order for the crop view to resize itself during iPad split screen events.
                    // On the first run, even though scale is exactly 1.0f, performing this multiplication introduces
                    // a floating point noise that zooms the image in by about 5 pixels. This fixes that issue.
                    if scale < 1.0 - CGFloat.ulpOfOne || scale > 1.0 + CGFloat.ulpOfOne {
                        strongSelf.scrollView.zoomScale *= scale
                        strongSelf.scrollView.zoomScale = min(strongSelf.scrollView.zoomScale, strongSelf.scrollView.maximumZoomScale)
                    }
                    
                    // If it turns out the zoom operation would have exceeded the minizum zoom scale, don't apply
                    // the content offset
                    if strongSelf.scrollView.zoomScale < strongSelf.scrollView.maximumZoomScale - CGFloat.ulpOfOne {
                        let newOffsetX = min(offset.x, strongSelf.scrollView.contentSize.width - cropFrame.maxX)
                        let newOffsetY = min(offset.y, strongSelf.scrollView.contentSize.height - cropFrame.maxY)
                        strongSelf.scrollView.contentOffset = CGPoint(x: newOffsetX, y: newOffsetY)
                    }
                    strongSelf.set(cropBoxFrame: cropFrame)
                }
                strongSelf.disableForgroundMatching = false
                // Explicitly update the matching at the end of the calculations
                strongSelf.matchForegroundToBackground()
            }
        }
        
        if !animated {
            translateBlock()
            return
        }
        matchForegroundToBackground()
        
        delayFunc(seconds: 0.01) {
            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0.7,
                           options: .beginFromCurrentState,
                           animations: translateBlock,
                           completion: nil)
        }
    }
    
    func rotateImageNinetyDegrees(animated: Bool, clockwise: Bool) {
        // Only allow one rotation animation at a time
        if rotateAnimationInProgress {
            return;
        }
        
        // Cancel any pending resizing timers
        if self.resetTimer != nil {
            cancelResetTimer()
            set(editing: false, animated: false)
            cropBoxLastEditedAngle = self.angle
            captureStateForImageRotation()
        }
        
        // Work out the new angle, and wrap around once we exceed 360
        var newAngle = angle
        newAngle = clockwise ? newAngle + 90 : newAngle - 90
        if newAngle <= -360 || newAngle >= 360 {
            newAngle = 0
        }
        angle = newAngle
        
        // Convert the new angle to radians
        var angleInRadians: CGFloat = 0.0
        switch angle {
        case 90:    angleInRadians = CGFloat.pi * 0.5;    break
        case -90:   angleInRadians = -CGFloat.pi * 0.5;   break
        case 180:   angleInRadians = CGFloat.pi;          break
        case -180:  angleInRadians = -CGFloat.pi;         break
        case 270:   angleInRadians = CGFloat.pi * 1.5;    break
        case -270:  angleInRadians = -CGFloat.pi * 1.5;   break
        default: break
        }
        
        // Set up the transformation matrix for the rotation
        let rotation = CGAffineTransform(rotationAngle: angleInRadians)
        
        // Work out how much we'll need to scale everything to fit to the new rotation
        let contentBounds = self.contentBounds()
        let _cropBoxFrame = self.cropBoxFrame
        let scale = min(contentBounds.width/_cropBoxFrame.height, contentBounds.height/_cropBoxFrame.width)
        
        // Work out which section of the image we're currently focusing at
        let cropMidPoint = CGPoint(x: _cropBoxFrame.midX, y: _cropBoxFrame.midY)
        var cropTargetPoint = CGPoint(x: cropMidPoint.x + scrollView.contentOffset.x, y: cropMidPoint.y + scrollView.contentOffset.y)
        
        // Work out the dimensions of the crop box when rotated
        var newCropFrame = CGRect.zero
        if (labs(angle) == labs(cropBoxLastEditedAngle)) || ((-labs(angle)) == (labs(cropBoxLastEditedAngle)-180)%360) {
            newCropFrame.size = cropBoxLastEditedSize
            scrollView.zoomScale = cropBoxLastEditedZoomScale
            scrollView.minimumZoomScale = cropBoxLastEditedMinZoomScale
        }
        else {
            newCropFrame.size = CGSize(width: floor(cropBoxFrame.height * scale), height: floor(cropBoxFrame.width * scale))
            // Re-adjust the scrolling dimensions of the scroll view to match the new size
            scrollView.minimumZoomScale *= scale
            scrollView.zoomScale *= scale
        }
        
        newCropFrame.origin.x = floor((self.bounds.width - newCropFrame.width) * 0.5)
        newCropFrame.origin.y = floor((self.bounds.height - newCropFrame.height) * 0.5)
        
        // If we're animated, generate a snapshot view that we'll animate in place of the real view
        var snapshotView: UIView?
        if animated {
            snapshotView = foregroundContainerView.snapshotView(afterScreenUpdates: false)
            rotateAnimationInProgress = true
        }
        
        // Rotate the background image view, inside its container view
        backgroundImageView.transform = rotation
        
        // Flip the width/height of the container view so it matches the rotated image view's size
        let containerSize = backgroundContainerView.frame.size
        backgroundContainerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: containerSize.height, height: containerSize.width))
        backgroundImageView.frame = CGRect(origin: CGPoint.zero, size: backgroundImageView.frame.size)
        
        // Rotate the foreground image view to match
        foregroundContainerView.transform = CGAffineTransform.identity
        foregroundImageView.transform = rotation
        
        // Flip the content size of the scroll view to match the rotated bounds
        scrollView.contentSize = backgroundContainerView.frame.size
        
        // assign the new crop box frame and re-adjust the content to fill it
        set(cropBoxFrame: newCropFrame)
        moveCroppedContentToCenter(animated: false)
        newCropFrame = self.cropBoxFrame
        
        // work out how to line up out point of interest into the middle of the crop box
        cropTargetPoint.x *= scale
        cropTargetPoint.y *= scale
        
        // swap the target dimensions to match a 90 degree rotation (clockwise or counterclockwise)
        let swap = cropTargetPoint.x
        if clockwise {
            cropTargetPoint.x = scrollView.contentSize.width - cropTargetPoint.y
            cropTargetPoint.y = swap
        }
        else {
            cropTargetPoint.x = cropTargetPoint.y
            cropTargetPoint.y = scrollView.contentSize.height - swap
        }
        
        // reapply the translated scroll offset to the scroll view
        let midPoint = CGPoint(x: newCropFrame.midX, y: newCropFrame.midY)
        var offset = CGPoint.zero
        offset.x = floor(-midPoint.x + cropTargetPoint.x)
        offset.y = floor(-midPoint.y + cropTargetPoint.y)
        offset.x = max(-scrollView.contentInset.left, offset.x)
        offset.y = max(-scrollView.contentInset.top, offset.y)
        
        // if the scroll view's new scale is 1 and the new offset is equal to the old, will not trigger the delegate 'scrollViewDidScroll:'
        // so we should call the method manually to update the foregroundImageView's frame
        if offset.x == scrollView.contentOffset.x && offset.y == scrollView.contentOffset.y && scale == 1 {
            matchForegroundToBackground()
        }
        scrollView.contentOffset = offset
        
        // If we're animated, play an animation of the snapshot view rotating,
        // then fade it out over the live content
        if animated {
            if let snapshotView = snapshotView {
                snapshotView.center = scrollView.center
                self.addSubview(snapshotView)
                
                backgroundContainerView.isHidden = true
                foregroundContainerView.isHidden = true
                translucencyView.isHidden = true
                gridOverlayView.isHidden = true
                
                UIView.animate(withDuration: 0.45,
                               delay: 0.0,
                               usingSpringWithDamping: 1.0,
                               initialSpringVelocity: 0.8,
                               options: .beginFromCurrentState,
                               animations: { 
                                let transform = CGAffineTransform(rotationAngle:  CGFloat.pi * 0.5 * CGFloat(clockwise ? 1 : -1))
                                snapshotView.transform = transform.scaledBy(x: scale, y: scale)
                }, completion: { (_) in
                    self.backgroundContainerView.isHidden = false
                    self.foregroundContainerView.isHidden = false
                    self.translucencyView.isHidden = false
                    self.gridOverlayView.isHidden = false
                    
                    self.backgroundContainerView.alpha = 0.0
                    self.gridOverlayView.alpha = 0.0
                    self.translucencyView.alpha = 1.0
                    
                    UIView.animate(withDuration: 0.45, animations: { 
                        snapshotView.alpha = 0.0
                        self.backgroundContainerView.alpha = 1.0
                        self.gridOverlayView.alpha = 1.0
                    }, completion: { (_) in
                        self.rotateAnimationInProgress = false
                        snapshotView.removeFromSuperview()
                    })
                })
            }
        }
        checkForCanReset()
    }
    
    func captureStateForImageRotation() {
        cropBoxLastEditedSize = cropBoxFrame.size
        cropBoxLastEditedZoomScale = scrollView.zoomScale
        cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale
    }
}

// MARK: - Convienience Methods

extension CropView {
    func contentBounds() -> CGRect {
        var contentRect = CGRect.zero
        contentRect.origin.x = CropViewPadding
        contentRect.origin.y = CropViewPadding
        contentRect.size.width = self.bounds.width - 2.0 * CropViewPadding
        contentRect.size.height = self.bounds.height - 2.0 * CropViewPadding
        return contentRect
    }
    
    func imageSize() -> CGSize {
        if let image = image {
            if  angle == -90 || angle == -270 || angle == 90 || angle == 270 {
                return CGSize(width: image.size.height, height: image.size.width)
            }
            return  CGSize(width: image.size.width, height: image.size.height)
        }
        else {
            return CGSize.zero
        }
    }
    
    func hasAspectRatio() -> Bool {
        return aspectRatio.width > CGFloat.ulpOfOne && aspectRatio.height > CGFloat.ulpOfOne
    }
    
    func startResetTimer() {
        if self.resetTimer != nil {
            return
        }
        self.resetTimer = Timer.scheduledTimer(timeInterval: CropTimerDuration, target: self, selector: #selector(timerTriggered), userInfo: nil, repeats: false)
    }
    
    @objc func timerTriggered() {
        set(editing: false, animated: true)
        cancelResetTimer()
    }
    
    func cancelResetTimer() {
        if let timer = self.resetTimer {
            timer.invalidate()
            self.resetTimer = nil
        }
    }
    
    func cropEdge(forPoint point: CGPoint) -> CropViewOverlayEdge {
        var frame = cropBoxFrame
        
        // account for padding around the box
        frame = frame.insetBy(dx: -32, dy: -32)
        
        // Make sure the corners take priority
        let topLeftRect = CGRect(origin: frame.origin, size: CGSize(width: 64, height: 64))
        if topLeftRect.contains(point) {
            return .topLeft
        }
        
        var topRightRect = topLeftRect
        topRightRect.origin.x = frame.maxX - 64.0
        if topRightRect.contains(point) {
            return .topRight
        }
        
        var bottomLeftRect = topLeftRect
        bottomLeftRect.origin.y = frame.maxY - 64.0
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        var bottomRightRect = topRightRect
        bottomRightRect.origin.y = bottomLeftRect.minY
        if bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        // Check for edges
        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 64))
        if topRect.contains(point) {
            return .top
        }
        
        var bottomRect = topRect
        bottomRect.origin.y = frame.maxY - 64.0
        if bottomRect.contains(point) {
            return .bottom
        }
        
        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: 64, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }
        
        var rightRect = leftRect
        rightRect.origin.x = frame.maxX - 64
        if rightRect.contains(point) {
            return .right
        }
        
        return .none
    }
    
    func toggleTranslucencyView(visible: Bool) {
        translucencyView.effect = visible ? translucencyEffect : nil
    }
}

// MARK: - other

extension CropView {
    func checkForCanReset() {
        var canReset = false
        if angle != 0 { // image has been rotated
            canReset = true
        }
        else if (scrollView.zoomScale > scrollView.minimumZoomScale + CGFloat.ulpOfOne) {
            // image has been zoomed
            canReset = true
        }
        else if (!cropBoxFrame.size.equalTo(originalCropBoxSize)) {
            // crop has been changed
            canReset = true
        }
        else if (!scrollView.contentOffset.equalTo(originalContentOffset)) {
            canReset = true
        }
        set(canBeReset: canReset)
    }
    
    fileprivate func delayFunc(seconds: TimeInterval, action: @escaping () -> Void) {
        let delayTime = DispatchTime.now() + seconds
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: action)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension CropView: UIGestureRecognizerDelegate {
    
    @objc func gridPanGestureRecognized(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        if recognizer.state == .began {
            startEditing()
            panOriginPoint = point
            cropOriginFrame = cropBoxFrame
            tappedEdge = cropEdge(forPoint: point)
        }
        else if recognizer.state == .ended {
            startResetTimer()
        }
        updateCropBoxFrame(GesturePoint: point)
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !gestureRecognizer.isEqual(gridPanGestureRecognizer) {
            return true
        }
        let tapPoint = gestureRecognizer.location(in: self)
        let frame = gridOverlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        if innerFrame.contains(tapPoint) || !outerFrame.contains(tapPoint) {
            return false
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gridPanGestureRecognizer.state == .changed {
            return false
        }
        return true
    }
}

// MARK: - UIScrollViewDelegate

extension CropView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? { return backgroundContainerView }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) { matchForegroundToBackground() }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startEditing()
        set(canBeReset: true)
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        startEditing()
        set(canBeReset: true)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        startResetTimer()
        checkForCanReset()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        startResetTimer()
        checkForCanReset()
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.isTracking {
            cropBoxLastEditedZoomScale = scrollView.zoomScale
            cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale
        }
        matchForegroundToBackground()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            startResetTimer()
        }
    }
}

class CropScrollView: UIScrollView {
    var touchesBegan: (() -> Void)?
    var touchesCancelled: (() -> Void)?
    var touchedEnd: (() -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBegan?()
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesCancelled?()
        super.touchesCancelled(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchedEnd?()
        super.touchesEnded(touches, with: event)
    }
}
