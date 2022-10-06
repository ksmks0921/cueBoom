//
//  LoginNavBar.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class LoginNavBar: UINavigationBar {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()
        self.isTranslucent = true
        self.backgroundColor = .clear
        self.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "MavenProRegular", size: 21)!
        ]
        
    }

}
