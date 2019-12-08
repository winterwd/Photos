//
//  PhotoAlbumCell.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Photos

class PhotoAlbum: Equatable {
    static func == (lhs: PhotoAlbum, rhs: PhotoAlbum) -> Bool {
        return lhs.asset.isEqual(rhs.asset) &&
            lhs.isSelected == rhs.isSelected &&
            lhs.canSelected == rhs.canSelected &&
            lhs.isEdited == rhs.isEdited
    }
    
    var asset: PHAsset
    var isSelected = false
    var canSelected = false
    
    var editedImageData: Data?
    var editedThumbImageData: Data?
    var isEdited = false {
        didSet {
            if isEdited {
                isSelected = true
                canSelected = true
            }
        }
    }
    
    var tempImage: UIImage?
    init(_ a: PHAsset) {
        self.asset = a
    }
}

class PhotoAlbumCell: UICollectionViewCell {
    
    typealias resultBlock = (_ obj: PhotoAlbum?) -> Void
    // MARK: - private
    fileprivate var block: resultBlock?
    fileprivate var model: PhotoAlbum!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var button: UIButton!
    
    @IBAction func buttonAction(_ sender: UIButton) {
        if model.canSelected {
            sender.isSelected = !sender.isSelected
            model.isSelected = !model.isSelected
            block?(model)
        }
        else { block?(nil) }
    }
    
    // MARK: - public
    
    func updatePhotoAlbum() {
        
        if model.isEdited {
            self.coverView.isHidden = model.canSelected
            self.button.isSelected = model.isSelected
            if let data = model.editedThumbImageData {
                imageView.image = UIImage(data: data)
            }
        }
    }
    
    func setPhotoAlbum(_ model: PhotoAlbum, selectBlock: resultBlock?) {
        self.model = model
        self.block = selectBlock
        self.coverView.isHidden = model.canSelected
        self.button.isSelected = model.isSelected
        
        if model.isEdited {
            if let data = model.editedThumbImageData {
                imageView.image = UIImage(data: data)
            }
            return
        }
        
        if let image = model.tempImage {
            return imageView.image = image
        }
        
        PhotoAlbumTool.requestImage(for: model.asset,
                                    size: self.imageView.frame.size,
                                    resizeMode: .exact,
                                    contentMode: .aspectFill) { [weak self] (image) in
                                        if let strongSelf = self {
                                            strongSelf.imageView.image = image
                                            strongSelf.model.tempImage = image
                                        }
                                    }
    }
}
