//
//  UploadPhotoProtocol.swift
//  JHPhotos
//
//  Created by winter on 2017/7/1.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Photos
import Foundation

public struct JPhoto {
    var imageData: Data?
    var asset: PHAsset?
    
    init(_ imageData: Data, asset: PHAsset? = nil) {
        self.imageData = imageData
        self.asset = asset
    }
    
    init(_ asset: PHAsset, imageData: Data? = nil) {
        self.imageData = imageData
        self.asset = asset
    }
}

public typealias JPhotoResult = (_ photoAlbums: [JPhoto]) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void
public typealias UploadResult = (_ success: Bool) -> Void

public protocol JHUploadPhotoDataDelegate {
    
    /// 将要上传选中图片 (单张)
//    func willUploadSingle(_ photo: JPhoto, idx: Int)
    
    /// 将要上传 选中 图片 到服务器上
    func willUploadAll(_ photos: [JPhoto])
    
    /// 上传图片data到服务器上
//    func startUpload(_ imageData: Data, params: [String : String], progress: UploadProgress?, result: UploadResult?)
}

public protocol JHUploadPhotoViewDelegate: class {
    /// 需要展示 上传图片的总数量
    func maxDisplayUPloadPhotoNumber() -> Int
    
    /// 返回 uploadPhotoView 高度
    func uploadPhotoView(viewHeight height: CGFloat)
    
    /// 删除
    func deletePhotoView(_ index: Int)
    
    /// 移动
    func moveItemAt(_ sourceIndex: Int, to destinationIndex: Int)
    
    /// 删除/上传失败
    func uploadPhotoViewForDeleteOrFailed(_ index: Int)
}

public extension JHUploadPhotoDataDelegate {
    
    func willUploadAll(_ photos: [JPhoto]) {}
    func willUploadSingle(_ photo: JPhoto, idx: Int) {}
    
    func startUpload(_ imageData: Data, params: [String : String], progress: UploadProgress?, result: UploadResult?) {}
    
    /// async
    func getImageDataFromJPhoto(_ photo: JPhoto, result: @escaping (Data?) -> Void ) {
        if let data = photo.imageData {
            return result(data)
        }
        guard let asset = photo.asset else { return result(nil) }
        _ = autoreleasepool {
            DispatchQueue.global(qos: .default).async {
                PhotoAlbumTool.requestImageData(for: asset, result: result)
            }
        }
    }
}

public extension JHUploadPhotoViewDelegate {
    func uploadPhotoViewForDeleteOrFailed(_ index: Int) {}
}
