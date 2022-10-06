//
//  DJQueueItemCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/15/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJQueueItemCell: UITableViewCell {
    @IBOutlet weak var songTitleLbl: UILabel!
    @IBOutlet weak var artistNameLbl: UILabel!
    @IBOutlet weak var numRequestsLbl: UILabel!
    @IBOutlet weak var totalValueLbl: UILabel!
    //TODO:
    //@IBOutlet weak var swipeToPlayLbl: UILabel!
    @IBOutlet weak var cellBg: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(stackedQueueItem: StackedQueueItem) {
        
        songTitleLbl.text = stackedQueueItem.song.songTitle
        artistNameLbl.text = stackedQueueItem.song.artistName
        totalValueLbl.text = "$\(Int(round(stackedQueueItem.totalValue)))"
        
        //If a song is paid and therefore ready to play, present instructions for DJ to play
        //If song already played, modify the cell accordingly
        switch stackedQueueItem.stackedQueueStatus {
        case .paid?:
            numRequestsLbl.text = "Swipe to play"
            break
        case .played?:
            numRequestsLbl.text = "Played"
            cellBg.backgroundColor = UIColor.gray
            //cellBg.alpha = 1.0
            break
        default:
            numRequestsLbl.text = "\(stackedQueueItem.numRequests) Requests"
            cellBg.backgroundColor = UIColor.white
            //cellBg.alpha = 0.2
            break
        }
    }

}
