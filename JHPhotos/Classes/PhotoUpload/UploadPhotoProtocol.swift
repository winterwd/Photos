//
//  UploadPhotoProtocol.swift
//  JHPhotos
//
//  Created by winter on 2017/7/1.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Foundation

public typealias UploadProgress = (_ progress: Progress) -> Void
public typealias UploadResult = (_ success: Bool) -> Void

public protocol JHUploadPhotoDataDelegate: class {
    /// 上传图片data到服务器上
    func startUpload(_ imageData: Data, params: [String : String], progress: UploadProgress?, result: UploadResult?)
}

public protocol JHUploadPhotoViewDelegate: class {
    /// 需要展示 上传图片的总数量
    func maxDisplayUPloadPhotoNumber() -> Int
    
    /// 返回 uploadPhotoView 高度
    func uploadPhotoView(viewHeight height: CGFloat)
    
    /// 删除/上传失败
    func uploadPhotoViewForDeleteOrFailed(_ index: Int)
}
