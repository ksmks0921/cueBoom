//
//  CartItemCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/13/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class CartItemCell: UITableViewCell {
    @IBOutlet weak var songTitleLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(queueItem: QueueItem) {
        songTitleLbl.text = queueItem.songTitle
        priceLbl.text = String(format: "$%.02f", queueItem.price)
    }

    

}
