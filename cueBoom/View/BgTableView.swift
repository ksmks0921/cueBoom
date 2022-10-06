//
//  BgTableView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/13/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class BgTableView: UITableView {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let imgV = UIImageView(image: UIImage(named: "mainAppBg"))
        imgV.frame = self.frame
        self.backgroundView = imgV
    }

}
