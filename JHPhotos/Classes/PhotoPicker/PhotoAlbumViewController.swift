//
//  PhotoAlbumViewController.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Photos

private let cameraPickerIdentifier = "cameraPickerCell"
private let albumPickerIdentifier = "albumPickerCell"

public final class PhotoAlbumViewController: UICollectionViewController {
    
    // MARK: - public property
    
    public var maxSelectCount: Int = 3
    public var resultBlock: ((_ imageDatas: [Data]) -> Void)?
    
    // MARK: - private property
    
    @IBOutlet fileprivate weak var titleButton: RightImageButton!
    @IBOutlet fileprivate weak var viewFlowLayout: UICollectionViewFlowLayout!
    
    fileprivate var queue: DispatchQueue? = nil
    fileprivate var selectedCount = 0 // 已经选中的照片数
    
    fileprivate var _uploadItems = NSMutableArray()
    fileprivate var selectedPhotoStatus: [Bool] = [] // 照片是否被选中状态
    
    fileprivate var currentPhotoListAlbum: PhotoListAlbum?
    fileprivate lazy var albumSelectView: PhotoAlbumSelectView = {
        return PhotoAlbumSelectView.instance()
    }()
    
    fileprivate var browserPhotos: [Photo]!
    fileprivate var albumListCount = 0
    fileprivate var albumList: [PhotoAlbum]! {
        didSet {
            self.updateAlbumList(albumList.count)
        }
    }
    
    private func updateAlbumList(_ dataCount: Int) {
        selectedPhotoStatus.removeAll()
        albumListCount = dataCount
        for _ in 0..<dataCount {
            selectedPhotoStatus.append(false)
        }
    }
    
    public class func photoAlbum(maxSelectCount count: Int, block: ((_ imageDatas: [Data]) -> Void)?) -> UINavigationController {
        let nvc = UIStoryboard(name: "PhotoAlbum", bundle: SystemHelper.getMyLibraryBundle()).instantiateInitialViewController() as! UINavigationController
        let vc = nvc.topViewController as! PhotoAlbumViewController
        vc.maxSelectCount = count
        vc.resultBlock = block
        return nvc
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        titleButton.backgroundColor = UIColor.clear
        let width = (UIScreen.main.bounds.width - 3) / 4.0
        viewFlowLayout.itemSize = CGSize(width: width, height: width)
        
        self.loadAlbumUserLibraryData()
    }

    // MARK: UICollectionViewDataSource

    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumListCount + 1
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: cameraPickerIdentifier, for: indexPath)
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: albumPickerIdentifier, for: indexPath) as! PhotoAlbumCell
            let model = albumList[indexPath.item - 1]
            model.canSelected = selectedCount < maxSelectCount || model.isSelected
            cell.setPhotoAlbum(model, selectBlock: { [unowned self] (album) in
                if album != nil {
                    self.addUploadItem(album!)
                }
                else { SystemHelper.showTip("你最多只能选择\(self.maxSelectCount)张图片！") }
            })
            return cell
        }
    }

    // MARK: UICollectionViewDelegate

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if indexPath.item == 0 {
            return
        }
        let model = albumList[indexPath.item - 1]
        if model.canSelected {
            let photoBrowser = PhotoBrowser.init(delgegate: self)
            photoBrowser.isDisplaySelectionButton = true
            photoBrowser.isCanEditPhoto = true
            photoBrowser.setCurrentPageIndex(indexPath.item - 1)
            let nav = UINavigationController(rootViewController: photoBrowser)
            nav.modalTransitionStyle = .crossDissolve
            self.present(nav, animated: true, completion: nil)
        }
    }
}

// MARK: - private method

