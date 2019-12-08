//
//  PhotoAlbumTool.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Photos

struct PhotoListAlbum: Equatable {
    static func == (lhs: PhotoListAlbum, rhs: PhotoListAlbum) -> Bool {
        return lhs.headImageAsset == rhs.headImageAsset &&
            lhs.assetCollection == rhs.assetCollection &&
            lhs.title == rhs.title &&
            lhs.count == rhs.count
    }
    
    var title: String?
    var count: Int = 0
    var headImageAsset: PHAsset
    var assetCollection: PHAssetCollection
    
    init(title: String?, count: Int, head: PHAsset, collection: PHAssetCollection) {
        self.title = title
        self.count = count
        self.headImageAsset = head
        self.assetCollection = collection
    }
}

class PhotoAlbumTool {
    
    // MARK: - public

    /// 获取Photo内所有相册
    class func getPhotoAlbumList() -> [PhotoListAlbum] {
        var photoAblums: [PhotoListAlbum] = []
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        smartAlbums.enumerateObjects({ (collection, idx, stop) in
            // 过滤掉视频、最近删除、慢动作
            if !(collection.localizedTitle == "Recently Deleted" ||
                collection.localizedTitle == "Videos" ||
                collection.localizedTitle == "Slo-mo") {
                let assets = self.getAssets(in: collection, ascending: false)
                if let first = assets.first {
                    let title = self.transformCNAblumTitle(collection.localizedTitle)
                    let album = PhotoListAlbum(title: title, count: assets.count, head: first, collection: collection)
                    photoAblums.append(album)
                }
            }
        })
        
        // 获取用户创建的相册
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumUserLibrary, options: nil)
        userAlbums.enumerateObjects({ (collection, idx, stop) in
            // 过滤掉视频、最近删除、慢动作
            if !(collection.localizedTitle == "Recently Deleted" ||
                collection.localizedTitle == "Videos" ||
                collection.localizedTitle == "Slo-mo") {
                let assets = self.getAssets(in: collection, ascending: false)
                if let first = assets.first {
                    let title = self.transformCNAblumTitle(collection.localizedTitle)
                    let album = PhotoListAlbum(title: title, count: assets.count, head: first, collection: collection)
                    photoAblums.append(album)
                }
            }
        })
        
