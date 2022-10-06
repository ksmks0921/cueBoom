//
//  StringExtensions.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import UIKit
extension String {
    func to(_ color: UIColor) -> NSAttributedString {
       
        let attrs = [NSAttributedString.Key.foregroundColor: color]
        let attrsString = NSAttributedString(string: self, attributes: attrs)
        return attrsString
    }
}
