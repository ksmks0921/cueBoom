//
//  SessionInfoView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class SessionInfoView: UIView {

    //Outlets
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var djNameLbl: UILabel!
    @IBOutlet weak var venueInfoLbl: UILabel!
    @IBOutlet weak var numCartItemsLbl: UILabel!
    //@IBOutlet weak var cartBtn: UIButton!
    @IBOutlet weak var cartView: UIView!
    @IBOutlet weak var arrowImgV: UIImageView!
    @IBOutlet weak var topBorder: UIView!
    @IBOutlet weak var bottomBorder: UIView! //Set to hidden in storyboard
    //TODO: need down arrow image
    
    //View model closures
    var handleCartTap: (()->())?
    var handleViewTap: (()->())?
    
    //Arrows
    let upArrow = UIImage(named: "upArrow")
    let downArrow = UIImage(named: "downArrow")
  
    //Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //Get nib
        UINib(nibName: "SessionInfoView", bundle: nil).instantiate(withOwner: self, options: nil)
        //Default session info view UI
        cartView.isHidden = true
        venueInfoLbl.isHidden = true
        
        //Configure arrow
        arrowImgV.image = upArrow
        
        //Add to view
        addSubview(view)
        view.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //IBActions
    
//    @IBAction func cartBtnTapped(_ sender: Any) {
//        handleCartTap?()
//    }
    
    @IBAction func cartViewTapped(_ sender: Any) {
        handleCartTap?()
    }
    
    
    @IBAction func viewTapped(_ sender: Any) {
        handleViewTap?()
    }
    
    //Configure UI when the view is selected, i.e. when user taps the view in order to select a venue
    func selected() {
        topBorder.isHidden = true
        bottomBorder.isHidden = false
        cartView.isHidden = true
        arrowImgV.image = UIImage(named: "downArrow")
    }
    
    func updateUI(forSession session: Session, shouldDisplayCartInfo: Bool) {
        if shouldDisplayCartInfo {
            cartView.isHidden = false
            arrowImgV.image = upArrow
        } else {
            cartView.isHidden = true
            topBorder.isHidden = true
            arrowImgV.image = downArrow
        }
    
        venueInfoLbl.isHidden = false
        
        if session.onlineEvent == true {
            venueInfoLbl.text = "Online Event"
        } else {
            venueInfoLbl.text = session.venueName
        }
        
        djNameLbl.text = session.djName
    }
    
}
