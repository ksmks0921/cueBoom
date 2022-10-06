//
//  SegueFromLeft.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/7/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class SegueFromLeft: UIStoryboardSegue {
    override func perform()
    {
        let src = self.source as UIViewController
        let dst = self.destination as UIViewController
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width * -2, y: 0)
        
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        },
                       completion: { finished in
                        if let navigationController = src.navigationController {
                            navigationController.pushViewController(dst, animated: false)
                        }
                        //src.present(dst, animated: false, completion: nil)
        }
        )
    }
    
}
