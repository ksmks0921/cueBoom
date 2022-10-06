//
//  UserQueueItemCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/11/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class UserQueueItemCell: UITableViewCell {
    
    @IBOutlet weak var numRequestsLbl: UILabel!
    @IBOutlet weak var songTitleLbl: UILabel!
    @IBOutlet weak var artistNameLbl: UILabel!
    @IBOutlet weak var albumArtImgV: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(queueItem: QueueItem) {
        //Song title
        songTitleLbl.text = queueItem.songTitle
        //Artist name
        artistNameLbl.text = queueItem.artistName
        //Album art url
        ImageService.shared.downloadAlbumArt(url: queueItem.albumArtUrl) { (image) in
            self.albumArtImgV.image = image
        }
        //Number of requests
        //FirestoreService.shared.REF_SESSIONS.collection("queues").document(queueItem.id).
    }

   

}
