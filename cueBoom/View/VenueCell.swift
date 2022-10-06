//
//  VenueCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/30/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class VenueCell: UITableViewCell {

    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var addressLbl: UILabel!
    
    private var _session: Session!
    var session: Session {
        return _session
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let colorView = UIView()
        colorView.backgroundColor = TEALISH
        self.selectedBackgroundView = colorView
    }
    
    func configureCell(session: Session) {
        self._session = session
        venueNameLbl.text = session.venueName
        addressLbl.text = session.venueAddress
    }
   

}
