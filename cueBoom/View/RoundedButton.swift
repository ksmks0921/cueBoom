//
//  RoundedButton.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/4/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {
    
    let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont(name: "Maven Pro", size: 20) as Any]

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = self.frame.height / 2
        self.backgroundColor = TEALISH
        
        
        if let btnText = titleLabel?.text {
            let attrsString = NSAttributedString(string: btnText, attributes: attrs)
            self.titleLabel!.attributedText = attrsString
            self.tintColor = UIColor.white
        }
        
    }
    
    func changeTitleText(toString string: String) {
        let attrsString = NSAttributedString(string: string, attributes: attrs)
        setAttributedTitle(attrsString, for: .normal)
    }
    
}
