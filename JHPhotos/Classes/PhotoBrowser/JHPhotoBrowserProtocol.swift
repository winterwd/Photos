//
//  JHPhotoBrowserProtocol.swift
//  JHPhotos
//
//  Created by winter on 2017/6/27.
//  Copyright © 2017年 DJ. All rights reserved.
//

import Foundation

public protocol JHPhotoBrowserDelegate: class {
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: PhotoBrowser) -> Int
    func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) -> Photo?
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbPhotoAtIndex: Int) -> Photo?
    //    @objc optional func photoBrowser(_ photoBrowser: PhotoBrowser, captionViewForPhotoAtIndex: Int) -> String?
    func photoBrowser(_ photoBrowser: PhotoBrowser, titleForPhotoAtIndex: Int) -> String?
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didDisplayPhotoAtIndex: Int)
    func photoBrowser(_ photoBrowser: PhotoBrowser, actionButtonPressedForPhotoAtIndex: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, isPhotoSelectedAtIndex: Int) -> Bool
    func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int, selectedChanged: Bool) -> Bool
    
    //    @objc optional func photoBrowserDidFinishModalPresentation(_ photoBrowser: PhotoBrowser)
}

public extension JHPhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbPhotoAtIndex: Int) -> Photo? { return nil }
    func photoBrowser(_ photoBrowser: PhotoBrowser, titleForPhotoAtIndex: Int) -> String? { return nil }
    func photoBrowser(_ photoBrowser: PhotoBrowser, didDisplayPhotoAtIndex: Int) {}
    func photoBrowser(_ photoBrowser: PhotoBrowser, actionButtonPressedForPhotoAtIndex: Int) {}
    func photoBrowser(_ photoBrowser: PhotoBrowser, isPhotoSelectedAtIndex: Int) -> Bool { return false }
    func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int, selectedChanged: Bool) -> Bool { return true }
}
