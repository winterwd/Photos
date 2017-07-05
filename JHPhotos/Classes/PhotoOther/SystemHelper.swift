//
//  SystemHelper.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Photos

public typealias SystemHelperResult = () -> Swift.Void

open class SystemHelper {
    
    // MARK: - Authorization
    
    /// 验证系统"照片"授权状态, 如果权限被关闭, 提示用户去隐私设置中打开
    ///
    /// - Parameters:
    ///   - success: 验证成功后回调
    ///   - failed: 验证失败后回调
    public class func verifyPhotoLibraryAuthorization(success: SystemHelperResult? = nil, failed: SystemHelperResult? = nil) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined: // 第一次授权
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                DispatchQueue.main.async {
                    if authorizationStatus == .authorized { success?() } // 同意授权
                    else { failed?() }
                }
            })
            break
        case .authorized:
            // 已授权
            success?()
            break
        default:
            // 相册 未授权
            self.showSettingAlert("请在iPhone的“设置->隐私->照片”中打开本应用的访问权限",cancel: failed)
            break
        }
    }
    
    /// 验证系统"相机"授权状态, 如果权限被关闭, 提示用户去隐私设置中打开
    ///
    /// - Parameters:
    ///   - success: 验证成功后回调
    ///   - failed: 验证失败后回调
    public class func verifyCameraAuthorization(success: SystemHelperResult? = nil, failed: SystemHelperResult? = nil) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.showTip("该设备不支持拍照！")
            failed?()
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch status {
        case .notDetermined: // 第一次授权
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    if granted { success?() } // 同意授权
                    else {  failed?() }
                }
            })
            break
        case .authorized:
            // 已授权
            success?()
            break
        default:
            // 相机 未授权
            self.showSettingAlert("请在iPhone的“设置->隐私->相机”中打开本应用的访问权限", cancel: failed)
            break
        }
    }
    
    // MARK: - other
    
    private class func showSettingAlert(_ tip: String, cancel: SystemHelperResult? = nil) {
        self.showActionAlert(tip, action: {_ in
            let app = UIApplication.shared
            let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString)!
            if app.canOpenURL(settingsURL as URL) {
                app.openURL(settingsURL as URL)
            }
        }, cancel: cancel)
    }
    
    /// 系统提示框，action->"知道了"
    ///
    /// - Parameter tip: 提示内容
    public class func showTip(_ tip: String) {
        if let viewController = self.presentingViewController() {
            let alert = UIAlertController.init(title: "提示", message: tip, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "知道了", style: .cancel, handler: nil))
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    /// 系统提示框
    ///
    /// - Parameters:
    ///   - tip: 提示内容
    ///   - action: "前往"
    ///   - cancel: 取消操作
    public class func showActionAlert(_ tip: String, action: SystemHelperResult? = nil, cancel: SystemHelperResult? = nil) {
        if let viewController = self.presentingViewController() {
            let alert = UIAlertController.init(title: "提示", message: tip, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (_) in
                cancel?()
            }))
            alert.addAction(UIAlertAction.init(title: "前往", style: .default, handler: { (_) in
                action?()
            }))
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    public class func getCurrentPresentingVC(_ objView: AnyObject) -> UIViewController? {
        if objView.isKind(of: UIViewController.self) {
            return objView as? UIViewController
        }
        else if objView.isKind(of: UIView.self) {
            return self.getCurrentPresentingViewController(objView as! UIView)
        }
        else { return nil }
    }
    
    private class func getCurrentPresentingViewController(_ objView: UIView) -> UIViewController? {
        var next = objView.superview
        while next != nil {
            if let nextResponder = next?.next {
                if nextResponder.isKind(of: UIViewController.self) {
                    return nextResponder as? UIViewController
                }
            }
            next = next?.superview
        }
        return nil
    }
    
    /// 获取当前正在显示的ViewController
    ///
    /// - Returns: 返回当前正在显示的ViewController
    public class func presentingViewController() -> UIViewController? {
        var window = UIApplication.shared.keyWindow
        if window?.windowLevel != 0.0 {
            let windows = UIApplication.shared.windows
            for obj in windows {
                if obj.windowLevel == 0.0 {
                    window = obj
                    break
                }
            }
        }
        
        if var result = window?.rootViewController {
            while result.presentedViewController != nil {
                result = result.presentedViewController!
            }
            if result is UITabBarController {
                let temp = result as! UITabBarController
                result = (temp.viewControllers?[temp.selectedIndex])!
            }
            if result is UINavigationController {
                let temp = result as! UINavigationController
                result = temp.topViewController!
            }
            return result
        }
        return nil
    }
}
