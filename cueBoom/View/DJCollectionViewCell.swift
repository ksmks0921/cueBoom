//
//  DJCollectionViewCell.swift
//  cueBoom
//
//  Created by Charles Oxendine on 7/30/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseStorage
import Kingfisher

class DJCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var djNameLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    private var djUID: String?
    
    func setCell(djName: String!, djUID: String!, profile: String?) {
        self.djUID = djUID
        self.djNameLabel.text = djName
//        djNameLabel.numberOfLines = 0
        
        if let img = profile, img != "" {
            profileImage.kf.indicatorType = .activity
            profileImage.kf.setImage(with: URL(string: img), placeholder: CONSTANT.IMG_PLACEHOLDER)
        } else {
            profileImage.image = CONSTANT.IMG_PLACEHOLDER
        }
//        getImage()
    }
    
    private func getImage() {
        guard djUID != nil else { return }
        
        let storage = Storage.storage()
        storage.reference(withPath: djUID!).getData(maxSize: 1 * 1024 * 1024) {[self] data, error in
            if let error = error {
                print(error.localizedDescription)
                profileImage.image = CONSTANT.IMG_PLACEHOLDER
            } else {
                self.profileImage.image = UIImage(data: data!)
            }
        }
    }

}
