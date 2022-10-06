//
//  ImageService.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import Firebase

class ImageService {
    
    static let shared = ImageService()
    
    private var _cache: NSCache<NSString, UIImage> = NSCache()
    
    func pullFromCache(url: String) -> UIImage? {
        if let pic = _cache.object(forKey: url as NSString) {
            return pic
        } else {
            return nil
        }
    }
    
    //Add image to cache
    func cacheImg(img: UIImage, url: String) {
        _cache.setObject(img, forKey: url as NSString)
    }
    
    //Remove image from cache, where url is key of image in cache
    func removeFromCache(url: String) {
        _cache.removeObject(forKey: url as NSString)
    }
    
    func downloadAlbumArt(url: String, completion: @escaping(UIImage) -> Void) {
        //TODO: catch error instead of multiple instances of completion(UIImage())
        
        //Replace {w}x{h} in url with real dimensions
        let imgUrl = URL(string: url.replacingOccurrences(of: "{w}x{h}", with: "300x300"))!
        
        let session = URLSession(configuration: .default)
        
        let downloadPicTask = session.dataTask(with: imgUrl) { (data, response, error) in
            if let e = error {
                completion(UIImage())
                //print("Error downloading img: \(e)")
            } else {
                if let res = response as? HTTPURLResponse {
                    //print("Downloaded img with response code \(res.statusCode)")
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            completion(image)
                        }
                    } else {
                        completion(UIImage())
                        //print("Couldn't get image")
                    }
                } else {
                    completion(UIImage())
                    //print("Couldn't get response code")
                }
            }
        }
        downloadPicTask.resume()
    }
    
}
