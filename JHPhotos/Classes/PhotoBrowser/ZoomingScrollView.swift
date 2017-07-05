//
//  ZoomingScrollView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/23.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

class ZoomingScrollView: UIScrollView {
    
    // MARK: - property
    
    weak var selectedButton: UIButton?
    var photo: Photo? {
        willSet {
            self.willSetPhoto(photo)
        }
        didSet {
            self.didSetPhoto(photo)
        }
    }
    
    fileprivate weak var photoBrowser: PhotoBrowser!
    var index = LONG_MAX
    
    fileprivate var tapView: TapDetectingView! = {
        let view = TapDetectingView(frame: CGRect.zero)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.black
        return view
    }()
    
    fileprivate var photoImageView: TapDetectingImageView! = {
        let view = TapDetectingImageView(frame: CGRect.zero)
        view.contentMode = .center
        view.backgroundColor = UIColor.black
        return view
    }()
    
    fileprivate var loadingIndicator: CircularProgressView! = {
        let view = CircularProgressView(frame: CGRect(x: 140, y: 30, width: 40, height: 40))
        view.isUserInteractionEnabled = false
        view.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        return view
    }()
    
    fileprivate var loadingError: UIImageView?
    
    // MARK: - self life
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
    }

    convenience init(_ browser: PhotoBrowser) {
        self.init(frame: CGRect.zero)
        
        // setup
        index = LONG_MAX
        photoBrowser = browser
//        photoBrowser.
        tapView.tapDelegate = self
        self.addSubview(tapView)
        
        photoImageView.tapDelegate = self
        self.addSubview(photoImageView)
        
        self.addSubview(loadingIndicator)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressFromNotification(notification:)),
                                               name: PHOTO_PROGRESS_NOTIFICATION,
                                               object: nil)
        
        self.backgroundColor = UIColor.black
        self.delegate = self
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        hideImageFailure()
        photo = nil
        selectedButton = nil
        photoImageView.isHidden = false
        photoImageView.image = nil
        index = LONG_MAX
    }
    
    // MARK: - Image
   
    fileprivate func willSetPhoto(_ some: Photo?) {
        // cancel any loading on old photo
        if (some == nil) && (photo != nil) {
            photo?.cancelAnyLoading()
        }
    }
    
    fileprivate func didSetPhoto(_ some: Photo?) {
        if photoBrowser.imageForPhoto(some) != nil {
            self.displayImage()
        }
        else {
            // will be loading
            self.showLoadingIndicator()
        }
    }
    
    // Get and display image
    func displayImage() {
        if photoImageView.image == nil && photo != nil {
            // Reset
            self.maximumZoomScale = 1;
            self.minimumZoomScale = 1;
            self.zoomScale = 1;
            self.contentSize = CGSize(width: 0, height: 0);
            
            if let image = photoBrowser.imageForPhoto(photo) {
                // hide indocator
                self.hideLoadingIndicator()
                
                // set image
                photoImageView.image = image
                photoImageView.isHidden = false
                
                // setup photo frame
                let photoImageViewFrame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                photoImageView.frame = photoImageViewFrame
                self.contentSize = photoImageViewFrame.size
                
                // set zoom to mininum zoom
                self.setMaxMinZoomScalesForCurrentBounds()
            }
            else {
                // show image failure
                self.displayImageFailure()
            }
            self.setNeedsLayout()
        }
    }
    
    // Image failed so just show black!
    func displayImageFailure() {
        self.hideLoadingIndicator()
        photoImageView.image = nil
        
        // show if image is not empty
        if !(photo?.emptyImage)! {
            if loadingError == nil {
                let path = Bundle.init(for: PhotoBrowser.self).path(forResource: "JHPhotos.bundle/ImageError", ofType: "png")!
                let image = UIImage(contentsOfFile: path)
                loadingError = UIImageView(image: image)
                loadingError?.isUserInteractionEnabled = false
                loadingError?.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
                loadingError?.sizeToFit()
                self.addSubview(loadingError!)
            }
            let size = self.bounds.size
            loadingError?.frame = CGRect(x: (size.width - (loadingError?.frame.size.width)!) / 2,
                                         y: (size.height - (loadingError?.frame.size.height)!) / 2,
                                         width: (loadingError?.frame.size.width)!,
                                         height: (loadingError?.frame.size.height)!)
        }
    }
    
    func hideImageFailure() {
        if loadingError != nil {
            loadingError?.removeFromSuperview();
            loadingError = nil
        }
    }
    
    // MARK: - Loading Progress
    
    @objc fileprivate func progressFromNotification(notification: Notification) {
        // dict = ["progress": "0.8", "photo": photo]
        DispatchQueue.main.async { 
            if let dict = notification.userInfo as? [String: Any] {
                if let p = dict["photo"] as? Photo, p.isEqual(self.photo) {
                    let progress = dict["progress"] as! Float
                    self.loadingIndicator.setProgress(max(min(1.0, CGFloat(progress)), 0.0))
                }
            }
        }
    }
    
    func hideLoadingIndicator() {
        loadingIndicator.isHidden = true
    }
    
    func showLoadingIndicator() {
        self.zoomScale = 0
        self.minimumZoomScale = 0
        self.maximumZoomScale = 0
        loadingIndicator.setProgress(0)
        loadingIndicator.isHidden = false
        self.hideImageFailure()
    }

    // MARK: - Setup
    
    fileprivate func initialZoomScaleWithMinScale() -> CGFloat {
        var zoomScale = self.minimumZoomScale
        if photoImageView != nil && photoBrowser.isZoomPhotosToFill {
            let boundsSize = self.bounds.size
            let imageSize = photoImageView.image?.size
            let boundsAR = boundsSize.width / boundsSize.height
            let imageAR = (imageSize?.width)! / (imageSize?.height)!
            let xScale = boundsSize.width / (imageSize?.width)!
            let yScale = boundsSize.height / (imageSize?.height)!
            if (abs(boundsAR - imageAR)) < 0.17 {
                zoomScale = max(xScale, yScale)
                zoomScale = min(max(self.minimumZoomScale, zoomScale), self.maximumZoomScale)
            }
        }
        return zoomScale
    }
    
    func setMaxMinZoomScalesForCurrentBounds() {
        // reset
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
        
        if photoImageView.image == nil {
            return
        }
        
        // reset position
        photoImageView.frame = CGRect(x: 0, y: 0, width: photoImageView.frame.size.width, height: photoImageView.frame.size.height)
        
        // sizes
        let boundsSize = self.bounds.size
        let imageSize = photoImageView.image?.size
     
        // calculate min
        let xScale = boundsSize.width / (imageSize?.width)!
        let yScale = boundsSize.height / (imageSize?.height)!
        var minScale = min(xScale, yScale)
        
        // calculate max
        var maxScale: CGFloat = 3.0
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            maxScale = 4.0
        }
        
        // image is smaller than screen so no zooming
        if xScale >= 1 && yScale >= 1 {
            minScale = 1.0
        }
        
        // set min/max zoom
        self.minimumZoomScale = minScale
        self.maximumZoomScale = maxScale
        
        // initial zoom
        self.zoomScale = self.initialZoomScaleWithMinScale()
        
        // if we're zooming to fill then centralise
        if self.zoomScale != minScale {
            self.contentOffset = CGPoint(x: ((imageSize?.width)! * self.zoomScale - boundsSize.width) / 2.0,
                                         y: ((imageSize?.height)! * self.zoomScale - boundsSize.height) / 2.0)
        }
        
        // disable scrolling initially until the first pinch to fix issues with swiping on an initially zoomed in photo
        self.isScrollEnabled = false
        
        self.setNeedsLayout()
    }
    
    // MARK: - layout

    override func layoutSubviews() {
        // update tap view frame
        tapView.frame = self.bounds
        
        let boundsSize = self.bounds.size
        // position indicators (centre does not seem to work!)
        if !loadingIndicator.isHidden {
            loadingIndicator.frame = CGRect(x: (boundsSize.width - loadingIndicator.frame.size.width) / 2,
                                            y: (boundsSize.height - loadingIndicator.frame.size.height) / 2,
                                            width: loadingIndicator.frame.size.width,
                                            height: loadingIndicator.frame.size.height)
        }
        
        if loadingError != nil {
            loadingError?.frame = CGRect(x: (boundsSize.width - (loadingError?.frame.size.width)!) / 2,
                                         y: (boundsSize.height - (loadingError?.frame.size.height)!) / 2,
                                         width: (loadingError?.frame.size.width)!,
                                         height: (loadingError?.frame.size.height)!)
        }
        super.layoutSubviews()
        
        // center the image as it becomes smaller than the size of the screen
        var frameToCenter = photoImageView.frame
        
        // horizontally
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2.0
        }
        else {
            frameToCenter.origin.x = 0
        }
        
        // vertically
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2.0
        }
        else {
            frameToCenter.origin.x = 0
        }
        
        // center
        if !frameToCenter.equalTo(photoImageView.frame) {
            photoImageView.frame = frameToCenter
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomingScrollView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.photoImageView
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        photoBrowser.cancelControlHiding()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.isScrollEnabled = true // reset
        photoBrowser.cancelControlHiding()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        photoBrowser.hideControlsAfterDelay()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

// MARK: - TapDetectingViewDelegate, TapDetectingImageViewDelegate

extension ZoomingScrollView: TapDetectingViewDelegate, TapDetectingImageViewDelegate {
    
    // action
    
    func handleSingleTap(_ touchPoint: CGPoint) {
        photoBrowser.controlAllAontrols()
    }
    
    func handleDoubleTap(_ touchPoint: CGPoint) {
        NSObject.cancelPreviousPerformRequests(withTarget: photoBrowser)
        // zoom
        if (self.zoomScale != self.minimumZoomScale) && (self.zoomScale != self.initialZoomScaleWithMinScale()) {
            // zoom out
            self.setZoomScale(self.minimumZoomScale, animated: true)
        }
        else {
            // zoom in to twice the size
            let newZoomScale = (self.maximumZoomScale + self.minimumZoomScale) / 2.0
            let xSize = self.bounds.size.width / newZoomScale
            let ySize = self.bounds.size.height / newZoomScale
            self.zoom(to: CGRect(x: touchPoint.x - xSize / 2.0,
                                 y: touchPoint.y - ySize / 2.0,
                                 width: xSize, height: ySize), animated: true)
        }
    }
    
    // TapDetectingImageViewDelegate
    
    func imageView(_ imageView: UIImageView, singleTapDetected touchPoint: CGPoint) {
        photoBrowser.controlAllAontrols()
    }
    
    func imageView(_ imageView: UIImageView, doubleTapDetected touchPoint: CGPoint) {
        self.handleDoubleTap(touchPoint)
    }
    
    // TapDetectingViewDelegate
    
    func view(_ view: UIView, singleTapDetected touch: UITouch) {
        var touchX = touch.location(in: view).x
        var touchY = touch.location(in: view).y
        
        touchX *= 1/self.zoomScale
        touchY *= 1/self.zoomScale
        
        touchX += self.contentOffset.x
        touchY += self.contentOffset.y
        
        print("TapDetectingView singleTap")
        self.handleSingleTap(CGPoint(x: touchX, y: touchY))
    }
    
    func view(_ view: UIView, doubleTapDetected touch: UITouch) {
        var touchX = touch.location(in: view).x
        var touchY = touch.location(in: view).y
        
        touchX *= 1/self.zoomScale
        touchY *= 1/self.zoomScale
        
        touchX += self.contentOffset.x
        touchY += self.contentOffset.y
        
        print("TapDetectingView doubleTap")
        self.handleDoubleTap(CGPoint(x: touchX, y: touchY))
    }
}
