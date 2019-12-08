//
//  UploadPhotoView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/30.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

public final class UploadPhotoView: UIView {
    
    public weak var delegate: (JHUploadPhotoViewDelegate & JHUploadPhotoDataDelegate)? {
        didSet {
            if let obj = delegate {
                self.jp_viewController = SystemHelper.getCurrentPresentingVC(obj)
                uploadPhotoMaxCount = obj.maxDisplayUPloadPhotoNumber()
            }
        }
    }
    public var isDirectDisplayPhotoAlbum = true // 是否直接进入相册选择照片
    /// 选中图片数
    public var hasSelectImageCnt = 0
    
    fileprivate weak var jp_viewController: UIViewController?
    
    fileprivate let lineImageCount: CGFloat = 3
    fileprivate let minSpace: CGFloat = 5
    fileprivate let cellReuseIdentifier = "UploadImageCell"
    fileprivate var photoCollectionView: DragCellCollectionView!
    fileprivate var viewLayout: UICollectionViewFlowLayout! = {
        let viewLayout = UICollectionViewFlowLayout()
        viewLayout.minimumLineSpacing = 5
        viewLayout.minimumInteritemSpacing = 5
        return viewLayout
    }()
    
    fileprivate var uploadPhotoMaxCount = 0
    fileprivate var browserPhotos: [Photo] = []
    fileprivate var uploadCellPhotos: [UploadCellImage] = [] {
        didSet {
            hasSelectImageCnt = uploadCellPhotos.count
        }
    }
    
    fileprivate lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.my_bundleImage(named: "jp_icon_upload_add"), for: .normal)
        button.adjustsImageWhenHighlighted = false
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    fileprivate var selfWidth: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupViews()
    }
    
    func setupViews() {
        // 解决collectionView 下移64问题
        let view = UIView(frame: self.bounds)
        view.backgroundColor = UIColor.clear
        self.addSubview(view)
        
        let width = self.bounds.width
        let itemW = (width-(2.0 * minSpace)) / lineImageCount
        viewLayout.itemSize = CGSize(width: itemW, height: itemW)
        photoCollectionView = DragCellCollectionView(frame: CGRect(x: 0, y: 0, width: width, height: itemW), collectionViewLayout: viewLayout)
        self.addSubview(photoCollectionView);
        photoCollectionView.myDelegate = self as DragCellCollectionViewDelegate
        photoCollectionView.myDataSource = self as DragCellCollectionViewDataSource
        photoCollectionView.register(UploadImageCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        
        addButton.addTarget(self, action: #selector(startSelectImage), for: .touchUpInside)
        self.addSubview(addButton)
        self.layer.masksToBounds = false
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if selfWidth < 1 {
            let width = self.bounds.width
            selfWidth = width
            let itemW = (width-(2.0 * minSpace)) / lineImageCount
            viewLayout.itemSize = CGSize(width: itemW, height: itemW)
            self.updateSelfViewHeight()
        }
    }
    
    // MARK: - public
    
    public init(_ frame: CGRect, delegate: JHUploadPhotoDataDelegate & JHUploadPhotoViewDelegate) {
        super.init(frame: frame)
        self.delegate = delegate
    }

    public func setupImageViews(_ imageUrls: [String]) {
        if imageUrls.count == 0 {
            return
        }
        
        uploadCellPhotos.removeAll()
        for url in imageUrls {
            if let Url = URL(string: url) {
                browserPhotos.append(Photo(url: Url))
                uploadCellPhotos.append(UploadCellImage(url))
            }
        }
        photoCollectionView.reloadData()
    }
}

extension UploadPhotoView: DragCellCollectionViewDelegate, DragCellCollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uploadCellPhotos.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! UploadImageCell
        cell.setImage(uploadCellPhotos[indexPath.item])
        
//        cell.deletedAction = { [weak self] () in
//            self?.deleteImageCell(indexPath.item)
//        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.handlePhotoBrowser(indexPath.item)
    }
    
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndex: Int, to destinationIndex: Int) {
        //print("moveItemAt = \(sourceIndex+1), to = \(destinationIndex+1)")
        // UI更新位置，这里并不是交换
        
        let item = uploadCellPhotos[sourceIndex]
        uploadCellPhotos.remove(at: sourceIndex)
        uploadCellPhotos.insert(item, at: destinationIndex)

        let bitem = browserPhotos[sourceIndex]
        browserPhotos.remove(at: sourceIndex)
        browserPhotos.insert(bitem, at: destinationIndex)
//        if let image = item.cellImage {
//           browserPhotos.insert(Photo(image: image), at: destinationIndex)
//        }

        self.delegate?.moveItemAt(sourceIndex, to: destinationIndex)
    }
    
    public func collectionView(_ collectionView: UICollectionView, deleteItemAt index: Int) {
        deleteImageCell(index)
    }
}

