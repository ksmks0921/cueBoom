//
//  StorageService.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import FirebaseStorage

let STORAGE_BASE = Storage.storage().reference()
class StorageService {

    private init() {}
    static let shared = StorageService()
    
    func download(url: String, completion: @escaping (UIImage?) -> Void) {
        let ref = Storage.storage().reference(forURL: url)
        
        ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
            if error != nil {
                completion(nil)
            } else {
                if let imgData = data {
                    if let img = UIImage(data: imgData) {
                        return completion(img)
                    }
                }
            }
            completion(nil)
        })
    }
    
    func upload(image: UIImage, uid: String, completion: @escaping (String) -> Void) {
        if let imgData = image.jpegData(compressionQuality: 0.2) {
            
            let imgUid = uid
            let imgMetadata = StorageMetadata()
            imgMetadata.contentType = "image/jpeg"
            var ref = STORAGE_BASE.child(imgUid)
            ref.putData(imgData, metadata: imgMetadata) { (metadata, error) in
                if error != nil {
                    print("Unable to upload image to firebase storage")
                } else {
                    print("Successfully uploaded image to firebase storage")
                
                    // Fetch the download URL
                    ref.downloadURL { url, error in
                        if let error = error {
                            // Handle any errors
                            if(error != nil){
                                print(error)
                                return
                            }
                        } else {
                            // Get the download URL
                            let urlStr:String = (url?.absoluteString) ?? ""
                            completion(urlStr)
                        }
                    }
                }
            }
        } else {
            completion("")
        }
    }
}
