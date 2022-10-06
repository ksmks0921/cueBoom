//
//  ConfirmRequestVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit


class ConfirmRequestVC: UIViewController {
    
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var djName: UILabel!
    @IBOutlet weak var venueName: UILabel!
    
    private var _confirmationTuple: (Song, Session)!
    
    var confirmationTuple: (Song, Session) {
        get {
            return _confirmationTuple
        } set {
            _confirmationTuple = newValue
        }
    }
   
    

    override func viewDidLoad() {
        super.viewDidLoad()
  
        trackName.text = _confirmationTuple.0.songTitle
        djName.text = _confirmationTuple.1.djName
        venueName.text = _confirmationTuple.1.venueName
    
    }
}