        return photoAblums
    }
    
    /// 获取相册内所有照片资源
    ///
    /// - Parameter ascending: 为YES时，按照照片的创建时间升序排列;为NO时，则降序排列
    /// - Returns: [PHAsset]
    class func getAllAssetInPhotoAblum(_ ascending: Bool) -> [PHAsset]? {
        var assets: [PHAsset] = []
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        result.enumerateObjects({ (obj, idx, stop) in
            assets.append(obj)
        })
        return assets
    }
    
    /// 获取指定相册内的所有图片
    ///
    /// - Parameters:
    ///   - assetCollection: 指定相册
    ///   - ascending: 按照照片的创建时间升序排列;为NO时，则降序排列
    /// - Returns: [PHAsset]
    class func getAssets(in assetCollection: PHAssetCollection, ascending: Bool) -> [PHAsset] {
        var arr: [PHAsset] = []
        let result = self.fetchAssets(in: assetCollection, ascending: ascending)
        result.enumerateObjects({ (obj, idx, stop) in
            if obj.mediaType == .image {
                arr.append(obj)
            }
        })
        return arr
    }
    
    class func enumerateAssets(in assetCollection: PHAssetCollection, ascending: Bool, block: @escaping (PHAsset, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        let result = self.fetchAssets(in: assetCollection, ascending: ascending)
        result.enumerateObjects(block)
    }
    
    /// 获取asset对应的图片
    class func requestImage(for asset:PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, contentMode: PHImageContentMode, result: @escaping (_ image: UIImage?) -> Void) {
        /**
         resizeMode：对请求的图像怎样缩放。有三种选择：None，默认加载方式；Fast，尽快地提供接近或稍微大于要求的尺寸；Exact，精准提供要求的尺寸。
         deliveryMode：图像质量。有三种值：Opportunistic，在速度与质量中均衡；HighQualityFormat，不管花费多长时间，提供高质量图像；FastFormat，以最快速度提供好的质量。
         这个属性只有在 synchronous 为 true 时有效。
         */
        let options = PHImageRequestOptions()
        options.resizeMode = resizeMode
        options.deliveryMode = .opportunistic // 控制照片质量
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        //param：targetSize 即你想要的图片尺寸，若想要原尺寸则可输入PHImageManagerMaximumSize
        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: contentMode, options: options) { (image, info) in
            result(image)
        }
    }
    
    /// 获取asset对应的imageData
    class func requestImageData(for asset:PHAsset, result: @escaping (_ imageData: Data?) -> Void) {
        /**
         resizeMode：对请求的图像怎样缩放。有三种选择：None，默认加载方式；Fast，尽快地提供接近或稍微大于要求的尺寸；Exact，精准提供要求的尺寸。
         deliveryMode：图像质量。有三种值：Opportunistic，在速度与质量中均衡；HighQualityFormat，不管花费多长时间，提供高质量图像；FastFormat，以最快速度提供好的质量。
         这个属性只有在 synchronous 为 true 时有效。
         */
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic // 控制照片质量
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        _ = autoreleasepool {
            PHCachingImageManager.default().requestImageData(for: asset, options: options, resultHandler: { (data, dataUTI, orientation, info) in
                self.compressImageQuality(data, toKByte: 1000, result: result)
            })
        }
    }
    
    // MARK: - private
    
    class func transformCNAblumTitle(_ title: String?) -> String? {
        if (title == "Slo-mo")                  { return "慢动作" }
        else if (title == "Recently Added")     { return "最近添加" }
        else if (title == "Favorites")          { return "个人收藏" }
        else if (title == "Recently Deleted")   { return "最近删除" }
        else if (title == "Videos")             { return "视频"  }
        else if (title == "All Photos")         { return "所有照片" }
        else if (title == "Selfies")            { return "自拍相册" }
        else if (title == "Screenshots")        { return "屏幕快照" }
        else if (title == "Camera Roll")        { return "相机胶卷" }
        else if (title == "Panoramas")          { return "全景照片" }
        return title
    }

    /// 获取assetCollection内所有的PHAsset
    class func fetchAssets(in assetCollection: PHAssetCollection, ascending: Bool) -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        return PHAsset.fetchAssets(in: assetCollection, options: options)
    }
    
    class func compressImageQuality(_ imageData: Data?, toKByte maxLengthKb: Int, result: ((_ data: Data?) -> Void)?) {
        let maxLength = maxLengthKb * 1000
        if let data = imageData {
            if data.count < maxLength {
                result?(data)
                return
            }
            else {
                if let image = UIImage(data: data) {
                    self.compressObjImageQuality(image, maxLength: maxLength, result: result)
                }
            }
        }
    }
    
    class func compressImageQuality(_ image: UIImage, toKByte maxLengthKb: Int, result: @escaping (_ image: UIImage?) -> Void) {
        let maxLength = maxLengthKb * 1000
        self.compressObjImageQuality(image, maxLength: maxLength) { (data) in
            if let image = UIImage(data: data!) {
                result(image)
            }
        }
    }
    
    class func compressObjImageQuality(_ image: UIImage, toKByte maxLengthKb: Int, result: ((_ data: Data?) -> Void)?) {
        let maxLength = maxLengthKb * 1000
        compressObjImageQuality(image, maxLength: maxLength, result: result)
    }
    
    private class func compressObjImageQuality(_ image: UIImage, maxLength: Int, result: ((_ data: Data?) -> Void)?) {
        var compression: CGFloat = 1.0
        if var data = image.jpegData(compressionQuality: compression) {
            if data.count < maxLength {
                result?(data)
                return
            }
            
            // 二分法压缩
            var max: CGFloat = 1.0
            var min: CGFloat = 0.0
            for _ in 0...5 {
                compression = (max + min) / 2.0
                if let temp = image.jpegData(compressionQuality: compression) {
                    data = temp
                }
                else { break }
                if data.count < Int(Double(maxLength) * 0.9) {
                    min = compression
                }
                else if data.count > maxLength {
                    max = compression
                }
                else { break }
            }
            
            if data.count < maxLength {
                result?(data)
                return
            }
            // 重新绘制新图 压缩size
            var lastDataLength = 0
            if var resultImage = UIImage(data: data) {
                while data.count > maxLength && data.count != lastDataLength {
                    lastDataLength = data.count
                    let ratio = Float(maxLength) / Float(data.count)
                    // Int 防止白边
                    let size = CGSize(width: CGFloat(Int(Float(resultImage.size.width) * sqrtf(ratio))),
                                      height: CGFloat(Int(Float(resultImage.size.height) * sqrtf(ratio))))
                    UIGraphicsBeginImageContext(size)
                    resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                    if let image = UIGraphicsGetImageFromCurrentImageContext() {
                        resultImage = image
                    }
                    UIGraphicsEndImageContext()
                    if let temp = resultImage.jpegData(compressionQuality: compression) {
                        data = temp
                    }
                    else  { break }
                }
            }
            result?(data)
        }
    }
}