fileprivate extension PhotoAlbumViewController {
    // 获得相机胶卷
    func loadAlbumUserLibraryData() {
        if let cameraRoll = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).lastObject {
            self.enumerateAssets(in: cameraRoll)
        }
    }
    
    func enumerateAssets(in assetCollection: PHAssetCollection) {
        let screen = UIScreen.main
        let scale = screen.scale
        // Sizing is very rough... more thought required in a real implementation
        let imageSize = max(screen.bounds.width, screen.bounds.height) * 1.5
        let imageTargetSize = CGSize(width: imageSize * scale, height: imageSize * scale)
        
        var array: [Photo] = []
        var albums: [PhotoAlbum] = []
        
        PhotoAlbumTool.enumerateAssets(in: assetCollection, ascending: false) { (obj, idx, stop) in
            let model = PhotoAlbum(obj)
            albums.append(model)
            array.append(Photo(asset: obj, targetSize: imageTargetSize))
        }
        albumList = albums
        browserPhotos = array
        
        self.setSelectCount(0)
        if currentPhotoListAlbum == nil {
            currentPhotoListAlbum = PhotoListAlbum(title: assetCollection.localizedTitle,
                                                   count: albumList.count,
                                                   head: (albumList.first?.asset)!,
                                                   collection: assetCollection)
        }
    }
    
    // obj = nil -> 超出最大选取数
    func addUploadItem(_ obj: PhotoAlbum)  {
        if obj.isSelected {
           if !_uploadItems.contains(obj) {
                self.setSelectCount(selectedCount + 1)
                _uploadItems.add(obj)
            }
        }
        else {
            self.setSelectCount(selectedCount - 1)
            _uploadItems.remove(obj)
        }
        
        if let index = self.albumList.index(where: { (item) -> Bool in
            return obj.isEqual(item)
        }) {
            self.selectedPhotoStatus[index] = obj.isSelected
        }
    }
    
    func setSelectCount(_ count: Int) {
        if count > maxSelectCount { return }
        selectedCount = count
        
        if let rightItem = self.navigationItem.rightBarButtonItem {
            rightItem.isEnabled = count > 0
            let string = "上传(\(count)/\(maxSelectCount))"
//            rightItem.title = string
            
            // 修复 设置item title 文字闪动bug
            let item = UIBarButtonItem(title: string, style: rightItem.style, target: self, action: #selector(newUploadAction(sender:)))
            item.isEnabled = rightItem.isEnabled
            item.tintColor = rightItem.tintColor
            self.navigationItem.rightBarButtonItem = item
        }
        
        self.collectionView?.reloadData()
    }
    
    @objc func newUploadAction(sender: UIBarButtonItem) {
        self.uploadAction(sender)
    }
    
    func updatePhotoListAlbum(_ obj: PhotoListAlbum?) {
        if let model = obj {
            currentPhotoListAlbum = model
            self.enumerateAssets(in: model.assetCollection)
            titleButton.setTitle(model.title, for: .normal)
        }
    }
    
    func dismiss() {
        queue?.suspend()
        if let nav = self.navigationController, nav.viewControllers.count > 1{
            nav.popViewController(animated: false)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - action

fileprivate extension PhotoAlbumViewController {
    
    @IBAction func cameraPickerAction(_ sender: UIButton) {
        if selectedCount >= maxSelectCount {
            SystemHelper.showTip("你最多只能选择\(maxSelectCount)张图片！")
            return
        }
        
        SystemHelper.verifyCameraAuthorization(success: { [unowned self] () in
            let imagePickerVC = UIImagePickerController()
            imagePickerVC.sourceType = .camera
            imagePickerVC.allowsEditing = false
            imagePickerVC.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            self.present(imagePickerVC, animated: true, completion: nil)
        }, failed: nil)
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss()
    }
    
    @IBAction func selectPhotoAlbumAction(_ sender: RightImageButton) {
        self.changeButtonState(sender)
        if sender.isSelected {
            albumSelectView.show(atView: self.view,
                                 selectedAlbumList: currentPhotoListAlbum!,
                                 block: { [unowned self] (obj) in
                                            self.changeButtonState(sender)
                                            self.updatePhotoListAlbum(obj)
                                        })
        }
        else {
            albumSelectView.hide()
            self.changeButtonState(sender)
        }
    }
    
    func changeButtonState(_ sender: RightImageButton) {
        sender.isSelected = !sender.isSelected
        let hlImageName = sender.isSelected ? "icon_upload_more_s" : "icon_upload_more"
        sender.setImage(UIImage.my_bundleImage(named: hlImageName), for: .normal)
        sender.setImage(UIImage.my_bundleImage(named: hlImageName), for: .highlighted)
    }
    
    @IBAction func uploadAction(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        _ = autoreleasepool {
            // hud... "请稍后..."
            
            let cQueue = DispatchQueue.global(qos: .default)
            queue = cQueue
            cQueue.async {
                var array: [Data] = []
                for obj in self._uploadItems {
                     let obj = obj as! PhotoAlbum
                    PhotoAlbumTool.requestImageData(for: obj.asset, result: { (data) in
                        if let data = data { array.append(data) }
                    })
                }
                
                DispatchQueue.main.async {
                    self.resultBlock?(array)
                    self.dismiss()
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension PhotoAlbumViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            if let imageData = UIImageJPEGRepresentation(image, 0.5) {
                resultBlock?([imageData])
            }
        }
        else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            if let imageData = UIImageJPEGRepresentation(image, 0.5) {
                resultBlock?([imageData])
            }
        }
        else {
            print("Something went wrong")
        }
        
        picker.dismiss(animated: false) { 
            self.dismiss()
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - JHPhotoBrowserDelegate

extension PhotoAlbumViewController: JHPhotoBrowserDelegate {
    public func numberOfPhotosInPhotoBrowser(_ photoBrowser: PhotoBrowser) -> Int {
        return browserPhotos.count
    }
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) -> Photo? {
        if photoAtIndex < browserPhotos.count {
            return browserPhotos[photoAtIndex]
        }
        return nil
    }
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, isPhotoSelectedAtIndex: Int) -> Bool {
        return selectedPhotoStatus[isPhotoSelectedAtIndex]
    }
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int, selectedChanged: Bool) -> Bool {

        if selectedChanged && selectedCount >= maxSelectCount {
            SystemHelper.showTip("你最多只能选择\(maxSelectCount)张图片！")
            return false
        }
        
        let model = albumList[photoAtIndex]
        model.isSelected = selectedChanged
        self.addUploadItem(model)
        print("Photo at index \(photoAtIndex) selected \(selectedChanged ? "YES" : "NO")")
        return true
    }
}
