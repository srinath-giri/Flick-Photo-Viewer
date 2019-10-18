//
//  PhotosViewController.swift
//  PhotoViewer
//
//  Created by Srinath Giri on 10/15/19.
//  Copyright © 2019 Rakuten. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {

  @IBOutlet weak var photosTableView: UITableView!

  var photos: [Photo] = []
  
  var fetchedPages = 0
  var isAllPhotosFetched = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    photosTableView.dataSource = self
    photosTableView.delegate = self
  }


  func fetchPhotos(page: Int) {
    guard !isAllPhotosFetched else {
      print("All photos fetched.")
      return
    }
    
    ServerUtils.default.fetchPhotos(page: page) { [weak self] (photoResults, err) in
      if let error = err {
        print("Unable to fetch photos data from Flickr. \(error.localizedDescription)")
        return
      }
      
      guard let self = self else {
        print("VC not available anymore")
        return
      }
      
      guard let photoResults = photoResults else {
        print("No photo results")
        return
      }
      
      guard photoResults.photos.page > self.fetchedPages else {
        print("Unexpected page of photo results. photoResults.photos.page=\(photoResults.photos.page)")
        return
      }
      
      self.fetchedPages = photoResults.photos.page
      self.isAllPhotosFetched = photoResults.photos.page == photoResults.photos.pages
      
      DispatchQueue.main.async {
          let startIndex = self.photos.count
          let endIndex = startIndex + photoResults.photos.photo.count
          let rowIndexesToAdd = [Int](startIndex..<endIndex).map({ return IndexPath(row: $0, section: 0)})
          
          self.photos.append(contentsOf: photoResults.photos.photo)

          self.photosTableView.insertRows(at: rowIndexesToAdd, with: .none)
      }
    }
  }
  

  func fetchPhoto(photo: Photo) {

    ServerUtils.default.fetchPhoto(photo: photo) { [weak self, photo] (photoImage, err) in
      
      guard let self = self else {
        print("VC not available anymore")
        return
      }
    
      if let error = err {
        print("Unable to fetch photo from Flickr. \(error.localizedDescription)")
        return
      }
      
      guard photoImage != nil else {
        print("No photo image")
        return
      }
      
      DispatchQueue.main.async {
        if let visibleIndices = self.photosTableView.indexPathsForVisibleRows {
          let toReloadIndices = visibleIndices.filter() {
            guard $0.row < self.photos.count else {
              return false
            }
            return self.photos[$0.row].isHavingSamePhotoImage(as: photo)
          }
          self.photosTableView.reloadRows(at: toReloadIndices, with: .none)
        }
      }
    }
  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let photoCell = sender as? PhotoCell, let navVC = segue.destination as? UINavigationController, let sliderVC = navVC.visibleViewController as? PhotosSliderViewController {
      sliderVC.photos = self.photos
      sliderVC.initialPhoto = photoCell.photo
    }
  }

}


extension PhotosViewController: UITableViewDataSource {
  

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return photos.count + (isAllPhotosFetched ? 0 : 1)
  }

  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
    UITableViewCell {
  
      guard indexPath.row < photos.count else {
        return UITableViewCell()
      }
      
      if let photoCell = tableView.dequeueReusableCell(withIdentifier:
        "photoCell") as? PhotoCell {
        
        let photo = photos[indexPath.row]
        photoCell.photo = photo
        
        if let photoImage = ServerUtils.default.getCachedPhotoImage(photo: photo) {
          photoCell.updateUi(photoImage: photoImage)
        } else {
          photoCell.updateUi()
          fetchPhoto(photo: photo)
        }
  
        return photoCell
      }
      return UITableViewCell()
  }
}


extension PhotosViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if indexPath.row == photos.count {
      fetchPhotos(page: fetchedPages + 1)
    }
  }
  
}
