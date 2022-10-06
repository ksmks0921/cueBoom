//
//  RequestCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class RequestCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var imgV: UIImageView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
      
    }
    
    func configureRequestCell(request: Request) {
        
        //Get album art from url
        ImageService.shared.downloadAlbumArt(url: request.albumArtUrl) { image in
            DispatchQueue.main.async {
                self.imgV.image = image
            }
        }
        
        titleLbl.text = request.songName
        subtitleLbl.text = "\(request.artistName) | \(request.albumName)"
    }
    
    func configureDjCell(session: Session) {
        StorageService.shared.download(url: session.djImgUrl) {img in
            if let img = img {
                self.imgV.image = img
            }
        }
        titleLbl.text = session.djName
        subtitleLbl.text = "\(session.venueName) | \(session.venueAddress)"
    }
}
