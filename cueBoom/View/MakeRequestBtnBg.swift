//
//  MakeRequestBtnBg.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/21/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class MakeRequestBtnBg: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        //Corner radius
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = false
        
        
       
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Shadow
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        
    }

}
