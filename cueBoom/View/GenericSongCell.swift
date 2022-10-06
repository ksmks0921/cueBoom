//
//  GenericSongCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/13/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Foundation

//This cell is used to display
//1. Queue items, AND
//2. Song search results
//In the case of Song rearch results, label displaying number of requests is hidden, as that applies only to queue items

class GenericSongCell: UITableViewCell {
    
    @IBOutlet weak var songTitleLbl: UILabel!
    @IBOutlet weak var artistNameLbl: UILabel!
    @IBOutlet weak var albumArtImgV: UIImageView!
    @IBOutlet weak var numRequestsLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(queueItem: QueueItem) {
        
            numRequestsLbl.isHidden = false
            songTitleLbl.text = queueItem.songTitle
            artistNameLbl.text = queueItem.artistName
            ImageService.shared.downloadAlbumArt(url: queueItem.albumArtUrl) { (image) in
                DispatchQueue.main.async {
                    self.albumArtImgV.image = image
                }
            }
            if queueItem.numRequests > 1 {
                numRequestsLbl.text = "\(queueItem.numRequests) Requests"
            } else {
                numRequestsLbl.isHidden = true
            }
    }
    
    func configureCell(song: Song) {
        numRequestsLbl.isHidden = true
        songTitleLbl.text = song.songTitle
        artistNameLbl.text = song.artistName
        ImageService.shared.downloadAlbumArt(url: song.albumArtUrl) { (image) in
            DispatchQueue.main.async {
                self.albumArtImgV.image = image
            }
        }
    }
    
    func configureCell(imgSongTuple: (UIImage, Song)) {
        numRequestsLbl.isHidden = true
        songTitleLbl.text = imgSongTuple.1.songTitle
        artistNameLbl.text = imgSongTuple.1.artistName
        DispatchQueue.main.async {
            self.albumArtImgV.image = imgSongTuple.0
        }
    }

  

}
