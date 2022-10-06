//
//  UserMainSessionCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/11/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class UserMainSessionCell: UITableViewCell {
    
    @IBOutlet weak var djNameLbl: UILabel!
    @IBOutlet weak var venueInfoLbl: UILabel!
    @IBOutlet weak var djImageV: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(session: Session) {
        djNameLbl.text = session.djName
        venueInfoLbl.text = session.venueName
        //djImageV.image = get image for url
    }

}
