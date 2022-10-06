//
//  djPublicTableViewCell.swift
//  cueBoom
//
//  Created by Charles Oxendine on 9/8/20.
//  Copyright © 2020 Shahin Firouzbakht. All rights reserved.
//

import UIKit

class djPublicTableViewCell: UITableViewCell {
    
    @IBOutlet weak var djNameLbl: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCell(dj: DjProfile!, profileImage: UIImage!) {
        
        self.profilePic.layer.cornerRadius = self.profilePic.frame.height/2
        self.djNameLbl.text = dj.name
        self.profilePic.image = profileImage
        
    }
}
