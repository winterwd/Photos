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
    @IBOutlet weak var uploadViewHeight: NSLayoutConstraint!
    
    var timerCount = 0
    var timer: Timer?
    var progressBlocks: [UploadProgress?] = []
    var resultBlocks: [UploadResult?] = []
    let upProgress = Progress(totalUnitCount: 10)
    
    var uploadDatas: [String] = []
    
    deinit {
        print("---> UploadViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uploadView.delegate = self as JHUploadPhotoDataDelegate & JHUploadPhotoViewDelegate
        if uploadDatas.count > 0 {
            uploadView.setupImageViews(uploadDatas)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deTimer()
    }
    
    func deTimer() {
        timer?.invalidate()
        timerCount = 0
        progressBlocks.removeAll()
        resultBlocks.removeAll()
        upProgress.completedUnitCount = 0
    }
    
    @objc func fakeUpload() {
        self.timerCount += 1
        upProgress.completedUnitCount += 1
        
        for result in progressBlocks {
            result?((upProgress))
        }
        
        if self.timerCount == 10 {
            for result in resultBlocks {
                result?(true)
            }
            self.deTimer()
        }
    }
    
    func fakeUploadDataProgress(progress: UploadProgress?, result: UploadResult?) {
        progressBlocks.append(progress)
        resultBlocks.append(result)
        timerCount = 0
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(fakeUpload), userInfo: nil, repeats: true)
    }
    
    // MARK: - delegate
    
    func startUpload(_ imageData: Data, params: [String : String], progress: UploadProgress?, result: UploadResult?) {
        uploadDatas.append("test")
        fakeUploadDataProgress(progress: progress, result: result)
    }
    
    /// 需要展示 上传图片的总数量
    func maxDisplayUPloadPhotoNumber() -> Int {
        return 8 - uploadDatas.count
    }
    
    /// 返回 uploadPhotoView 高度
    func uploadPhotoView(viewHeight height: CGFloat) {
        print("uploadPhotoView height \(height)")
        uploadViewHeight.constant = height
    }
    
    /// 删除/上传失败
    func uploadPhotoViewForDeleteOrFailed(_ index: Int) {
        uploadDatas.remove(at: index)
    }
}
