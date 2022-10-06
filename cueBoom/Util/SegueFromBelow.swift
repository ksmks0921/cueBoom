//
//  SegueFromBelow.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/13/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class SegueFromBelow: UIStoryboardSegue {
    override func perform()
    {
        let src = self.source as UIViewController
        let dst = self.destination as UIViewController
        
        print("SEGUE: Source is \(src)")
        print("SEGUE: Dest is \(dst)")
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: 0, y: src.view.frame.size.height)
        
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
