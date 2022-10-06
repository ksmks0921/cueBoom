//
//  NavigationBarExtensions.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

extension UINavigationController: UINavigationBarDelegate {
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPush item: UINavigationItem) -> Bool {
        print("NAV: Should push")

       
       // Remove "Back" from back bar button
        let backItem = UIBarButtonItem(title: " ", style: .plain, target: self, action: nil)
        backItem.tintColor = UIColor.white
        
        navigationBar.topItem?.backBarButtonItem = backItem
        
       // Set back indicator arrow
        let backImg = UIImage(named: "back")
        navigationBar.backIndicatorImage = backImg
        navigationBar.backIndicatorTransitionMaskImage = backImg
        

        return true
    }
    
//    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
//       
//
//        return true
//    }
    
   
    
    public func customMakeTranslucent() {
        self.navigationBar.backgroundColor = .clear
        self.navigationBar.isTranslucent = true
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
    }
    
    public func customMakeOpaque() {
        self.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationBar.shadowImage = nil
        self.navigationBar.isTranslucent = false
        self.navigationBar.backgroundColor = UIColor.black
    }
    


    
}
