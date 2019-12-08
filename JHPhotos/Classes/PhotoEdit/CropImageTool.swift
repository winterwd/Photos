//
//  CropImageTool.swift
//  JHPhotos
//
//  Created by winter on 2017/8/30.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

// MARK: - CroppedImageAttributes

struct CroppedImageAttributes {
    var angle = 0
    var croppedFrame = CGRect.zero
    var originalImageSize = CGSize.zero
}

// MARK: - ActivityCroppedImageProvider

class ActivityCroppedImageProvider: UIActivityItemProvider {
    var image: UIImage!
    var cropFrame = CGRect.zero
    var angle = 0
    var circular = false
    
    fileprivate var cropedImage: UIImage!
    
    init(image: UIImage, cropFrame: CGRect, angle: Int, circular: Bool) {
        super.init(placeholderItem: UIImage())
        self.image = image
        self.cropFrame = cropFrame
        self.angle = angle
        self.circular = circular
    }
    
    override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return UIImage()
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.cropedImage
    }
    
    override var item: Any {
        // If the user didn't touch the image, just forward along the original
        if self.angle == 0 && self.cropFrame.equalTo(CGRect(origin: CGPoint.zero, size: self.image.size)) {
            self.cropedImage = self.image
            return self.cropedImage
        }
        self.cropedImage = self.image.croppedImage(frame: self.cropFrame, angle: self.angle, circularClip: self.circular)
        return self.cropedImage
    }
}

// MARK: - UIImage+croppedImage

extension UIImage {
    func croppedImage(frame: CGRect, angle: Int, circularClip circular: Bool) -> UIImage {
        let alpha = self.hasAlpha()
        var croppedImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(frame.size, !alpha && !circular, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            if circular {
                context.addEllipse(in: CGRect(origin: CGPoint.zero, size: frame.size))
                context.clip()
            }
            
            // To conserve memory in not needing to completely re-render the image re-rotated,
            // map the image to a view and then use Core Animation to manipulate its rotation
            if angle != 0 {
                let imageView = UIImageView(image: self)
                imageView.layer.minificationFilter = CALayerContentsFilter.nearest
                imageView.layer.magnificationFilter = CALayerContentsFilter.nearest
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 180 * CGFloat(angle))
                let rotatedRect = imageView.bounds.applying(imageView.transform)
                let containerView = UIView(frame: CGRect(origin: CGPoint.zero, size: rotatedRect.size))
                containerView.addSubview(imageView)
                imageView.center = containerView.center
                context.translateBy(x: -frame.minX, y: -frame.minY)
                containerView.layer.render(in: context)
            }
            else {
                context.translateBy(x: -frame.minX, y: -frame.minY)
                self.draw(at: CGPoint.zero)
            }
            croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        
        if let cgImage = croppedImage?.cgImage {
            return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        }
        else {
            return self
        }
    }
    
    fileprivate func hasAlpha() -> Bool {
        if let cgImage = self.cgImage {
            let alphaInfo = cgImage.alphaInfo
            switch alphaInfo {
            case .first, .last, .premultipliedFirst, .premultipliedLast:
                return true
            default:
                return false
            }
        }
        return false
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

