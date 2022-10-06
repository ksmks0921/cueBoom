//
//  UserNavBar.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class UserNavBar: UINavigationBar {

    override func awakeFromNib() {
        super.awakeFromNib()
        
     
        let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "MavenProRegular", size: 22)]

        titleTextAttributes = attrs
        
       
    }
    

}
