//
//  DJProfileTextField.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/3/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJProfileTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        if let string = placeholder {
            let attrs = [NSAttributedString.Key.foregroundColor:UIColor.white]
            let attrsString = NSAttributedString(string: string, attributes: attrs)
            attributedPlaceholder = attrsString
        }
    }

}
