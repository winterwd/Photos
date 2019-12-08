//
//  PhotoAlbumSelectCell.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

class PhotoAlbumSelectCell: UITableViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var albumCountLabel: UILabel!
    
    func setPhotoListAlbum(_ model: PhotoListAlbum) {
        albumTitleLabel.text = model.title
        albumCountLabel.text = "\(model.count)"
        
        PhotoAlbumTool.requestImage(for: model.headImageAsset,
                                    size: self.albumImageView.frame.size,
                                    resizeMode: .exact,
                                    contentMode: .aspectFill) { [weak self] (image) in
                                        if let strongSelf = self {
                                            strongSelf.albumImageView.image = image
                                        }
                                    }
    }
}
