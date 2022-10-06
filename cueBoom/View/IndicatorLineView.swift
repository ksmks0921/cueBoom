//
//  IndicatorLineView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/23/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class IndicatorLineView: UIView {

    override func awakeFromNib() {
        self.backgroundColor = TEALISH
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 1
    }
    
}
