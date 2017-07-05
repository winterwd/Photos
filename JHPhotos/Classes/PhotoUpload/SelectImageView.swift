//
//  SelectImageView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/30.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

fileprivate let viewSpace: CGFloat = 10
fileprivate let selectActionCount: CGFloat = 3
fileprivate let selectActionHeight: CGFloat = 45

fileprivate let screenWidth = UIScreen.main.bounds.width
fileprivate let screenHeight = UIScreen.main.bounds.height

public class SelectImageView: UIView {
    
    public var block: ((_ imageDatas: [Data]) -> Void)?
    
    fileprivate var selectButton: UIButton!
    fileprivate var maxSelectCount = 0
    fileprivate weak var delegate: UIViewController?
    
    fileprivate let lineColor = UIColor.lightGray
    fileprivate let textColor = UIColor(red: 0.1333, green: 0.1333, blue: 0.1333, alpha: 1)

    fileprivate lazy var selectView: UIView = {
        let height = selectActionCount * selectActionHeight + viewSpace
        let view = UIView(frame: CGRect(x: 0, y: screenHeight, width: screenWidth, height: height))
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    fileprivate lazy var coverView: UIControl = {
        let view = UIControl(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        view.backgroundColor = UIColor.black
        view.alpha = 0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - public
    
    public init(_ delegate: UIViewController, maxSelectCount count: Int) {
        super.init(frame:  CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
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
            let y = screenHeight - selectView.frame.height
            let frame = CGRect(origin: CGPoint(x: 0, y: y), size: selectView.frame.size)
            UIView.animate(withDuration: 0.25, animations: { 
                self.selectView.frame = frame
                self.coverView.alpha = 0.3
            })
        }
    }
}

fileprivate extension SelectImageView {
    
    func handleSelectImageDatas(_ datas: [Data]) {
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
                self.setFrameY(y: screenHeight)
            }
        }
    }
    
    func selectViewItem(_ frame: CGRect) -> UIButton {
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor.white
        
        let line = UIView(frame: CGRect(x: 0, y: frame.height - 0.5, width: frame.width, height: 0.5))
        line.backgroundColor = lineColor
        
        let button = UIButton(type: .custom)
        button.frame = view.bounds
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(textColor.withAlphaComponent(0.6), for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        view.addSubview(button)
        view.addSubview(line)
        self.selectView.addSubview(view)
        return button
    }
    
     func setupSubViews() {
        coverView.addTarget(self, action: #selector(hide), for: .touchUpInside)
        self.addSubview(coverView)
        self.addSubview(selectView)
        
        let buttonTitles = ["从手机相册选择", "拍照", "取消"]
        for i in 0..<Int(selectActionCount) {
            var y = CGFloat(i) * selectActionHeight
            if i == Int(selectActionCount) - 1 {
                y += viewSpace
            }
            let button = self.selectViewItem(CGRect(x: 0, y: y, width: screenWidth, height: selectActionHeight))
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
        
        if buttonIndex == 1 {
            // 拍照
            SystemHelper.verifyCameraAuthorization(success: { [unowned self] () in
                let imagePickerVC = UIImagePickerController()
                imagePickerVC.sourceType = .camera
                imagePickerVC.allowsEditing = true
                imagePickerVC.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
                self.delegate?.present(imagePickerVC, animated: true, completion: nil)
            }, failed: nil)
        }
        else {
            // 相册
            SystemHelper.verifyPhotoLibraryAuthorization(success: { [unowned self] () in
                let vc = PhotoAlbumViewController.photoAlbum(maxSelectCount: self.maxSelectCount, block: { [unowned self] (datas) in
                    self.handleSelectImageDatas(datas)
                })
                self.delegate?.present(vc, animated: true, completion: nil)
            }, failed: nil)
        }
    }
}

extension SelectImageView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        if let imageData = UIImageJPEGRepresentation(image, 0.5) {
            picker.dismiss(animated: true) { [unowned self] () in
                self.handleSelectImageDatas([imageData])
                self.removeFromSuperview()
            }
            return
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [unowned self] () in
            self.removeFromSuperview()
        }
    }
}
