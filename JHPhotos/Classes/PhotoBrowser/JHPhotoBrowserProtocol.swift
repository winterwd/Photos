//
//  JHPhotoBrowserProtocol.swift
//  JHPhotos
//
//  Created by winter on 2017/6/27.
//  Copyright © 2017年 DJ. All rights reserved.
//

import Foundation

@objc public protocol JHPhotoBrowserDelegate: class {
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: PhotoBrowser) -> Int
    func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) -> Photo?
    
    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, thumbPhotoAtIndex: Int) -> Photo?
    //    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, captionViewForPhotoAtIndex: Int) -> String?
    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, titleForPhotoAtIndex: Int) -> String?
    
    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, didDisplayPhotoAtIndex: Int)
    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, actionButtonPressedForPhotoAtIndex: Int)
    
    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, isPhotoSelectedAtIndex: Int) -> Bool
    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int, selectedChanged: Bool) -> Bool
    
    //    @objc optional func photoBrowserDidFinishModalPresentation(_ photoBrowser: PhotoBrowser)
}
