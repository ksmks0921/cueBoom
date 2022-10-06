//
//  DJGigCell.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJGigCell: UITableViewCell {

    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var bg: UIView!
    
    private var _session: Session!
    var session: Session {
        return _session
    }
    
    var delegate: GigCellDelegate!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let colorView = UIView()
        colorView.backgroundColor = TEALISH
        self.selectedBackgroundView = colorView
        
        
    }
    

    
    func configureCell(session: Session) {
        self._session = session
        venueNameLbl.text = session.venueName
        var time = session.startTime.dateValue()
        timeLbl.text = time.getCustomTimeString()
    }
    
    @IBAction func editBtnTapped(_ sender: Any) {
        delegate.editBtnTapped(session: session)
    }

}
