//
//  NavControllerExtensions.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/15/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    func customPopToVc(ofType targetVc: UIViewController) {
        for vc in self.viewControllers {
            if vc.isKind(of: type(of: targetVc)) {
                self.popToViewController(vc, animated: true)
            }
        }
    }
}
