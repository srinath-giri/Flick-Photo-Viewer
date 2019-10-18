//
//  Photo.swift
//  PhotoViewer
//
//  Created by Srinath Giri on 10/15/19.
//  Copyright © 2019 Rakuten. All rights reserved.
//

import Foundation

struct Photo: Codable, Equatable, Hashable {
  
  let id: String
  let owner: String
  let secret: String
  let server: String
  let farm: Int
  let title: String
  let ispublic: Int
  let isfriend: Int
  let isfamily: Int
  let date: Date = Date()
  
  var debugDescription: String {
    return "Photo<id:\(id) owner:\(owner) server:\(server) farm:\(farm)>"
  }
  
  static func == (lhs: Photo, rhs: Photo) -> Bool {
    return lhs.id == rhs.id && lhs.secret == rhs.secret && lhs.farm == rhs.farm && lhs.server == rhs.server && lhs.date == rhs.date
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(secret)
    hasher.combine(farm)
    hasher.combine(server)
  }
  
  func isHavingSamePhotoImage(as other: Photo) -> Bool {
     return id == other.id && secret == other.secret && farm == other.farm && server == other.server
  }
}
