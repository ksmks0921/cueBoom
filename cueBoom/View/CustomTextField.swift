//
//  CustomTextField.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let string = placeholder {
            let attrs = [NSAttributedString.Key.foregroundColor:UIColor.lightGray]
            let attrsString = NSAttributedString(string: string, attributes: attrs)
            attributedPlaceholder = attrsString
        }
        
    }
}
