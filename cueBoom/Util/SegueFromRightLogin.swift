//
//  SegueFromRightLogin.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class SegueFromRightLogin: UIStoryboardSegue {
    override func perform()
    {
        let src = self.source as UIViewController
        let dst = self.destination as UIViewController
        
        print("SEGUE: Source is \(src)")
        print("SEGUE: Dest is \(dst)")
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width, y: 0)
        
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        },
                       completion: { finished in
                        
                        src.present(dst, animated: false, completion: nil)
        }
        )
    }
}
