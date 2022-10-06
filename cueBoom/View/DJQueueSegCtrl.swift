//
//  DJQueueSegCtrl.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/15/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJQueueSegCtrl: UISegmentedControl {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.removeBorders()
        
        backgroundColor = .white
        
        let unselectedColor = UIColor.black.withAlphaComponent(0.43)
        let selectedColor = UIColor.black.withAlphaComponent(0.8)
        
        
        let selectedAttrs = [NSAttributedString.Key.font: UIFont(name: "MavenProMedium", size: 11)!, NSAttributedString.Key.foregroundColor: selectedColor]
        let unselectedAttrs = [NSAttributedString.Key.font: UIFont(name: "MavenProMedium", size: 11)!, NSAttributedString.Key.foregroundColor: unselectedColor]
        
        setTitleTextAttributes(selectedAttrs, for: .selected)
        setTitleTextAttributes(unselectedAttrs, for: .normal)
        
    }
    
    func removeBorders() {
        setBackgroundImage(imageWithColor(color: UIColor.clear), for: .normal, barMetrics: .default)
        setBackgroundImage(imageWithColor(color: UIColor.clear), for: .selected, barMetrics: .default)
        setDividerImage(imageWithColor(color: UIColor.clear), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }
    
    func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width:  1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor);
        context!.fill(rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }

}
