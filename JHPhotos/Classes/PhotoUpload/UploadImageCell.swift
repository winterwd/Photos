//
//  UploadImageCell.swift
//  JHPhotos
//
//  Created by winter on 2017/8/17.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import Kingfisher

struct UploadCellImage {
    
    var cellImage: UIImage?
    var cellImageData: Data?
    var cellImageUrl: String?
    
    init(_ url: String?) {
        cellImageUrl = url
    }
    
    init(_ data: Data?) {
        cellImageData = data
    }
    
    init(_ image: UIImage?) {
        cellImage = image
    }
}

class UploadImageCell: UICollectionViewCell {
    
    var deletedAction: (() -> Void)?
    
//    lazy var coverView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.white
//        view.alpha = 0.3
//        return view
//    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
//    lazy var progressView: UIProgressView = {
//        let progressView = UIProgressView()
//        progressView.progressTintColor = UIColor.blue
//        progressView.progress = 0
//        progressView.layer.cornerRadius = 2.0
//        progressView.layer.masksToBounds = true
//        return progressView
//    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.isHidden = true
        button.setImage(UIImage.my_bundleImage(named: "icon_upload_delete"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(-14, 14, 0, 0)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSubView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupSubView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.bounds
//        coverView.frame = self.bounds
        let width = self.bounds.width;
//        progressView.frame = CGRect(x: 5, y: width / 2.0, width: width - 10, height: 2)
//        // 设置高度为之前3倍
//        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 3.0)

        deleteButton.frame = CGRect(x: width - 29, y: -1, width: 30, height: 30)
    }
    
    private func setupSubView() {
        self.addSubview(imageView)
//        self.addSubview(coverView)
//        self.addSubview(progressView)
        
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        self.addSubview(deleteButton)
    }
    
    @objc func deleteAction() {
        deletedAction?()
    }
    
    func UploadResult(_ success: Bool) {
        if !success {
            // 上传失败
            return
        }
        
        deleteButton.isHidden = false
//        coverView.isHidden = true
//        progressView.isHidden = true
    }
    
    // MARK: - set image 
    
    func setImage(_ cellImage: UploadCellImage) {
        var hideDeleteBtn = true
        if let url = cellImage.cellImageUrl {
            if let Url = URL(string: url) {
                let res = ImageResource(downloadURL: Url)
                imageView.kf.setImage(with: res)
//                coverView.isHidden = true
//                progressView.isHidden = true
                hideDeleteBtn = false
            }
        }
        else if let image = cellImage.cellImage {
            imageView.image = image
//            coverView.isHidden = true
//            progressView.isHidden = true
            hideDeleteBtn = false
        }
        else if let data = cellImage.cellImageData {
            let image = UIImage(data: data)
            imageView.image = image
//            coverView.isHidden = true
//            progressView.isHidden = true
            hideDeleteBtn = false
        }
        deleteButton.isHidden = hideDeleteBtn
    }
}
