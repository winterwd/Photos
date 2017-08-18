//
//  UploadPhotoView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/30.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

public final class UploadPhotoView: UIView {
    
    public weak var delegate: (JHUploadPhotoViewDelegate & JHUploadPhotoDataDelegate)?{
        didSet {
            if let obj = delegate {
                viewController = SystemHelper.getCurrentPresentingVC(obj)
                uploadPhotoMaxCount = obj.maxDisplayUPloadPhotoNumber()
            }
        }
    }
    public var isDirectDisplayPhotoAlbum = true // 是否直接进入相册选择照片
    
    fileprivate weak var viewController: UIViewController?
    
    fileprivate let cellReuseIdentifier = "UploadImageCell"
    fileprivate var photoCollectionView: DragCellCollectionView!
    fileprivate var viewLayout: UICollectionViewFlowLayout! = {
        let viewLayout = UICollectionViewFlowLayout()
        viewLayout.minimumLineSpacing = 10
        viewLayout.minimumInteritemSpacing = 10
        return viewLayout
    }()
    
    fileprivate var uploadPhotoMaxCount = 0
    fileprivate var browserPhotos: [Photo] = []
    fileprivate var uploadCellPhotos: [UploadCellImage] = []
    fileprivate var addCellImage: UploadCellImage = {
        let image = UIImage.my_bundleImage(named: "icon_upload_add")
        let data =  Data()
        return UploadCellImage(image, canAdd: true)
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
        
        uploadCellPhotos.append(addCellImage)
        
        let width = self.bounds.width
        let itemW = (width-30.0) / 4.0
        viewLayout.itemSize = CGSize(width: itemW, height: itemW)
        photoCollectionView = DragCellCollectionView(frame: CGRect(x: 0, y: 0, width: width, height: itemW), collectionViewLayout: viewLayout)
        self.addSubview(photoCollectionView);
        photoCollectionView.myDelegate = self as DragCellCollectionViewDelegate
        photoCollectionView.myDataSource = self as DragCellCollectionViewDataSource
        photoCollectionView.register(UploadImageCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        
        self.layer.masksToBounds = false
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if selfWidth < 1 {
            let width = self.bounds.width
            selfWidth = width
            let itemW = (width-30.0) / 4.0
            viewLayout.itemSize = CGSize(width: itemW, height: itemW)
            self.updateSelfViewHeight()
        }
    }
    
    // MARK: - public
    
    public init(_ frame: CGRect, delegate: JHUploadPhotoViewDelegate & JHUploadPhotoViewDelegate) {
        super.init(frame: frame)
        self.delegate = delegate as? (JHUploadPhotoDataDelegate & JHUploadPhotoViewDelegate)
    }

    public func setupImageViews(_ imageUrls: [String]) {
        if imageUrls.count == 0 {
            return
        }
        
        var cellImages: [UploadCellImage]! = []
        for url in imageUrls {
            if let Url = NSURL(string: url) {
                browserPhotos.append(Photo(url: Url))
                cellImages.append(UploadCellImage(url))
            }
        }
        uploadCellPhotos.insert(contentsOf: cellImages, at: 0)
        let index = uploadCellPhotos.count - 1
        if index == uploadPhotoMaxCount {
            uploadCellPhotos.removeLast()
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
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let obj = uploadCellPhotos[indexPath.item]
        if obj.canAddNewImage {
            self.startSelectImage()
        }
        else {
            self.handlePhotoBrowser(indexPath.item)
        }
    }
}

fileprivate extension UploadPhotoView {
    
    func updateSelfViewHeight() {
        let itemH = viewLayout.itemSize.height
        let lineCount = uploadCellPhotos.count/4 + 1
        let height = itemH * CGFloat(lineCount) + 10.0 * CGFloat(lineCount-1)
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
        photoCollectionView.frame = self.bounds
        delegate?.uploadPhotoView(viewHeight: height)
    }
    
    func needUploadPhotoCount() -> Int {
        let num = uploadPhotoMaxCount - uploadCellPhotos.count + 1
        return max(0, num)
    }
    
    func addImageDatas(_ datas: [Data]) {
        if viewController == nil {
            return
        }
        
        var cellImages: [UploadCellImage]! = []
        for data in datas {
            if let image = UIImage(data:data) {
                browserPhotos.append(Photo(image: image))
                cellImages.append(UploadCellImage(image))
            }
        }
        var index = uploadCellPhotos.count - 1
        uploadCellPhotos.insert(contentsOf: cellImages, at: index)
        
        index = uploadCellPhotos.count - 1
        if index == uploadPhotoMaxCount {
            uploadCellPhotos.removeLast()
        }
        updateSelfViewHeight()
        photoCollectionView.reloadData()
    }
    
    // MARK: - action 选择图片

    func startSelectImage() {
        if let vc = viewController {
            if !isDirectDisplayPhotoAlbum {
                let selectImageView = SelectImageView(vc, maxSelectCount: needUploadPhotoCount())
                selectImageView.showView()
                selectImageView.block = { [unowned self] (datas) in
                    print("selected Photo number is \(datas.count)")
                    self.addImageDatas(datas)
                }
            }
            else {
                SystemHelper.verifyPhotoLibraryAuthorization(success: { [unowned self] () in
                    let nvc = PhotoAlbumViewController.photoAlbum(maxSelectCount: self.needUploadPhotoCount(), block: { (datas) in
                        print("selected \(datas.count) from album!")
                        self.addImageDatas(datas)
                    })
                    self.viewController?.present(nvc, animated: true, completion: nil)
                }, failed: nil)
            }
        }
        else {
            print("UploadPhotoView delegate(viewController) must not be nil")
        }
    }
    
    func handlePhotoBrowser(_ index: Int) {
        // 启动图片浏览器
        let photoBrowser = PhotoBrowser(delgegate: self)
        photoBrowser.setCurrentPageIndex(index)
        let nav = UINavigationController(rootViewController: photoBrowser)
        nav.modalTransitionStyle = .crossDissolve
        self.viewController?.present(nav, animated: true, completion: nil)
    }
}

extension UploadPhotoView: JHPhotoBrowserDelegate {
    public func numberOfPhotosInPhotoBrowser(_ photoBrowser: PhotoBrowser) -> Int {
        return browserPhotos.count
    }
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) -> Photo? {
        if photoAtIndex < browserPhotos.count {
            return browserPhotos[photoAtIndex]
        }
        return nil
    }
}
