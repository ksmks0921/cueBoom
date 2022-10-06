//
//  String+Extention.swift
//  cueBoom
//
//  Created by Angel Dev on 2/17/22.
//  Copyright © 2022 Shahin Firouzbakht. All rights reserved.
//

extension String {
    public func substring(_ from: Int) -> String {
        return self.substring(from: self.index(self.startIndex, offsetBy: from))
    }
}
