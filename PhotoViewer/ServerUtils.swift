//
//  ServerUtils.swift
//  PhotoViewer
//
//  Created by Srinath Giri on 10/15/19.
//  Copyright © 2019 Rakuten. All rights reserved.
//

import UIKit

class ServerUtils {

  let session: URLSession
  let flickrApiUrl: URL
  let apiKey: (param: String, value: String)
  
  var photoImageCache: [String: UIImage] = [:]
  var photoFetchTasksInProgress: [String: URLSessionDataTask] = [:]
  
  static private let _serverUtils = ServerUtils()
  
  typealias FetchPhotosCompletionHandler = (_ photosResult: PhotoResults?, _ err: Error?) -> Void
  typealias FetchPhotoCompletionHandler = (_ photoImage: UIImage?, _ err: Error?) -> Void
  
  static var `default`: ServerUtils {
    return _serverUtils
  }
  

  private init() {
    session = URLSession.shared
    flickrApiUrl = URL(string: "https://www.flickr.com/services/rest")!
    apiKey = ("api_key", "fee10de350d1f31d5fec0eaf330d2dba")
  }
  
  
  func getCachedPhotoImage(photo: Photo) -> UIImage? {
      return photoImageCache[buildImageUrlString(photo: photo)]
  }
  

  func buildHTTPGetRequest(baseUrl: URL, params: [String: String]) -> URLRequest? {
    var components = URLComponents()
    components.host = baseUrl.host
    components.path = baseUrl.path
    components.scheme = baseUrl.scheme
    
    var queryItems: [URLQueryItem] = []
    
    queryItems.append(URLQueryItem(name: apiKey.param, value: apiKey.value))
    
    for (param, value) in params {
      queryItems.append(URLQueryItem(name: param, value: value))
    }
    
    components.queryItems = queryItems
    
    guard let urlWithQueryItems = components.url else {
      print("Unable to build query URL from URL components. params=\(params)")
      return nil
    }
    
    var urlRequest = URLRequest(url: urlWithQueryItems)
    urlRequest.httpMethod = "GET"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    return urlRequest
  }
  
  
  func buildImageUrlString(photo: Photo) -> String {
    return "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_m.jpg"
  }

  
  func fetchPhotos(page: Int = 1, perPage: Int = 20, completionHandler: @escaping FetchPhotosCompletionHandler) {
    
    print("Fetching next page of photos. page=\(page) perPage=\(perPage)")
    
    let params = ["method" : "flickr.photos.getRecent",
                  "page" : String(page),
                  "per_page" : String(perPage),
                  "format": "json",
                  "nojsoncallback": "1",
                  "safe_search": String(true)]
    
    guard let getPhotosUrlRequest = self.buildHTTPGetRequest(baseUrl: flickrApiUrl, params: params) else {
      print("HTTP Request Error. Unable to form GET request. params=\(params)")
      completionHandler(nil, URLError(.badURL))
      return
    }

    let fetchPhotosDataTask = session.dataTask(with: getPhotosUrlRequest) { data, response, error in
      
      if let error = error {
        print("Client Error. error=\(error)")
        completionHandler(nil, error)
        return
      }
      
      guard let response = response as? HTTPURLResponse else {
        print("Server Error. Missing HTTP response")
        completionHandler(nil, URLError(.badServerResponse))
        return
      }
      
      if response.statusCode >= 300 {
        print("Server Error. Status Code=\(response.statusCode)")
        completionHandler(nil, URLError(.resourceUnavailable))
        return
      }
      
      guard let mime = response.mimeType, mime == "application/json" else {
        print("Data Error. Unexpected MIME type.")
        completionHandler(nil, URLError(.badServerResponse))
        return
      }
      
      guard let data = data else {
        print("Data Error. Missing data payload.")
        completionHandler(nil, URLError(.badServerResponse))
        return
      }
      
      do {
        let photoResults = try JSONDecoder().decode(PhotoResults.self, from: data)
        print("Fetched next page of photos. photoResults=\(photoResults)")
        completionHandler(photoResults, nil)
      } catch {
        print("Data error. Unable to create photos result object from data. error=\(error.localizedDescription) data=\(data)")
        completionHandler(nil, URLError(.badServerResponse))
      }
    }
    
    fetchPhotosDataTask.resume()
  }
  
  
  func fetchPhoto(photo: Photo, completionHandler: @escaping FetchPhotoCompletionHandler) {
    
    let imageUrlString = buildImageUrlString(photo: photo)
    
    if let cachedImage = photoImageCache[imageUrlString] {
      print("Returning cached photo image. photo=\(photo) cachedImage=\(cachedImage)")
      completionHandler(cachedImage, nil)
      return
    }
    
    guard photoFetchTasksInProgress[imageUrlString] == nil else {
      print("Photo image fetch already in progress. photo=\(photo) imageUrlString=\(imageUrlString)")
      completionHandler(nil, nil)
      return
    }
  
    guard let imageUrl = URL(string: imageUrlString) else {
      print("HTTP Request Error. Unable to form Image URL. photo=\(photo)")
      completionHandler(nil, URLError(.badURL))
      return
    }
  
    print("Fetching photo image. photo=\(photo) imageUrlString=\(imageUrlString)")
    
    let fetchPhotoImageTask = session.dataTask(with: imageUrl) { data, response, error in
      
      self.photoFetchTasksInProgress[imageUrlString] = nil
      
      if let error = error {
        print("Client Error. error=\(error)")
        completionHandler(nil, error)
        return
      }
      
      guard let response = response as? HTTPURLResponse else {
        print("Server Error. Missing HTTP response")
        completionHandler(nil, URLError(.badServerResponse))
        return
      }
      
      if response.statusCode >= 300 {
        print("Server Error. Status Code=\(response.statusCode)")
        completionHandler(nil, URLError(.resourceUnavailable))
        return
      }
      
      guard let mime = response.mimeType, mime == "image/jpeg" else {
        print("Data Error. Unexpected MIME type.")
        completionHandler(nil, URLError(.badServerResponse))
        return
      }
      
      guard let data = data else {
        print("Data Error. Missing data payload.")
        completionHandler(nil, URLError(.badServerResponse))
        return
      }
      
      guard let photoImage = UIImage(data: data) else {
        print("Data Error. Unable to create image from data. data.count=\(data.count)")
        completionHandler(nil, URLError(.badServerResponse))
        return
      }
      
      self.photoImageCache[imageUrlString] = photoImage
    
      print("Fetched the photo image. photo=\(photo) photoImage=\(photoImage) ")
      completionHandler(photoImage, nil)
    }
    
    self.photoFetchTasksInProgress[imageUrlString] = fetchPhotoImageTask
    
    fetchPhotoImageTask.resume()
    
    return
  }

}
