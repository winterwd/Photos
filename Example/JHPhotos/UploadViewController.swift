//
//  UploadViewController.swift
//  JHPhotos
//
//  Created by winter on 2017/7/2.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import JHPhotos

class UploadViewController: UIViewController, JHUploadPhotoDataDelegate, JHUploadPhotoViewDelegate{

    @IBOutlet weak var uploadView: UploadPhotoView!
    @IBOutlet weak var bgViewHeight: NSLayoutConstraint!
    
    var timerCount = 0
    var timer: Timer?
    var progressBlocks: [UploadProgress?] = []
    var resultBlocks: [UploadResult?] = []
    let upProgress = Progress(totalUnitCount: 10)
    
    var imageUrls: [String] = []
    var willUploadDatas: [Data] = []
    
    deinit {
        print("---> UploadViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uploadView.delegate = self as JHUploadPhotoDataDelegate & JHUploadPhotoViewDelegate
        if imageUrls.count > 0 {
            uploadView.setupImageViews(imageUrls)
        }
        
        let navItem = UIBarButtonItem(title: "上传", style: .plain, target: self, action: #selector(startUploadAll))
        navItem.tintColor = UIColor.blue
        self.navigationItem.rightBarButtonItem = navItem
    }
    
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        deTimer()
//    }
//    
//    func deTimer() {
//        timer?.invalidate()
//        timerCount = 0
//        progressBlocks.removeAll()
//        resultBlocks.removeAll()
//        upProgress.completedUnitCount = 0
//    }
    
    @objc func startUploadAll() {
        
    }
    
//    @objc func fakeUpload() {
//        self.timerCount += 1
//        upProgress.completedUnitCount += 1
//        
//        for result in progressBlocks {
//            result?((upProgress))
//        }
//        
//        if self.timerCount == 10 {
//            for result in resultBlocks {
//                result?(true)
//            }
//            self.deTimer()
//        }
//    }
//    
//    func fakeUploadDataProgress(progress: UploadProgress?, result: UploadResult?) {
//        progressBlocks.append(progress)
//        resultBlocks.append(result)
//        timerCount = 0
//        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(fakeUpload), userInfo: nil, repeats: true)
//    }
    
    // MARK: - delegate
    
//    func startUpload(_ imageData: Data, progress: UploadProgress?, result: UploadResult?) {
//        uploadDatas.append("test")
//        fakeUploadDataProgress(progress: progress, result: result)
//    }
    
    func willUploadSingle(_ imageData: Data) {
        willUploadDatas.append(imageData)
    }
    
    /// 需要展示 上传图片的总数量
    func maxDisplayUPloadPhotoNumber() -> Int {
        return 8
    }
    
    /// 返回 uploadPhotoView 高度
    func uploadPhotoView(viewHeight height: CGFloat) {
        print("uploadPhotoView height \(height)")
        bgViewHeight.constant = height + 40
    }
    
    /// 删除
    func deletePhotoView(_ index: Int) {
        print("deletePhotoView at \(index)")
        willUploadDatas.remove(at: index)
    }
}
