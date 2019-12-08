//
//  ViewController.swift
//  JHPhotos
//
//  Created by winter on 06/23/2017.
//  Copyright (c) 2017 winter. All rights reserved.
//

import UIKit
import Photos
import JHPhotos

class ViewController: UIViewController {
    
    var tableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    
    var photos: [Photo]! {
        didSet {
            self.updateDatas(photos.count)
        }
    }
    var thumbsPhotos: [Photo]!
    
    let webPhotos: [Photo] = {
        let photo1 = Photo(url: URL(string: "http://farm6.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"))
        let photo2 = Photo(url: URL(string: "http://farm6.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"))
        let photo3 = Photo(url: URL(string: "http://farm6.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"))
        let photo4 = Photo(url: URL(string: "http://farm6.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg"))
        let photo5 = Photo(url: URL(string: "http://farm6.static.flickr.com/2449/4052876281_6e068ac860_b.jpg"))
        return [photo1, photo2, photo3, photo4, photo5]
    }()
    
    let webThumbsPhotos: [Photo] = {
        let photo1 = Photo(url: URL(string: "http://farm6.static.flickr.com/3567/3523321514_371d9ac42f_q.jpg"))
        let photo2 = Photo(url: URL(string: "http://farm6.static.flickr.com/3629/3339128908_7aecabc34b_q.jpg"))
        let photo3 = Photo(url: URL(string: "http://farm6.static.flickr.com/3364/3338617424_7ff836d55f_q.jpg"))
        let photo4 = Photo(url: URL(string: "http://farm6.static.flickr.com/3590/3329114220_5fbc5bc92b_q.jpg"))
        let photo5 = Photo(url: URL(string: "http://farm6.static.flickr.com/2449/4052876281_6e068ac860_q.jpg"))
        return [photo1, photo2, photo3, photo4, photo5]
    }()
    
    var photoCount = 0
    var selectedPhotoStatus: [Bool] = []
    
    var showType = "Modal"
    var showSource = "网络"
    
    lazy var selectImageView: SelectImageView = {
        return SelectImageView(self, maxSelectCount: 8)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        photos = webPhotos
        thumbsPhotos = webThumbsPhotos
        
        selectImageView.block = { (datas) in
            print("selected Photo number is \(datas.count)")
        }
    }

    private func updateDatas(_ dataCount: Int) {
        selectedPhotoStatus.removeAll()
        photoCount = dataCount
        for _ in 0..<dataCount {
            selectedPhotoStatus.append(false)
        }
    }
    
    @IBAction func navButtonItemAction(_ sender: UIBarButtonItem) {
        if sender.tag == 3 {
            self.navigationController?.pushViewController(TestCropViewController(), animated: true)
        }
        else if sender.tag == 0 {
            if showSource == "相册" {
                showSource = "网络"
                sender.title = showSource
            }
            else {
                showSource = "相册"
                sender.title = showSource
            }
        }
        else {
            if showType == "Modal" {
                showType = "Push"
                sender.title = showType
            }
            else {
                showType = "Modal"
                sender.title = showType
            }
        }
        self.loadAllData()
    }

    @IBAction func action(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            // select photo
            SystemHelper.verifyPhotoLibraryAuthorization({
                let nvc = PhotoAlbumViewController.photoAlbum(maxSelectCount: 8, block: { (datas) in
                    print("selected \(datas.count) from album!")
                })
                self.present(nvc, animated: true, completion: nil)
            }, failed: nil)
            break
        case 1:
            // show all photo
            let photoBrowser = PhotoBrowser.init(delgegate: self)
            
            if showType == "Modal" {
                let nav = UINavigationController(rootViewController: photoBrowser)
                nav.modalTransitionStyle = .crossDissolve
                self.present(nav, animated: true, completion: nil)
            }
            else {
                self.navigationController?.pushViewController(photoBrowser, animated: true)
            }
            break
        case 2:
            selectImageView.showView()
            break
        case 3:
            let images = ["http://www.qqjia.com/z/02/tu5082_4.jpg",
                          "http://www.qqjia.com/z/02/tu5082_5.jpg"]
            self.performSegue(withIdentifier: "UploadViewController", sender: images)
            break
        default:
            break
        }
    }
    
    // MARK: - load assets
    
    private func loadAllData() {
        switch showSource {
        case "网络":
            photos = webPhotos
            thumbsPhotos = webThumbsPhotos
            break
        case "相册":
            self.loadAssets()
            break
        default: break
        }
    }
    
    private func loadAssets() {
        SystemHelper.verifyPhotoLibraryAuthorization({
            self.performLoadAssets()
            }, failed: {
                SystemHelper.showTip("未获得授权，将显示默认图片")
        })
    }
    
    private func performLoadAssets() {
        DispatchQueue.global(qos: .default).async {
            var results: [PHAsset] = []
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResults = PHAsset.fetchAssets(with: options)
            fetchResults.enumerateObjects({ (obj, idx, stop) in
                results.append(obj)
            })
            if results.count > 0 {
                self.perform(#selector(self.handleLoadAssets(data:)), on: Thread.main, with: results, waitUntilDone: false)
            }
        }
    }
    
    @objc private func handleLoadAssets(data: [PHAsset]) {
        let screen = UIScreen.main
        let scale = screen.scale
        let imageSize = max(screen.bounds.width, screen.bounds.height) * 1.5
        let imageTargetSize = CGSize(width: imageSize / 3.0 * scale, height: imageSize / 3.0 * scale)
        let thumbTargetSize = CGSize(width: imageSize / 3.0 * scale, height: imageSize / 3.0 * scale)
        
        var results: [Photo] = []
        var thumbResults: [Photo] = []
        for obj in data {
            let p = Photo(asset: obj, targetSize: imageTargetSize)
            let tp = Photo(asset: obj, targetSize: thumbTargetSize)
            
            results.append(p)
            thumbResults.append(tp)
        }
        
        photos = results
        thumbsPhotos = thumbResults
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UploadViewController" {
            if let vc = segue.destination as? UploadViewController {
                vc.imageUrls = sender as! [String]
            }
        }
    }
}

extension ViewController: JHPhotoBrowserDelegate {
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: PhotoBrowser) -> Int {
        return photos.count
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) -> Photo? {
        if photoAtIndex < photoCount {
            return photos[photoAtIndex]
        }
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbPhotoAtIndex: Int) -> Photo? {
        if thumbPhotoAtIndex < photoCount {
            return thumbsPhotos[thumbPhotoAtIndex]
        }
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, isPhotoSelectedAtIndex: Int) -> Bool {
        return selectedPhotoStatus[isPhotoSelectedAtIndex]
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int, selectedChanged: Bool) -> Bool {
        print("Photo at index \(photoAtIndex) selected \(selectedChanged ? "YES" : "NO")")
        selectedPhotoStatus[photoAtIndex] = selectedChanged
        return true
    }
}
