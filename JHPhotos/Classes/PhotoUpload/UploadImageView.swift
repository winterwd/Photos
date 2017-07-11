//
//  UploadImageView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/30.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Kingfisher

class UploadImageView: UIView {
    
    weak var delegate: JHUploadPhotoDataDelegate?
    
    var currentImage: UIImage?
    var clickAction: ((_ index: Int, _ isDeleted: Bool) -> Void)?

    lazy var coverView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.alpha = 0.3
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var progressView: UIProgressView = {
        let view = UIProgressView()
        view.progressTintColor = UIColor.blue
        view.progress = 0
        return view
    }()
    
    lazy var actionButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.isHidden = true
        return button
    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.isHidden = true
        button.imageEdgeInsets = UIEdgeInsetsMake(-7, 15, 0, 0)
        button.setImage(UIImage.my_bundleImage(named: "icon_upload_delete"), for: .normal)
        return button
    }()
    
    var imageViewWidth: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageViewWidth = frame.width
        self.setupSubView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubView() {
        imageView.frame = self.bounds
        self.addSubview(imageView)
        
        coverView.frame = self.bounds
        self.addSubview(coverView)
        
        progressView.frame = CGRect(x: 5, y: imageViewWidth / 2.0, width: imageViewWidth - 10, height: 2)
        // 设置高度为之前3倍
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 3.0)
        progressView.layer.cornerRadius = 2.0
        progressView.layer.masksToBounds = true
        self.addSubview(progressView)
        
        actionButton.frame = self.bounds
        actionButton.addTarget(self, action: #selector(buttonClickAction), for: .touchUpInside)
        self.addSubview(actionButton)
        
        deleteButton.frame = CGRect(x: imageViewWidth - 25, y: -10, width: 30, height: 30)
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        self.addSubview(deleteButton)
    }
    
    @objc func buttonClickAction() {
        clickAction?(self.tag, false)
    }
    
    @objc func deleteAction() {
        clickAction?(self.tag, true)
        self.removeFromSuperview()
    }
    
    func uploadResult(_ success: Bool) {
        if !success {
            // 上传失败
            return
        }
        
        actionButton.isHidden = false
        deleteButton.isHidden = false
        coverView.isHidden = true
        progressView.isHidden = true
        currentImage = imageView.image
    }
    
    // MARK: - set image url
    
    func setImage(_ url: String) {
        if let Url = URL(string: url) {
            let res = ImageResource(downloadURL: Url)
            imageView.kf.setImage(with: res,
                                  placeholder: nil,
                                  options: nil,
                                  progressBlock: nil,
                                  completionHandler: { [unowned self] (image, error, cacheType, imageUrl) in
                                    self.currentImage = image
                                    if error != nil {
                                        self.deleteButton.isHidden = true
                                        self.actionButton.isHidden = true
                                    }
            })
            deleteButton.isHidden = false
            coverView.isHidden = true
            progressView.isHidden = true
            actionButton.isHidden = false
        }
    }
    
    // MARK: - upload
    
    func uploadImage(imageData data: Data, block: @escaping (_ objView : UploadImageView, _ success: Bool) -> Void ) {
        currentImage = UIImage(data: data)
        imageView.image = currentImage
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSSS"
        let str = formatter.string(from: Date())
        let fileName = "\(str).jpg"
        
        let params = ["fileName": fileName]
        
        let progress: uploadProgress = { [unowned self] (p) in
            let x = Float(p.completedUnitCount) / Float(p.totalUnitCount)
            self.progressView.setProgress(x, animated: true)
        }
        
        let result: uploadResult = {[unowned self] (suc) in
            self.uploadResult(suc)
            block(self, suc)
        }
        
        delegate?.startUpload(data, params: params, progress: progress, result: result)
    }
}
