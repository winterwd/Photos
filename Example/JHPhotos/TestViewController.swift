//
//  TestViewController.swift
//  JHPhotos
//
//  Created by winter on 2017/8/24.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import JHPhotos

class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black
        
        let gridView = CropOverlayView(frame: CGRect(x: 50, y: 100, width: 250, height: 300))
        
        self.view.addSubview(gridView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
