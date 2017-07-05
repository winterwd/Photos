//
//  PhotoAlbumSelectView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

let PhotoAlbumSelectCellHeight: CGFloat = 62
let albumCellIdentifier = "albumSelectCell"

class PhotoAlbumSelectView: UIView {
    
    // MARK: - property
    
    fileprivate var block: ((_ obj: PhotoListAlbum?) -> Void)? = nil
    fileprivate var currentAlbum: PhotoListAlbum?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraints: NSLayoutConstraint!
    
    lazy var albums: [PhotoListAlbum] = {
        if let a = PhotoAlbumTool.getPhotoAlbumList() {
            return a
        }
        return []
    }()
    
    lazy var coverView: UIControl = {
        let cover = UIControl(frame: CGRect.zero)
        cover.backgroundColor = UIColor(white: 0, alpha: 0.3)
        return cover
    }()
    
    
    // MARK: - private method
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let size = UIScreen.main.bounds.size
        self.frame = CGRect(x: 0, y: 64, width: size.width, height: size.height - 64)
        self.setupSubViews()
    }
    
    private func setupSubViews() {
        tableView.register(UINib(nibName: "PhotoAlbumSelectCell", bundle: SystemHelper.getMyLibraryBundle()), forCellReuseIdentifier: albumCellIdentifier)
        
        self.coverView.frame = self.bounds
        self.coverView.addTarget(self, action: #selector(hide), for: .touchUpInside)
        self.insertSubview(self.coverView, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = UIScreen.main.bounds.size
        self.frame = CGRect(x: 0, y: 64, width: size.width, height: size.height - 64)
        self.coverView.frame = self.bounds
    }
    
    fileprivate func hideForSelect(_ obj: PhotoListAlbum?) {
        block?(obj)
        self.removeFromSuperview()
    }
    
    @objc public func hide() {
        self.hideForSelect(nil)
    }
    
    // MARK: - public method
    
    class func instance() -> PhotoAlbumSelectView {
        let nib = UINib(nibName: "PhotoAlbumSelectView", bundle: SystemHelper.getMyLibraryBundle())
        return nib.instantiate(withOwner: nil, options: nil).first as! PhotoAlbumSelectView
    }
    
    func show(atView view: UIView, selectedAlbumList album: PhotoListAlbum, block: ((_ obj: PhotoListAlbum?) -> Void)?) {
        tableViewHeightConstraints.constant = CGFloat(albums.count) * PhotoAlbumSelectCellHeight
        
        self.block = block
        currentAlbum = album
        view.addSubview(self)
        
        if let index = albums.index(of: album) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
        }
    }
}

extension PhotoAlbumSelectView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: albumCellIdentifier, for: indexPath) as! PhotoAlbumSelectCell
        cell.setPhotoListAlbum(albums[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let obj = self.albums[indexPath.row]
        self.hideForSelect(obj)
    }
}
