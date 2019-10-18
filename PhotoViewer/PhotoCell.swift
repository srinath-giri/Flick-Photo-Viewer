//
//  PhotoCell.swift
//  PhotoViewer
//
//  Created by Srinath Giri on 10/15/19.
//  Copyright © 2019 Rakuten. All rights reserved.
//

import UIKit

class PhotoCell: UITableViewCell {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var photoImageView: UIImageView!
  
  var photo: Photo?

  func updateUi(photoImage: UIImage? = nil) {
    
    if let photo = photo {
      titleLabel.text = "\(photo.title)"
    } else {
      titleLabel.text = nil
    }
      
    if let photoImage = photoImage {
      photoImageView.image = photoImage
    } else {
      photoImageView.image = nil
    }
  }
}