fileprivate extension UploadPhotoView {
    
    func updateSelfViewHeight() {
        let itemH = viewLayout.itemSize.height
        
        let lineCount = uploadCellPhotos.count / Int(lineImageCount)
        let columnCount = uploadCellPhotos.count % Int(lineImageCount)
        
        var extra = 1
        if needUploadPhotoCount() != 0 {
            addButton.isHidden = false
            let buttonX: CGFloat = (itemH + minSpace) * CGFloat(columnCount)
            let buttonY: CGFloat = (itemH + minSpace) * CGFloat(lineCount)
            addButton.frame = CGRect(x: buttonX, y: buttonY, width: itemH, height: itemH)
        }
        else {
            // 不能再继续上传了
            extra = 0
            addButton.isHidden = true
        }
        
        let height = itemH * CGFloat(lineCount + extra * 1) + minSpace * CGFloat(lineCount - 1 + extra)
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
        photoCollectionView.frame = self.bounds
        delegate?.uploadPhotoView(viewHeight: height)
    }
    
    func needUploadPhotoCount() -> Int {
        let num = uploadPhotoMaxCount - uploadCellPhotos.count
        return max(0, num)
    }
    
    func addImageDatas(_ datas: [JPhoto]) {
        if jp_viewController == nil {
            return
        }
        let screen = UIScreen.main
        let scale = screen.scale
        let imageSize = max(screen.bounds.width, screen.bounds.height) * 1.5
        let imageTargetSize = CGSize(width: imageSize * scale, height: imageSize * scale)
        
        var cellImages: [UploadCellImage] = []
//        for (idx, photo) in datas.enumerated() {
        for photo in datas {
            if let data = photo.imageData {
                browserPhotos.append(Photo(data: data))
                cellImages.append(UploadCellImage(data))
            }
            else if let asset = photo.asset {
                browserPhotos.append(Photo(asset: asset, targetSize: imageTargetSize))
                cellImages.append(UploadCellImage(asset))
            }
//            self.delegate?.willUploadSingle(photo, idx: idx)
        }
        let index = uploadCellPhotos.count
        uploadCellPhotos.insert(contentsOf: cellImages, at: index)
        updateSelfViewHeight()
        photoCollectionView.reloadData()
        
        self.delegate?.willUploadAll(datas)
    }
    
    func deleteImageCell(_ index: Int) {
        browserPhotos.remove(at: index)
        uploadCellPhotos.remove(at: index)
        updateSelfViewHeight()
        photoCollectionView.reloadData()
        self.delegate?.deletePhotoView(index)
    }
    
    // MARK: - action 选择图片

    @objc func startSelectImage() {
        guard let vc = jp_viewController else {
            return print("UploadPhotoView delegate(viewController) must not be nil")
        }
        if !isDirectDisplayPhotoAlbum {
            let selectImageView = SelectImageView(vc, maxSelectCount: needUploadPhotoCount())
            selectImageView.showView()
            selectImageView.block = { [weak self] (datas) in
                self?.addImageDatas(datas)
            }
        }
        else {
            func showPhotoAlbumViewController()  {
                let nvc = PhotoAlbumViewController.photoAlbum(maxSelectCount: self.needUploadPhotoCount()) { [weak self] (datas) in
                    self?.addImageDatas(datas)
                }
                self.jp_viewController?.present(nvc, animated: true, completion: nil)
            }
            
            SystemHelper.verifyPhotoLibraryAuthorization({ showPhotoAlbumViewController() })
        }
    }
    
    func handlePhotoBrowser(_ index: Int) {
        // 启动图片浏览器
        let photoBrowser = PhotoBrowser(delgegate: self)
        photoBrowser.setCurrentPageIndex(index)
        photoBrowser.isShowDeleteBtn = true
        let nav = UINavigationController(rootViewController: photoBrowser)
        nav.modalTransitionStyle = .crossDissolve
        self.jp_viewController?.present(nav, animated: true, completion: nil)
    }
}

extension UploadPhotoView: JHPhotoBrowserDelegate {
    public func numberOfPhotosInPhotoBrowser(_ photoBrowser: PhotoBrowser) -> Int {
        return browserPhotos.count
//        return uploadCellPhotos.count
    }
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) -> Photo? {
        if photoAtIndex < browserPhotos.count {
            return browserPhotos[photoAtIndex]
        }
//        if photoAtIndex < uploadCellPhotos.count {
//            let temp = uploadCellPhotos[photoAtIndex]
//            if let image = temp.cellImage {
//                return Photo(image: image)
//            }
//            else if let data = temp.cellImageData {
//                return Photo(data: data)
//            }
//            else  if let string = temp.cellImageUrl, let url = URL(string: string) {
//                return Photo(url: url)
//            }
//            else if let asset = temp.cellAsset {
//                let screen = UIScreen.main
//                let scale = screen.scale
//                let imageSize = max(screen.bounds.width, screen.bounds.height) * 1.5
//                let imageTargetSize = CGSize(width: imageSize * scale, height: imageSize * scale)
//                return Photo(asset: asset, targetSize: imageTargetSize)
//            }
//            return nil
//        }
        return nil
    }
    
    public func photoBrowserDeleteImage(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) {
        deleteImageCell(photoAtIndex)
    }
}
