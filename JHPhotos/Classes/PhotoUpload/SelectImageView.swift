//
//  SelectImageView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/30.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

fileprivate let viewSpace: CGFloat = 15
fileprivate let selectActionCount: CGFloat = 3
fileprivate let selectActionHeight: CGFloat = 55

fileprivate let jp_screenWidth = UIScreen.main.bounds.width
fileprivate let jp_screenHeight = UIScreen.main.bounds.height
// 刘海屏系列
fileprivate let jp_iPhoneXs = Int(100 * jp_screenHeight / jp_screenWidth) == 216
// 底部button距离
let jp_bottomSpace: CGFloat = jp_iPhoneXs ? 34 : 0
// 顶部导航栏高度
let jp_navBarHeight: CGFloat = jp_iPhoneXs ? 88 : 64

public class SelectImageView: UIView {
    
    public var block: JPhotoResult?
    
    fileprivate var selectButton: UIButton!
    fileprivate var maxSelectCount = 0
    fileprivate weak var delegate: UIViewController?
    
    fileprivate let lineColor = UIColor(red: 0.898, green: 0.898, blue: 0.898, alpha: 1)
    fileprivate let textColor = UIColor(red: 0.1333, green: 0.1333, blue: 0.1333, alpha: 1)

    fileprivate lazy var selectView: UIView = {
        let height = selectActionCount * selectActionHeight + viewSpace + jp_bottomSpace
        let frame = CGRect(x: 0, y: jp_screenHeight, width: jp_screenWidth, height: height)
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor(red: 0.945, green: 0.945, blue: 0.945, alpha: 1)
        
        let maskPath = UIBezierPath(roundedRect: view.bounds,
                                    byRoundingCorners: UIRectCorner(rawValue: UIRectCorner.topLeft.rawValue | UIRectCorner.topRight.rawValue),
                                    cornerRadii: CGSize(width: 15, height: 15))
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        return view
    }()
    
    fileprivate lazy var coverView: UIControl = {
        let view = UIControl(frame: CGRect(x: 0, y: 0, width: jp_screenWidth, height: jp_screenHeight))
        view.backgroundColor = UIColor.black
        view.alpha = 0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: jp_screenWidth, height: jp_screenHeight))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - public
    
    public init(_ delegate: UIViewController, maxSelectCount count: Int) {
        super.init(frame:  CGRect(x: 0, y: 0, width: jp_screenWidth, height: jp_screenHeight))
        self.delegate = delegate
        self.maxSelectCount = count
        self.backgroundColor = UIColor.clear
        self.setupSubViews()
    }
    
    public func showView() {
        if let window = UIApplication.shared.keyWindow {
            window.endEditing(true)
            window.addSubview(self)
            
            self.setFrameY(y: 0)
            let y = jp_screenHeight - selectView.frame.height
            let frame = CGRect(origin: CGPoint(x: 0, y: y), size: selectView.frame.size)
            UIView.animate(withDuration: 0.25, animations: { 
                self.selectView.frame = frame
                self.coverView.alpha = 0.3
            })
        }
    }
}

fileprivate extension SelectImageView {
    
    func handleSelectImageDatas(_ datas: [JPhoto]) {
        block?(datas)
        self.removeFromSuperview()
    }
    
    func setFrameY(y: CGFloat) {
        var frame = self.frame
        frame.origin.y = y
        self.frame = frame
    }
    
    @objc  func hide() {
        self.hideAndRemove(true)
    }
    
    func hideAndRemove(_ remove: Bool) {
        let y = selectActionHeight * selectActionCount + viewSpace + selectView.frame.minY
        let frame = CGRect(origin: CGPoint(x: 0, y: y), size: selectView.frame.size)
        UIView.animate(withDuration: 0.25, animations: {
            self.selectView.frame = frame
            self.coverView.alpha = 0
        }) { (_) in
            if remove {
                self.removeFromSuperview()
            }
            else {
                self.setFrameY(y: jp_screenHeight)
            }
        }
    }
    
    func selectViewItem(_ frame: CGRect, showLine: Bool) -> UIButton {
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor.white
        
        let button = UIButton(type: .custom)
        button.frame = view.bounds
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(textColor.withAlphaComponent(0.6), for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.backgroundColor = .white
        
        view.addSubview(button)
        
        if showLine {
            let line = UIView(frame: CGRect(x: 0, y: frame.height - 0.5, width: frame.width, height: 0.5))
            line.backgroundColor = lineColor
            view.addSubview(line)
        }
        
        self.selectView.addSubview(view)
        return button
    }
    
     func setupSubViews() {
        coverView.addTarget(self, action: #selector(hide), for: .touchUpInside)
        self.addSubview(coverView)
        self.addSubview(selectView)
        
        let buttonTitles = ["拍照", "从手机相册选择", "取消"]
        for i in 0..<Int(selectActionCount) {
            var y = CGFloat(i) * selectActionHeight
            var height = selectActionHeight
            if i == Int(selectActionCount) - 1 {
                y += viewSpace
                height += jp_bottomSpace
            }
            let itemFrame = CGRect(x: 0, y: y, width: jp_screenWidth, height: height)
            let button = self.selectViewItem(itemFrame, showLine: i == 0)
            if i == Int(selectActionCount) - 1 {
                selectButton = button
            }
            button.tag = i
            button.setTitle(buttonTitles[i], for: .normal)
            button.addTarget(self, action: #selector(buttonClickedAction(sender:)), for: .touchUpInside)
        }
    }
    
    @objc func buttonClickedAction(sender: UIButton) {
        selectButton = sender
        
        let buttonIndex = sender.tag
        
        if buttonIndex == 2 {
            self.hideAndRemove(true)
            return
        }
        
        self.hideAndRemove(false)
        
        if buttonIndex == 0 {
            // 拍照
            func takePhoto() {
                let imagePickerVC = UIImagePickerController()
                imagePickerVC.sourceType = .camera
                imagePickerVC.allowsEditing = true
                imagePickerVC.delegate = self
                delegate?.present(imagePickerVC, animated: true, completion: nil)
            }
            
            SystemHelper.verifyCameraAuthorization({ takePhoto() })
        }
        else {
            // 相册
            func selectPhoto() {
                let vc = PhotoAlbumViewController.photoAlbum(maxSelectCount: maxSelectCount, block: { [weak self] (datas) in
                    self?.handleSelectImageDatas(datas)
                })
                delegate?.present(vc, animated: true, completion: nil)
            }
            
            SystemHelper.verifyPhotoLibraryAuthorization({ selectPhoto() })
        }
    }
}

extension SelectImageView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        if let imageData = image.jpegData(compressionQuality: 0.5) {
            picker.dismiss(animated: true) { [weak self] () in
                self?.handleSelectImageDatas([JPhoto(imageData)])
                self?.removeFromSuperview()
            }
            return
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] () in
            self?.removeFromSuperview()
        }
    }
}
