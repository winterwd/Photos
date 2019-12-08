//
//  PhotoConstants.swift
//  JHPhotos
//
//  Created by winter on 2019/12/8.
//  Copyright © 2019 W. All rights reserved.
//

import UIKit

let jp_screenWidth = UIScreen.main.bounds.width
let jp_screenHeight = UIScreen.main.bounds.height

// 刘海屏系列
fileprivate let jp_iPhoneXs = Int(100 * jp_screenHeight / jp_screenWidth) == 216
// 底部button距离
let jp_bottomSpace: CGFloat = jp_iPhoneXs ? 34 : 0
// 顶部导航栏高度
let jp_navBarHeight: CGFloat = jp_iPhoneXs ? 88 : 64
