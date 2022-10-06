//
//  SearchResultCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/19/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var artistAlbumLbl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func configureCell(song: Song) {
        nameLbl.text = song.songTitle
        artistAlbumLbl.text = "\(song.artistName) | \(song.albumName)"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
