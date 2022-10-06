//
//  InteractiveImgView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class InteractiveImgView: UIImageView {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        isUserInteractionEnabled = true
    }

}
