//
//  DjCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/23/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DjCell: UITableViewCell {
    
    @IBOutlet weak var djLbl: UILabel!
    @IBOutlet weak var venueLbl: UILabel!
    @IBOutlet weak var djImgV: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(session: Session) {
        
        djLbl.text = session.djName
        var venue = session.startTime.dateValue()
        venueLbl.text = venue.getCustomTimeString()
        if session.djImgUrl == nil || session.djImgUrl == "" {
            FirestoreService.shared.getDocumentData(ref: FirestoreService.shared.REF_DJS_PUBLIC.document(session.djUid)) { (data) in
                guard var imageURL = data?["djImgUrl"] as? String else {
                    print("ERROR NO URL")
                    return
                }
            
                print("dj img url is \(imageURL)")
                StorageService.shared.download(url: imageURL) { img in
                    print(img)
                    self.djImgV.image = img
                }
            }
        } else {
            print("dj img url is \(session.djImgUrl)")
            StorageService.shared.download(url: session.djImgUrl) { img in
                print(img)
                self.djImgV.image = img
            }
        }
    }
}
