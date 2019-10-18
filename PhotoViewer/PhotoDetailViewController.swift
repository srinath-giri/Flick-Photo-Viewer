//
//  PhotoDetailViewController.swift
//  PhotoViewer
//
//  Created by Srinath Giri on 10/16/19.
//  Copyright © 2019 Rakuten. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {
  
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var detailedPhotoImageView: UIImageView!
  
  var photo: Photo? = nil
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateUi()
  }


  func updateUi() {
    if let photo = photo {
      titleLabel.text = photo.title
      
      if let photoImage = ServerUtils.default.getCachedPhotoImage(photo: photo) {
        detailedPhotoImageView.image = photoImage
      }
    }
  }
}
