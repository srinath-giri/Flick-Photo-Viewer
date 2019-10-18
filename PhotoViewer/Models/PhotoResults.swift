//
//  PhotoResults.swift
//  PhotoViewer
//
//  Created by Srinath Giri on 10/15/19.
//  Copyright © 2019 Rakuten. All rights reserved.
//

struct PhotoResults: Codable, CustomDebugStringConvertible {
  
  let photos: PhotoResultsPage
  let stat: String
  
  var debugDescription: String {
    return "PhotoResults<photos:\(photos) stat:\(stat)>"
  }
}

struct PhotoResultsPage: Codable, CustomDebugStringConvertible  {
  
  let page: Int
  let perpage: Int
  
  let pages: Int
  let total: Int
  
  let photo: [Photo]
  
  var debugDescription: String {
    return "PhotoResultsPage<page:\(page) perpage:\(perpage) pages:\(pages) total:\(total)>"
  }

}
