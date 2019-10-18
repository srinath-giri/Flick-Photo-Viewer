//
//  PhotosSliderViewController.swift
//  PhotoViewer
//
//  Created by Srinath Giri on 10/16/19.
//  Copyright © 2019 Rakuten. All rights reserved.
//

import UIKit

class PhotosSliderViewController: UIPageViewController {
  
  var photos: [Photo] = []
  
  var initialPhoto: Photo? = nil

  override func viewDidLoad() {
    
    self.dataSource = self
    
    if let initialPhoto = initialPhoto {
      
      if let initilPhotoDetailViewController = generatePhotoDetailViewController(photo: initialPhoto) {
        setViewControllers([initilPhotoDetailViewController],
                         direction: .forward,
                         animated: true,
                         completion: nil)
      }
      
      if ServerUtils.default.getCachedPhotoImage(photo: initialPhoto) == nil {
        self.fetchPhotoImage(photo: initialPhoto)
      }
    }
  }
  

  func generatePhotoDetailViewController(photo: Photo) -> PhotoDetailViewController? {
    
    if let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "photoDetailViewController") as? PhotoDetailViewController {
      photoVC.photo = photo
      return photoVC
    }
    
    return nil
  }
  

  func fetchPhotoImage(photo: Photo) {
    
   ServerUtils.default.fetchPhoto(photo: photo) { [weak self, photo] (photoImage, err) in
      
      guard let self = self else {
        print("VC not available anymore")
        return
      }
      
      if let error = err {
        print("Unable to fetch photo from Flickr. \(error.localizedDescription)")
        return
      }
      
      guard let photoImage = photoImage else {
        print("No photo image")
        return
      }
      
      DispatchQueue.main.async {
        
        if let viewControllers = self.viewControllers {
        
          let existingPhotoDetailViewControllers: [PhotoDetailViewController] = viewControllers.compactMap() {
          
            if let photoDetailViewController = $0 as? PhotoDetailViewController, let photoInVC = photoDetailViewController.photo, photoInVC.isHavingSamePhotoImage(as: photo) {
                return photoDetailViewController
            }
            return nil
          }

          for existingPhotoDetailViewController in existingPhotoDetailViewControllers {
            existingPhotoDetailViewController.updateUi()
            print("PhotoDetailVC already shown or visible. Updating the detailed photo image for photo. photo=\(photo) photoImage=\(photoImage)")
          }
        }
      }
    }
  }
  

  @IBAction func donePressed(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}


extension PhotosSliderViewController: UIPageViewControllerDataSource {
  

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController) -> UIViewController? {
    if let photoVC = viewController as? PhotoDetailViewController, let currentPhoto = photoVC.photo {
      if let currentIndex = photos.firstIndex(where: { return $0 == currentPhoto }) {
        if currentIndex > 0 {
          let previousPhoto = photos[currentIndex - 1]
          let previousPhotoVC = generatePhotoDetailViewController(photo: previousPhoto)
          
          if ServerUtils.default.getCachedPhotoImage(photo: previousPhoto) == nil {
            self.fetchPhotoImage(photo: previousPhoto)
          }

          return previousPhotoVC
        }
      }
    }
    return nil
  }
  

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController) -> UIViewController? {
    if let photoVC = viewController as? PhotoDetailViewController, let currentPhoto = photoVC.photo {
      if let currentIndex = photos.firstIndex(where: { return $0 == currentPhoto }) {
        if currentIndex < (photos.count - 1) {
          let nextPhoto = photos[currentIndex + 1]
          let nextPhotoVC = generatePhotoDetailViewController(photo: nextPhoto)
          
          if ServerUtils.default.getCachedPhotoImage(photo: nextPhoto) == nil {
            self.fetchPhotoImage(photo: nextPhoto)
          }
          
          return nextPhotoVC
        }
      }
    }
    return nil
  }
}
