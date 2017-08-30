//
//  TestViewController.swift
//  JHPhotos
//
//  Created by winter on 2017/8/24.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import JHPhotos

class TestViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(imageView)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImageView))
        imageView.addGestureRecognizer(tapRecognizer)
    }
    
    func layoutImageView() {
        if let image = self.imageView.image {
            let padding: CGFloat = 20.0
            let bounds = self.view.bounds
            var viewFrame = bounds
            viewFrame.size.width -= padding * 2.0
            viewFrame.size.height -= padding * 2.0
            
            var imageFrame = CGRect.zero
            imageFrame.size = image.size
            
            if imageFrame.width > viewFrame.width || imageFrame.height > viewFrame.height {
                let scale = min(viewFrame.width/imageFrame.width, viewFrame.height/imageFrame.height)
                imageFrame.size.width *= scale
                imageFrame.size.height *= scale
                imageFrame.origin.x = (bounds.width - imageFrame.width) * 0.5
                imageFrame.origin.y = (bounds.height - imageFrame.height) * 0.5
                imageView.frame = imageFrame
            }
            else {
                imageView.frame = imageFrame
                imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageView()
    }
    
    @objc func didTapImageView() {
        if let image = imageView.image {
            let cropController = CropViewController(image: image, delegate: self)
            let viewFrame = self.view.convert(imageView.frame, to: self.navigationController?.view)
            cropController.presentAnimated(fromParentViewController: self, fromImage: image, fromView: nil, fromFrame: viewFrame, angle: 0, toImageFrame: CGRect.zero, setup: { 
                self.imageView.isHidden = true
            }, completion: nil)
        }
    }
    
    @IBAction func addPhotoButtonTapped(_ sender: AnyObject?) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        dismiss(animated: true) {
            let cropViewController = CropViewController(image: image)
            self.present(cropViewController, animated: true, completion: nil)
        }
    }
}

extension TestViewController: CropViewControllerDelegate {
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage: UIImage, rect: CGRect, angle: Int) {
        imageView.image = didCropToImage
        layoutImageView()
        
        imageView.isHidden = true
        cropViewController.dismissAnimated(fromParentViewController: self, croppedImage: didCropToImage, toView: self.imageView, toFrame: CGRect.zero, setup: { 
            self.layoutImageView()
        }) { 
            self.imageView.isHidden = false
        }
    }
}
